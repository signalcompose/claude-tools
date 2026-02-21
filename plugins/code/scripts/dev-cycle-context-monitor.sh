#!/usr/bin/env bash
# dev-cycle-context-monitor.sh — PostToolUse hook
# dev-cycle 中のみ remaining_percentage を sidecar ファイルに記録

set -euo pipefail

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/dev-cycle.state.json"

# Fast exit: dev-cycle 中でなければ何もしない
[[ -f "$STATE_FILE" ]] || exit 0

command -v jq &>/dev/null || exit 0

input=$(cat)

REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
[[ -n "$REMAINING" && "$REMAINING" != "null" ]] || exit 0

SIDECAR_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/.context-budget.json"

# Atomic write (一時ファイル → mv)
TMPFILE=$(mktemp "${SIDECAR_FILE}.XXXXXX" 2>/dev/null || mktemp /tmp/ctx-budget.XXXXXX)
jq -n --arg remaining "$REMAINING" --arg ts "$(date +%s)" \
  '{remaining:($remaining|tonumber), ts:($ts|tonumber)}' > "$TMPFILE"
mv "$TMPFILE" "$SIDECAR_FILE"

exit 0
