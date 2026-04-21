#!/usr/bin/env bash
# autopilot-state.sh — Manage .claude/autopilot.state.json for the autopilot pipeline.
#
# Usage:
#   autopilot-state.sh init <plan-file> [issue-number]
#   autopilot-state.sh read
#   autopilot-state.sh get <json-path>             # e.g. get .phase
#   autopilot-state.sh set <key> <value>           # e.g. set phase audit
#   autopilot-state.sh advance                     # move to next phase
#   autopilot-state.sh metric <name> <value>       # update metrics.{name}
#   autopilot-state.sh skip-declare <phase> <reason>  # append skip_log entry
#   autopilot-state.sh cleanup
#
# Schema (v1):
#   {
#     "version": 1,
#     "phase": "sprint|audit|simplify|ship|post-pr-review|retrospective|complete",
#     "iteration": 0,
#     "last_successful_stage": null,
#     "plan_source": "/abs/path/to/plan.md",
#     "issue_number": 123 | null,
#     "auto_mode_confidence": "detected|assumed|unknown",
#     "created_at": "<ISO8601>",
#     "updated_at": "<ISO8601>",
#     "metrics": {
#       "critical": 0,
#       "important": 0,
#       "ci_status": "unknown|pending|success|failure"
#     }
#   }
#
# Phase order for `advance`:
#   sprint → audit → simplify → ship → post-pr-review → retrospective → complete

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "autopilot-state: jq required" >&2; exit 2; }

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_FILE="${PROJECT_DIR}/.claude/autopilot.state.json"

iso_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

die() { echo "autopilot-state: $*" >&2; exit 1; }

# Create a temporary file next to $STATE_FILE rather than the default $TMPDIR.
# Claude Code's sandbox allow-list permits writes within the repository tree
# (including the project's .claude/ directory) but denies the default macOS
# $TMPDIR (/var/folders/...). Co-locating scratch files with the real state
# keeps every write on an already-permitted path. Errors are surfaced via
# stderr + non-zero return so callers' command substitution sees the failure
# (bash's `local` swallows exit codes, hence the explicit `|| return 1`).
state_mktemp() {
  local dir; dir=$(dirname "$STATE_FILE")
  mkdir -p "$dir" || { echo "autopilot-state: mkdir failed: $dir" >&2; return 1; }
  mktemp "$dir/.autopilot.tmp.XXXXXX" || { echo "autopilot-state: mktemp failed in $dir" >&2; return 1; }
}

ensure_state_dir() {
  mkdir -p "$(dirname "$STATE_FILE")"
}

next_phase() {
  case "$1" in
    sprint)          echo "audit" ;;
    audit)           echo "simplify" ;;
    simplify)        echo "ship" ;;
    ship)            echo "post-pr-review" ;;
    post-pr-review)  echo "retrospective" ;;
    retrospective)   echo "complete" ;;
    complete)        echo "complete" ;;
    *) die "unknown phase: $1" ;;
  esac
}

cmd_init() {
  local plan="$1" issue="${2:-null}"
  [ -n "$plan" ] || die "plan file required"
  ensure_state_dir
  [ "$issue" = "null" ] || [[ "$issue" =~ ^[0-9]+$ ]] || die "issue must be a number or 'null'"
  local issue_json
  if [ "$issue" = "null" ]; then
    issue_json=null
  else
    issue_json="$issue"
  fi
  local now; now=$(iso_now)
  jq -n \
    --arg plan "$plan" \
    --argjson issue "$issue_json" \
    --arg now "$now" \
    '{
      version: 1,
      phase: "sprint",
      iteration: 0,
      last_successful_stage: null,
      plan_source: $plan,
      issue_number: $issue,
      auto_mode_confidence: "unknown",
      created_at: $now,
      updated_at: $now,
      metrics: {
        critical: 0,
        important: 0,
        ci_status: "unknown"
      }
    }' > "$STATE_FILE"
  echo "initialized: $STATE_FILE"
}

cmd_read() {
  [ -f "$STATE_FILE" ] || die "no state file"
  jq '.' "$STATE_FILE"
}

cmd_get() {
  local path="$1"
  [ -n "$path" ] || die "json path required (e.g. .phase)"
  [ -f "$STATE_FILE" ] || die "no state file"
  jq -r "$path // empty" "$STATE_FILE"
}

