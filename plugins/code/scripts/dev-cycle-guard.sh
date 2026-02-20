#!/usr/bin/env bash
# dev-cycle-guard.sh — UserPromptSubmit hook
#
# Detects bare "implement" requests and reminds to use /code:dev-cycle.
# Soft reminder only (exit 0) — does NOT block the request.
#
# Trigger conditions (ALL must be true):
#   1. User message contains implementation keywords
#   2. .claude/dev-cycle.state.json does NOT exist (not already in a dev-cycle)
#   3. User did NOT explicitly invoke /code:dev-cycle in the message

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/dev-cycle.state.json"

# Already in a dev-cycle → skip
if [[ -f "$STATE_FILE" ]]; then
  exit 0
fi

# Read user message from hook input (stdin JSON: {"message": "..."})
HOOK_INPUT=$(cat)

# Parse message: use python3 if available, else grep-based fallback
if command -v python3 &>/dev/null; then
  USER_MSG=$(echo "$HOOK_INPUT" | python3 -c \
    "import json,sys; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null || echo "")
else
  USER_MSG=$(echo "$HOOK_INPUT" | grep -oE '"message"\s*:\s*"[^"]*"' | sed 's/^"message"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")
fi

# Skip if user explicitly invoked /code:dev-cycle
if echo "$USER_MSG" | grep -qiE "dev.?cycle|code:dev"; then
  exit 0
fi

# Check for implementation keywords
if echo "$USER_MSG" | grep -qiE \
  "(implement|sprint|実装|フェーズ|phase\s*[0-9]|plan|プラン|full.?cycle)"; then
  echo "🔴 DEV-CYCLE REMINDER: This project uses /code:dev-cycle for implementation tasks."
  echo "Running sprint alone skips: Compliance Audit (DDD/TDD/DRY/ISSUE/PROCESS), Ship (PR creation), and Retrospective."
  echo "If this is a full implementation task, use /code:dev-cycle instead of /code:sprint-impl alone."
  echo "(If sprint-only is intentional, this reminder can be ignored.)"
fi

exit 0
