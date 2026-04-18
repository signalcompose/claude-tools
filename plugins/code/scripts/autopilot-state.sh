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
# Rationale: Claude Code's sandbox denies writes to /var/folders (the default
# macOS TMPDIR) while allowing writes inside the project .claude/ directory.
# Using the state file's dir keeps every write on the already-permitted path.
state_mktemp() {
  local dir; dir=$(dirname "$STATE_FILE")
  mkdir -p "$dir"
  mktemp "$dir/.autopilot.tmp.XXXXXX"
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
  local tmp; tmp=$(state_mktemp)
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
  local tmp; tmp=$(state_mktemp)
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
  local tmp; tmp=$(state_mktemp)
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

sub="${1:-}"
shift || true
case "$sub" in
  init)    cmd_init "$@" ;;
  read)    cmd_read ;;
  get)     cmd_get "$@" ;;
  set)     cmd_set "$@" ;;
  advance) cmd_advance ;;
  metric)  cmd_metric "$@" ;;
  cleanup) cmd_cleanup ;;
  "" )     die "subcommand required: init|read|get|set|advance|metric|cleanup" ;;
  *)       die "unknown subcommand: $sub" ;;
esac