cmd_set() {
  local key="$1" value="$2"
  [ -n "$key" ] && [ -n "${value+x}" ] || die "usage: set <key> <value>"
  [ -f "$STATE_FILE" ] || die "no state file; run init first"
  # Reject keys containing shell/jq metacharacters (defense against injection via arg)
  [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || die "invalid key: $key"
  # Guard against bypassing the stop-hook's phase advance. Direct `set phase`
  # skips the next-skill invocation step (the stop hook reads the current
  # phase to pick NEXT_SKILL; manually jumping the phase forward silently
  # omits the skill for the skipped phase — e.g. pr-review-team vanished
  # when `set phase post-pr-review` was run after ship). `advance` is the
  # intended API; direct `set phase` is reserved for resume-after-crash.
  if [ "$key" = "phase" ] && [ -z "${AUTOPILOT_STATE_ALLOW_SET_PHASE:-}" ]; then
    die "use 'advance' to move phases. Direct 'set phase' skips stop-hook skill dispatch. Set AUTOPILOT_STATE_ALLOW_SET_PHASE=1 only for manual recovery."
  fi
  local now; now=$(iso_now)
  local tmp; tmp=$(state_mktemp) || die "state_mktemp failed"
  trap 'rm -f "$tmp"' RETURN
  # Prefer --argjson (typed JSON). Fall back to --arg (string) if value is not valid JSON.
  # Single-pass write that also stamps updated_at; no secondary jq call.
  if jq --arg key "$key" --argjson v "$value" --arg now "$now" \
        '.[$key] = $v | .updated_at = $now' \
        "$STATE_FILE" >"$tmp" 2>/dev/null; then
    :
  else
    jq --arg key "$key" --arg v "$value" --arg now "$now" \
       '.[$key] = $v | .updated_at = $now' \
       "$STATE_FILE" >"$tmp"
  fi
  mv "$tmp" "$STATE_FILE"
  echo "set $key = $value"
}

cmd_advance() {
  [ -f "$STATE_FILE" ] || die "no state file"
  local cur; cur=$(jq -r '.phase' "$STATE_FILE")
  local nxt; nxt=$(next_phase "$cur")
  local now; now=$(iso_now)
  local tmp; tmp=$(state_mktemp) || die "state_mktemp failed"
  trap 'rm -f "$tmp"' RETURN
  jq \
    --arg cur "$cur" \
    --arg nxt "$nxt" \
    --arg now "$now" \
    '.last_successful_stage = $cur
     | .phase = $nxt
     | .iteration = 0
     | .updated_at = $now' \
    "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  echo "advanced: $cur -> $nxt"
}

cmd_metric() {
  local name="$1" value="$2"
  [ -n "$name" ] && [ -n "${value+x}" ] || die "usage: metric <name> <value>"
  [ -f "$STATE_FILE" ] || die "no state file"
  [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || die "invalid metric name: $name"
  local now; now=$(iso_now)
  local tmp; tmp=$(state_mktemp) || die "state_mktemp failed"
  trap 'rm -f "$tmp"' RETURN
  if jq --arg name "$name" --argjson v "$value" --arg now "$now" \
        '.metrics[$name] = $v | .updated_at = $now' \
        "$STATE_FILE" >"$tmp" 2>/dev/null; then
    :
  else
    jq --arg name "$name" --arg v "$value" --arg now "$now" \
       '.metrics[$name] = $v | .updated_at = $now' \
       "$STATE_FILE" >"$tmp"
  fi
  mv "$tmp" "$STATE_FILE"
  echo "metric.$name = $value"
}

cmd_cleanup() {
  rm -f "$STATE_FILE"
  echo "cleaned up: $STATE_FILE"
}

# Append a skip declaration to .skip_log[]. Purely additive; does NOT advance
# the phase or interact with the Stop hook. Callers are expected to still run
# `advance` afterward. The retrospective step audits skip_log against the
# session transcript.
cmd_skip_declare() {
  local phase="$1" reason="${2:-}"
  [ -n "$phase" ] && [ -n "$reason" ] || die "usage: skip-declare <phase> <reason>"
  [[ "$phase" =~ ^[a-z][a-z0-9-]*$ ]] || die "invalid phase: $phase"
  # Reject whitespace-only or too-short reasons: zero-effort declarations like
  # "n/a" or " " defeat the commitment device purpose.
  local trimmed="${reason#"${reason%%[![:space:]]*}"}"
  trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
  (( ${#trimmed} >= 10 )) || die "reason must be at least 10 non-whitespace chars (got: '$reason')"
  [ -f "$STATE_FILE" ] || die "no state file; run init first"
  local now; now=$(iso_now)
  local tmp; tmp=$(state_mktemp) || die "state_mktemp failed"
  trap 'rm -f "$tmp"' RETURN
  # Cap skip_log at 500 most-recent entries to prevent unbounded growth across
  # many autopilot runs. Retrospective still sees the latest run's entries.
  jq --arg phase "$phase" --arg reason "$reason" --arg now "$now" \
     '.skip_log = ((.skip_log // []) + [{phase: $phase, reason: $reason, declared_at: $now}])
      | .skip_log = (if (.skip_log | length) > 500 then .skip_log[-500:] else .skip_log end)
      | .updated_at = $now' \
     "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  echo "skip-declared: $phase"
}

sub="${1:-}"
shift || true
case "$sub" in
  init)         cmd_init "$@" ;;
  read)         cmd_read ;;
  get)          cmd_get "$@" ;;
  set)          cmd_set "$@" ;;
  advance)      cmd_advance ;;
  metric)       cmd_metric "$@" ;;
  cleanup)      cmd_cleanup ;;
  skip-declare) cmd_skip_declare "$@" ;;
  "" )          die "subcommand required: init|read|get|set|advance|metric|cleanup|skip-declare" ;;
  *)            die "unknown subcommand: $sub" ;;
esac
