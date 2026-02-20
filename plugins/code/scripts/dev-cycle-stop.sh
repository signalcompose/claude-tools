#!/usr/bin/env bash
# dev-cycle-stop.sh — Stop hook for /code:dev-cycle auto-chain enforcement
#
# Reads .claude/dev-cycle.state.json to determine if the dev-cycle is
# still in progress. If so, blocks Claude from stopping and instructs
# it to invoke the next skill.
#
# When no state file exists (standalone skill usage), exits cleanly.

set -euo pipefail

# Fail open if jq is not available
if ! command -v jq &>/dev/null; then
  exit 0
fi

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/dev-cycle.state.json"

# No state file → not in a dev-cycle → allow stop
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Read hook input from stdin (Claude Code provides stop_hook_active)
HOOK_INPUT=$(cat)

# Validate JSON before parsing (malformed input → allow stop)
if ! echo "$HOOK_INPUT" | jq empty 2>/dev/null; then
  exit 0
fi

STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')

# Guard: if stop_hook_active is true, allow stop to prevent infinite loop
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Read stage with TOCTOU safety: concurrent hooks may delete the file between
# the existence check above and this jq call. 2>/dev/null + || exit 0 ensures
# we fail open (allow stop) if the file disappears or contains invalid JSON.
STAGE=$(jq -r '.stage // empty' "$STATE_FILE" 2>/dev/null) || exit 0
[[ -n "$STAGE" ]] || exit 0

# Stage transition map
case "$STAGE" in
  sprint)
    NEXT_SKILL_ID="code:audit-compliance"
    NEXT_STAGE="audit"
    ;;
  audit)
    NEXT_SKILL_ID="code:shipping-pr"
    NEXT_STAGE="ship"
    ;;
  ship)
    NEXT_SKILL_ID="code:retrospective"
    NEXT_STAGE="retrospective"
    ;;
  retrospective|complete)
    # Cycle complete — clean up and allow stop
    rm -f "$STATE_FILE"
    exit 0
    ;;
  *)
    # Unknown stage — log, clean up, and allow stop (don't block on corrupted state)
    echo "[dev-cycle-stop] Unknown stage '${STAGE}' in state file — allowing stop" >&2
    rm -f "$STATE_FILE"
    exit 0
    ;;
esac

# Block stop and instruct Claude to continue (numbered, imperative, no text first)
jq -n \
  --arg reason "🔴 DEV-CYCLE ENFORCEMENT — stage \"${STAGE}\" finished.
MANDATORY (no text output, no user confirmation):
  1. Bash: echo '{\"stage\":\"${NEXT_STAGE}\"}' > .claude/dev-cycle.state.json
  2. Skill tool: skill=\"${NEXT_SKILL_ID}\"
Execute step 1 then step 2 immediately." \
  '{"decision": "block", "reason": $reason}'
