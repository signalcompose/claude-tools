#!/usr/bin/env bash
# autopilot-state.sh — Manage .claude/autopilot.state.json for the autopilot pipeline.
#
# Usage:
#   autopilot-state.sh init <plan-file> [issue-number]
#   autopilot-state.sh read
#   autopilot-state.sh get <json-path>             # e.g. get .phase
#   autopilot-state.sh set <key> <value>           # e.g. set phase audit
#   autopilot-state.sh advance                     # move to next phase (with verification)
#   autopilot-state.sh metric <name> <value>       # update metrics.{name}
#   autopilot-state.sh skip-declare <phase> <reason>  # append skip_log entry
#   autopilot-state.sh record-invocation <phase> <skill> [tool-use-id]
#                                                  # append Skill-tool invocation evidence
#   autopilot-state.sh record-review-iteration    # increment review_iterations (pr-review-team)
#   autopilot-state.sh cleanup
#
# Schema (v2 — additive to v1, backward compatible via `// [] / // 0` reads):
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
#     },
#     "invocations": [
#       { "phase": "sprint", "skill": "code:sprint-impl", "invoked_at": "<ISO>", "tool_use_id": "..." }
#     ],
#     "review_iterations": 0,
#     "skip_log": [
#       { "phase": "simplify", "reason": "...", "declared_at": "<ISO>" }
#     ]
#   }
#
# Phase → expected Skill mapping (used by `advance` verification):
#   sprint         → code:sprint-impl
#   audit          → code:audit-compliance
#   simplify       → simplify
#   ship           → code:shipping-pr
#   post-pr-review → code:pr-review-team
#   retrospective  → code:retrospective
#
# Concurrency note: read-modify-write on $STATE_FILE is not locked. The
# PostToolUse hook (autopilot-record-invocation.sh) and main-thread callers
# (advance/metric/skip-declare) can race on the final `mv "$tmp"`, in which
# case the later writer silently wins. The window is microseconds in
# practice and the failure mode is observable (advance then refuses with a
# "no evidence" message, which the caller can resolve by re-invoking the
# skill or retrying). Locking is deferred to the next PDCA iteration if the
# race is observed in real usage. See #255/#257 discussion.
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

# Map a phase name to the Skill tool that is expected to carry out that phase.
# Used by both record-invocation (to bucket invocations by phase) and advance
# (to verify the previous phase produced a matching invocations[] entry).
expected_skill_for_phase() {
  case "$1" in
    sprint)          echo "code:sprint-impl" ;;
    audit)           echo "code:audit-compliance" ;;
    simplify)        echo "simplify" ;;
    ship)            echo "code:shipping-pr" ;;
    post-pr-review)  echo "code:pr-review-team" ;;
    retrospective)   echo "code:retrospective" ;;
    *) echo "" ;;
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
      },
      invocations: [],
      review_iterations: 0,
      skip_log: []
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

  # Refuse no-op advance once the pipeline is complete: a second `advance`
  # on `complete` would otherwise silently rewrite updated_at and obscure
  # whether a genuine transition had happened.
  [ "$cur" = "complete" ] && die "pipeline already complete — use cleanup to reset"

  # Skip verification when a recovery override is set. This is the same
  # escape hatch style used by AUTOPILOT_STATE_ALLOW_SET_PHASE.
  if [ -z "${AUTOPILOT_STATE_ALLOW_UNVERIFIED:-}" ]; then
    verify_advance_preconditions "$cur" "$nxt"
  fi

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

# Refuse `advance` unless the phase we are leaving left a Skill-tool invocation
# record, an explicit skip-declare, OR the leader is transitioning from the
# pre-pipeline sprint (no predecessor). Additionally gate the special
# post-pr-review → retrospective transition on convergence metrics: the
# pr-review-team contract requires metrics.{critical,important} == 0 and
# at least 2 review_iterations. This is the mechanical side of #253 / #254.
verify_advance_preconditions() {
  local cur="$1" nxt="$2"

  # Every real phase we leave must produce evidence — sprint included,
  # since the sprint work itself is carried out by code:sprint-impl whose
  # invocation is the evidence. The caller (cmd_advance) already refuses
  # to run when cur == complete, so we do not need to re-handle that here.
  verify_phase_evidence "$cur"

  if [ "$cur" = "post-pr-review" ] && [ "$nxt" = "retrospective" ]; then
    verify_review_convergence
  fi
}

