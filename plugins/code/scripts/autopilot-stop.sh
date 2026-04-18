#!/usr/bin/env bash
# autopilot-stop.sh — Stop hook for /code:autopilot phase-chain enforcement.
#
# Reads .claude/autopilot.state.json. If the cycle is still in progress, blocks
# Claude from stopping and instructs it to invoke the next phase skill.
#
# Coexists with dev-cycle-stop.sh: different state files, independent behavior.
#
# Stop hook input format (stdin, JSON): { "stop_hook_active": bool, ... }

set -euo pipefail

# Fail open if jq is unavailable
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_FILE="${PROJECT_DIR}/.claude/autopilot.state.json"

# No state file → not an autopilot session, allow stop
[ -f "$STATE_FILE" ] || exit 0

# Read hook input (guard: stop_hook_active prevents infinite loops)
HOOK_INPUT=$(cat || true)

# Single jq pass: validate + extract. Default to false on invalid JSON.
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Read current phase + failure marker + iteration + metrics (fail-open if stale)
STATE_JSON=$(jq -c '{
  phase: (.phase // ""),
  iteration: (.iteration // 0),
  last_failure: (.last_failure // ""),
  critical: (.metrics.critical // 0),
  important: (.metrics.important // 0)
}' "$STATE_FILE" 2>/dev/null || echo "")
[ -n "$STATE_JSON" ] || exit 0

PHASE=$(echo "$STATE_JSON" | jq -r '.phase')
ITERATION=$(echo "$STATE_JSON" | jq -r '.iteration')
LAST_FAILURE=$(echo "$STATE_JSON" | jq -r '.last_failure')
METRIC_CRITICAL=$(echo "$STATE_JSON" | jq -r '.critical')
METRIC_IMPORTANT=$(echo "$STATE_JSON" | jq -r '.important')

[ -n "$PHASE" ] || exit 0

# Failure guard: if the current phase recorded a failure, do not auto-advance.
# Clean up state and allow stop so the user can investigate.
if [ -n "$LAST_FAILURE" ]; then
  echo "[autopilot-stop] phase '$PHASE' recorded failure: $LAST_FAILURE — cleaning up and allowing stop" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Iteration guard: prevent cross-invocation infinite loops when advance fails.
MAX_ITERATIONS_PER_PHASE=5
if [ "$ITERATION" -ge "$MAX_ITERATIONS_PER_PHASE" ]; then
  echo "[autopilot-stop] phase '$PHASE' exceeded iteration cap ($MAX_ITERATIONS_PER_PHASE) — aborting" >&2
  rm -f "$STATE_FILE"
  exit 0
fi

# Phase-specific next skill mapping
case "$PHASE" in
  sprint)
    NEXT_SKILL="code:audit-compliance"
    NEXT_PHASE="audit"
    ;;
  audit)
    # `simplify` here refers to the plugin-registered skill of the same name
    # (Review changed code for reuse, quality, efficiency). Invoke via Skill tool.
    NEXT_SKILL="simplify"
    NEXT_PHASE="simplify"
    ;;
  simplify)
    # Pre-ship gate: refuse to advance with unresolved review findings.
    if [ "$METRIC_CRITICAL" != "0" ] || [ "$METRIC_IMPORTANT" != "0" ]; then
      echo "[autopilot-stop] simplify not converged (critical=$METRIC_CRITICAL important=$METRIC_IMPORTANT) — aborting before ship" >&2
      rm -f "$STATE_FILE"
      exit 0
    fi
    NEXT_SKILL="code:shipping-pr"
    NEXT_PHASE="ship"
    SKILL_ARG="--skip-review"
    ;;
  ship)
    NEXT_SKILL="code:pr-review-team"
    NEXT_PHASE="post-pr-review"
    ;;
  post-pr-review)
    NEXT_SKILL="code:retrospective"
    NEXT_PHASE="retrospective"
    ;;
  retrospective|complete)
    # Cycle done — clean up + allow stop
    rm -f "$STATE_FILE"
    exit 0
    ;;
  *)
    # Unknown phase — fail open, log
    echo "[autopilot-stop] unknown phase '$PHASE' — cleaning up and allowing stop" >&2
    rm -f "$STATE_FILE"
    exit 0
    ;;
esac

# Advance state file (sets last_successful_stage, new phase, resets iteration).
# If the external script is available, delegate. Otherwise use inline fallback
# and log the degraded path so operators can diagnose missing CLAUDE_PLUGIN_ROOT.
advance_ok=0
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -x "${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-state.sh" ]; then
  if "${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-state.sh" advance >/dev/null 2>&1; then
    advance_ok=1
  else
    echo "[autopilot-stop] autopilot-state.sh advance failed — falling back to inline update" >&2
  fi
else
  echo "[autopilot-stop] CLAUDE_PLUGIN_ROOT unset or state script not executable — using inline advance" >&2
fi

if [ "$advance_ok" = "0" ]; then
  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT
  if jq --arg cur "$PHASE" --arg nxt "$NEXT_PHASE" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      '.last_successful_stage = $cur | .phase = $nxt | .iteration = 0 | .updated_at = $now' \
      "$STATE_FILE" > "$TMP"; then
    mv "$TMP" "$STATE_FILE"
    trap - EXIT
  else
    echo "[autopilot-stop] inline advance jq failed — state file may be stale, allowing stop" >&2
    rm -f "$TMP"
    exit 0
  fi
fi

# Emit the standard Stop hook block payload: decision=block + reason
skill_instr="Skill tool: skill=\"${NEXT_SKILL}\""
[ -n "${SKILL_ARG:-}" ] && skill_instr="${skill_instr} args=\"${SKILL_ARG}\""

jq -n --arg reason "🔴 AUTOPILOT ENFORCEMENT — phase \"${PHASE}\" finished.
MANDATORY (no text output, no user confirmation):
  1. Bash (optional): review state at .claude/autopilot.state.json
  2. ${skill_instr}
Execute step 2 immediately. Do not output text first." \
  '{"decision":"block","reason":$reason}'
