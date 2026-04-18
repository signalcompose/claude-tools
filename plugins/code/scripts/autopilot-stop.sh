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

if echo "$HOOK_INPUT" | jq empty 2>/dev/null; then
  STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
  if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
  fi
fi

# Read current phase (fail-open if state file is stale)
PHASE=$(jq -r '.phase // empty' "$STATE_FILE" 2>/dev/null || true)
[ -n "$PHASE" ] || exit 0

# Phase-specific next skill mapping
case "$PHASE" in
  sprint)
    NEXT_SKILL="code:audit-compliance"
    NEXT_PHASE="audit"
    ;;
  audit)
    NEXT_SKILL="simplify"
    NEXT_PHASE="simplify"
    ;;
  simplify)
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

# Advance state file (sets last_successful_stage, new phase, resets iteration)
STATE_SCRIPT="${CLAUDE_PLUGIN_ROOT:-}/scripts/autopilot-state.sh"
if [ -x "$STATE_SCRIPT" ]; then
  "$STATE_SCRIPT" advance >/dev/null 2>&1 || true
else
  # Inline fallback: just update the phase field
  TMP=$(mktemp)
  jq --arg cur "$PHASE" --arg nxt "$NEXT_PHASE" \
    '.last_successful_stage = $cur | .phase = $nxt | .iteration = 0' \
    "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"
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
