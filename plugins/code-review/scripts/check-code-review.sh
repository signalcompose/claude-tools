#!/bin/bash
# Pre-commit code review hook for Claude Code
# This script checks if the command is 'git commit' and blocks it
# unless code review has been completed (verified by hash).

# Read JSON from stdin
INPUT=$(cat)

# Extract the command from tool_input.command (nested JSON structure)
if command -v jq &> /dev/null; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
    # Fallback: simple pattern matching for tool_input.command
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
fi

# Check if this is a git commit command
if [[ "$COMMAND" =~ ^git[[:space:]]+commit ]] || [[ "$COMMAND" =~ git[[:space:]]+commit ]]; then
    # Use project-local .claude directory or /tmp/claude as fallback
    if [[ -d ".claude" ]]; then
        REVIEW_FILE=".claude/review-approved"
    else
        REVIEW_FILE="/tmp/claude/review-approved"
    fi

    # Check if review approval file exists
    if [[ -f "$REVIEW_FILE" ]]; then
        # Get current staged changes hash
        CURRENT_HASH=$(git diff --cached --raw 2>/dev/null | shasum -a 256 | cut -d' ' -f1)
        APPROVED_HASH=$(cat "$REVIEW_FILE" 2>/dev/null)

        if [[ "$CURRENT_HASH" == "$APPROVED_HASH" ]]; then
            # Review completed and staged changes haven't changed
            # Remove the approval file and allow commit
            rm -f "$REVIEW_FILE"
            exit 0
        else
            echo "Staged changes have been modified since review." >&2
            echo "Please run code review again with: /code:review-commit" >&2
            rm -f "$REVIEW_FILE"
            exit 2
        fi
    fi

    echo "STOP: Code review required before commit!" >&2
    echo "" >&2
    echo "Please run: /code:review-commit" >&2
    exit 2  # Exit code 2 blocks the tool call
fi

# Allow other commands to proceed
exit 0
