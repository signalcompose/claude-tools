#!/bin/bash
set -euo pipefail

# PR Review Team - Stop Hook (Command-based)
# Verifies workflow completion using state file + transcript fallback
# Part of 5-layer defense: Layer 1 (deterministic gate)

INPUT=$(cat)

# Layer 0: Infinite loop prevention (same pattern as CVI/dev-cycle)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Session detection via flag file (state file doubles as active-review flag)
# If no state file exists, this is not a pr-review-team session → pass immediately
shopt -s nullglob
STATE_FILES=(/tmp/claude/pr-review-*.state)
shopt -u nullglob
if [ ${#STATE_FILES[@]} -eq 0 ]; then
    exit 0
fi

# Read progress from state file
STATE_FILE="${STATE_FILES[0]}"
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "{}")

# Get transcript path for fallback verification
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")

MISSING=""

# Check 1: Security checklist completion
SECURITY_DONE=$(echo "$STATE" | jq -r '.security_done // false' 2>/dev/null || echo "false")
if [ "$SECURITY_DONE" != "true" ]; then
    if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
        if ! grep -q "security-checklist.md" "$TRANSCRIPT_PATH" 2>/dev/null; then
            MISSING="${MISSING}\n- Security checklist was not read"
        fi
    else
        MISSING="${MISSING}\n- Security checklist was not completed (state: security_done=false)"
    fi
fi

# Check 2: Fixer agent spawned when issues were found
FIXER_DONE=$(echo "$STATE" | jq -r '.fixer_done // false' 2>/dev/null || echo "false")

# Check transcript for evidence of issues regardless of state counts
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    if grep -qE '"Critical Issues"|"Important Issues"' "$TRANSCRIPT_PATH" 2>/dev/null; then
        if [ "$FIXER_DONE" != "true" ]; then
            MISSING="${MISSING}\n- Fixer agent was not spawned (direct editing is prohibited)"
        fi
    fi
fi

if [ -n "$MISSING" ]; then
    REASON=$(printf 'PR review workflow incomplete:%b\n\nComplete all required steps before stopping.' "$MISSING")
    printf '%s' "$REASON" | jq -Rs '{"decision":"block","reason":.}'
    exit 0
fi

exit 0
