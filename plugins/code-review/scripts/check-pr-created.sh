#!/bin/bash
# PostToolUse hook: Detect PR creation and prompt for review
# Exit 0: Allow (with optional message)

# Read hook input from stdin
INPUT=$(cat)

# Validate input
if [[ -z "$INPUT" ]]; then
    exit 0
fi

# Extract command from tool_input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [[ -z "$COMMAND" ]]; then
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# Check if this was a gh pr create command
if [[ "$COMMAND" =~ gh[[:space:]]+pr[[:space:]]+create ]]; then
    # Extract tool output
    OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null)
    if [[ -z "$OUTPUT" ]]; then
        OUTPUT=$(echo "$INPUT" | grep -o '"tool_output"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"tool_output"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi

    # Check if PR URL was returned
    if [[ "$OUTPUT" =~ https://github.com/.*/pull/[0-9]+ ]]; then
        PR_URL=$(echo "$OUTPUT" | grep -o 'https://github.com/[^/]*/[^/]*/pull/[0-9]*' | head -1)
        PR_NUM=$(echo "$PR_URL" | grep -o '[0-9]*$')

        # Validate PR number before output
        if [[ -n "$PR_NUM" ]]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📋 PR #${PR_NUM} created. Run self-review:"
            echo ""
            echo "   /pr-review-toolkit:review-pr ${PR_NUM}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        fi
    fi
fi

exit 0
