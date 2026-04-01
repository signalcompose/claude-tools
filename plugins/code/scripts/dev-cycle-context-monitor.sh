#!/usr/bin/env bash
# dev-cycle-context-monitor.sh — PostToolUse hook
# dev-cycle 中のみ remaining_percentage を sidecar ファイルに記録
# Matcher in hooks.json limits firing to file/content tools (Bash, Edit, Write, Read, Grep, Glob,
# NotebookEdit, WebFetch, WebSearch). Meta-tools (Agent, Skill, SendMessage, etc.) are excluded
# because their PostToolUse payloads do NOT include context_window.remaining_percentage.
# Coverage is maintained: tools called WITHIN a skill (Bash, Read, etc.) fire this hook normally.
# The case guard below provides defense-in-depth and future-proofs against matcher broadening.
# When adding new tools, update BOTH the matcher AND the case guard below.

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

# Read stdin (PostToolUse hook provides JSON via stdin; guard against empty payload or read errors)
input=$(cat 2>/dev/null) || exit 0
[[ -n "$input" ]] || exit 0

# Skip tool types whose payloads lack context_window (e.g., Agent, SendMessage).
# NOTE: If you update this list, also update the matcher in hooks.json (PostToolUse).
TOOL_NAME=$(echo "$input" | jq -r '.tool_name // empty' 2>/dev/null) || exit 0
[[ -n "$TOOL_NAME" ]] || exit 0
case "$TOOL_NAME" in
  Agent|SendMessage|TaskCreate|TaskUpdate|TaskList|TaskGet|TeamCreate|TeamDelete|EnterPlanMode|ExitPlanMode|AskUserQuestion|Skill|ToolSearch|EnterWorktree) exit 0 ;;
  Bash|Edit|Write|Read|Grep|Glob|NotebookEdit|WebFetch|WebSearch) ;;
  *) exit 0 ;;
esac

REMAINING=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)
[[ -n "$REMAINING" && "$REMAINING" != "null" ]] || exit 0

# Read stage from state file (if available) for sidecar enrichment
STAGE=""
if [[ -f "$STATE_FILE" ]]; then
  STAGE=$(jq -r '.stage // empty' "$STATE_FILE" 2>/dev/null) || true
fi

# Atomic write (一時ファイル → mv; same-dir temp avoids cross-device mv issues)
TMPFILE=$(mktemp "${SIDECAR_FILE}.XXXXXX" 2>/dev/null) || exit 0
trap 'rm -f "${TMPFILE:-}"' EXIT

if [[ -n "$STAGE" ]]; then
  jq -n --arg remaining "$REMAINING" --arg ts "$(date +%s)" --arg stage "$STAGE" \
    '{remaining:($remaining|tonumber), ts:($ts|tonumber), stage:$stage}' > "$TMPFILE" 2>/dev/null || exit 0
else
  jq -n --arg remaining "$REMAINING" --arg ts "$(date +%s)" \
    '{remaining:($remaining|tonumber), ts:($ts|tonumber)}' > "$TMPFILE" 2>/dev/null || exit 0
fi
mv "$TMPFILE" "$SIDECAR_FILE"
trap - EXIT

exit 0
