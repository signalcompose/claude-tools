#!/bin/bash
# PostCompact hook: Re-inject PR review state into Claude's context
# Fires after auto-compaction to preserve workflow continuity

shopt -s nullglob
STATE_FILES=(/tmp/claude/pr-review-*.state)
shopt -u nullglob

if [ ${#STATE_FILES[@]} -eq 0 ]; then
    exit 0
fi

STATE_FILE="${STATE_FILES[0]}"
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "{}")

if [ "$STATE" = "{}" ]; then
    exit 0
fi

PR=$(echo "$STATE" | jq -r '.pr // "unknown"' 2>/dev/null)
PHASE=$(echo "$STATE" | jq -r '.phase // "unknown"' 2>/dev/null)
ITERATIONS=$(echo "$STATE" | jq -r '.iterations // 0' 2>/dev/null)

cat << EOF
🔴 PR REVIEW IN PROGRESS (recovered after compaction)
PR: #$PR | Phase: $PHASE | Iterations: $ITERATIONS
State file: $STATE_FILE
Full state: $STATE

Continue the pr-review-team workflow from where you left off.
Read the state file for details: cat $STATE_FILE
EOF