# A phase has evidence iff invocations[] contains an entry matching BOTH
# phase AND expected skill, OR skip_log has a declaration for the phase.
# Matching skill name (not just phase) closes the CLI-side bypass where
# `record-invocation sprint wrong-skill` would otherwise satisfy the gate.
# The PostToolUse hook already performs this filter; enforcing it at the
# gate too makes direct-CLI and hook paths agree on what counts as evidence.
verify_phase_evidence() {
  local phase="$1"
  local expected; expected=$(expected_skill_for_phase "$phase")
  local inv_count
  if [ -n "$expected" ]; then
    inv_count=$(jq --arg p "$phase" --arg s "$expected" \
      '[(.invocations // [])[] | select(.phase == $p and .skill == $s)] | length' \
      "$STATE_FILE")
  else
    inv_count=$(jq --arg p "$phase" \
      '[(.invocations // [])[] | select(.phase == $p)] | length' \
      "$STATE_FILE")
  fi
  local skip_count
  skip_count=$(jq --arg p "$phase" '[(.skip_log // [])[] | select(.phase == $p)] | length' "$STATE_FILE")
  if [ "$inv_count" = "0" ] && [ "$skip_count" = "0" ]; then
    cat >&2 <<EOF
autopilot-state: advance refused — no evidence for phase '$phase'.

Expected one of:
  (A) Invoke the phase's Skill tool (${expected:-<none>}) — PostToolUse hook
      will append an invocations[] entry whose .skill matches.
  (B) Declare a deliberate skip:
        autopilot-state.sh skip-declare $phase "<reason ≥10 chars>"

Recovery override (use sparingly):
  AUTOPILOT_STATE_ALLOW_UNVERIFIED=1 autopilot-state.sh advance
EOF
    exit 1
  fi
}

# pr-review-team contract: at least 2 review iterations, both critical and
# important counts settled to zero. Based on #254.
verify_review_convergence() {
  local iters crit imp
  iters=$(jq -r '.review_iterations // 0' "$STATE_FILE")
  crit=$(jq -r '.metrics.critical // 0' "$STATE_FILE")
  imp=$(jq -r '.metrics.important // 0' "$STATE_FILE")
  if [ "$iters" -lt 2 ] || [ "$crit" != "0" ] || [ "$imp" != "0" ]; then
    cat >&2 <<EOF
autopilot-state: advance refused — pr-review-team contract unmet.

  review_iterations = $iters  (required: ≥ 2)
  metrics.critical  = $crit  (required: 0)
  metrics.important = $imp  (required: 0)

Re-invoke code:pr-review-team via the Skill tool and let it iterate until
both metrics reach 0. Each iteration must call:
  autopilot-state.sh record-review-iteration
  autopilot-state.sh metric critical <n>
  autopilot-state.sh metric important <n>

Recovery override (use sparingly):
  AUTOPILOT_STATE_ALLOW_UNVERIFIED=1 autopilot-state.sh advance
EOF
    exit 1
  fi
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

# Append a Skill-tool invocation record. Phase is derived from the current
# .phase so the PostToolUse hook only needs to supply skill + optional tool-
# use id. Phase may also be passed explicitly for backfill / replay scenarios.
cmd_record_invocation() {
  local phase="$1" skill="${2:-}" tool_id="${3:-}"
  [ -n "$phase" ] && [ -n "$skill" ] || die "usage: record-invocation <phase> <skill> [tool-use-id]"
  [[ "$phase" =~ ^[a-z][a-z0-9-]*$ ]] || die "invalid phase: $phase"
  # Skills are namespaced like "code:sprint-impl" or plain like "simplify".
  [[ "$skill" =~ ^[a-zA-Z][a-zA-Z0-9:_-]*$ ]] || die "invalid skill: $skill"
  [ -f "$STATE_FILE" ] || die "no state file; run init first"
  local now; now=$(iso_now)
  local tmp; tmp=$(state_mktemp) || die "state_mktemp failed"
  trap 'rm -f "$tmp"' RETURN
  # Cap invocations[] at 500 entries — same convention as skip_log.
  jq --arg phase "$phase" --arg skill "$skill" --arg tool_id "$tool_id" --arg now "$now" \
     '.invocations = ((.invocations // []) + [
        ({phase: $phase, skill: $skill, invoked_at: $now}
         + (if $tool_id == "" then {} else {tool_use_id: $tool_id} end))
      ])
      | .invocations = (if (.invocations | length) > 500 then .invocations[-500:] else .invocations end)
      | .updated_at = $now' \
     "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  echo "recorded: $phase / $skill"
}

# Increment review_iterations. Called by code:pr-review-team at the start of
# each iteration. Kept as a dedicated subcommand (rather than `set`) so the
# phase-write guard stays narrow.
cmd_record_review_iteration() {
  [ -f "$STATE_FILE" ] || die "no state file; run init first"
  local now; now=$(iso_now)
  local tmp; tmp=$(state_mktemp) || die "state_mktemp failed"
  trap 'rm -f "$tmp"' RETURN
  jq --arg now "$now" \
     '.review_iterations = ((.review_iterations // 0) + 1)
      | .updated_at = $now' \
     "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  echo "review_iterations=$(jq -r '.review_iterations' "$STATE_FILE")"
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
  init)                      cmd_init "$@" ;;
  read)                      cmd_read ;;
  get)                       cmd_get "$@" ;;
  set)                       cmd_set "$@" ;;
  advance)                   cmd_advance ;;
  metric)                    cmd_metric "$@" ;;
  cleanup)                   cmd_cleanup ;;
  skip-declare)              cmd_skip_declare "$@" ;;
  record-invocation)         cmd_record_invocation "$@" ;;
  record-review-iteration)   cmd_record_review_iteration ;;
  "" )                       die "subcommand required: init|read|get|set|advance|metric|cleanup|skip-declare|record-invocation|record-review-iteration" ;;
  *)                         die "unknown subcommand: $sub" ;;
esac
