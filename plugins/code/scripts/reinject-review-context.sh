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

read -r PR PHASE ITERATIONS < <(echo "$STATE" | jq -r '[.pr // "unknown", .phase // "unknown", (.iterations // 0 | tostring)] | @tsv' 2>/dev/null || echo "unknown unknown 0")

cat << EOF
🔴 PR REVIEW IN PROGRESS (recovered after compaction)
PR: #$PR | Phase: $PHASE | Iterations: $ITERATIONS
Full state: $STATE

Continue the pr-review-team workflow from where you left off.
EOF
