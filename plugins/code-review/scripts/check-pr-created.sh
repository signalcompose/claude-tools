#!/bin/bash
# PostToolUse hook: Detect PR creation and prompt for review
# Exit 0: Allow (with optional message)

# Read hook input from stdin
INPUT=$(cat)

# Extract command from tool_input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
if [[ -z "$COMMAND" ]]; then
    # Fallback: try to extract with grep
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

# Check if this was a gh pr create command
if [[ "$COMMAND" =~ gh[[:space:]]+pr[[:space:]]+create ]]; then
    # Extract tool output (the result of the command)
    OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null)

    # Check if PR URL was returned (indicates success)
    if [[ "$OUTPUT" =~ https://github.com/.*/pull/[0-9]+ ]]; then
        # Extract PR number
        PR_URL=$(echo "$OUTPUT" | grep -o 'https://github.com/[^/]*/[^/]*/pull/[0-9]*' | head -1)
        PR_NUM=$(echo "$PR_URL" | grep -o '[0-9]*$')

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 PR #${PR_NUM} created. Run self-review:"
        echo ""
        echo "   /code:review-pr ${PR_NUM}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
fi

exit 0
