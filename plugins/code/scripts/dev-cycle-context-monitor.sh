#!/usr/bin/env bash
# dev-cycle-context-monitor.sh — PostToolUse hook
# dev-cycle 中のみ remaining_percentage を sidecar ファイルに記録

set -euo pipefail

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/dev-cycle.state.json"

# Fast exit: dev-cycle 中でなければ何もしない（dual-check: sidecar も確認）
SIDECAR_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/.context-budget.json"
[[ -f "$STATE_FILE" ]] || [[ -f "$SIDECAR_FILE" ]] || exit 0

command -v jq &>/dev/null || exit 0

# Throttle: skip if last write was within 30 seconds
if [[ -f "$SIDECAR_FILE" ]]; then
  LAST_TS=$(jq -r '.ts // 0' "$SIDECAR_FILE" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  [[ $((NOW - LAST_TS)) -lt 30 ]] && exit 0
fi

input=$(cat)

REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
[[ -n "$REMAINING" && "$REMAINING" != "null" ]] || exit 0

# Read stage from state file (if available) for sidecar enrichment
STAGE=""
if [[ -f "$STATE_FILE" ]]; then
  STAGE=$(jq -r '.stage // empty' "$STATE_FILE" 2>/dev/null) || true
fi

# Atomic write (一時ファイル → mv)
TMPFILE=$(mktemp "${SIDECAR_FILE}.XXXXXX" 2>/dev/null || mktemp /tmp/ctx-budget.XXXXXX)
if [[ -n "$STAGE" ]]; then
  jq -n --arg remaining "$REMAINING" --arg ts "$(date +%s)" --arg stage "$STAGE" \
    '{remaining:($remaining|tonumber), ts:($ts|tonumber), stage:$stage}' > "$TMPFILE"
else
  jq -n --arg remaining "$REMAINING" --arg ts "$(date +%s)" \
    '{remaining:($remaining|tonumber), ts:($ts|tonumber)}' > "$TMPFILE"
fi
mv "$TMPFILE" "$SIDECAR_FILE"

exit 0
