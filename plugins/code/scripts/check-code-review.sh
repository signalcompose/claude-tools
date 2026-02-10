#!/bin/bash
# Pre-commit code review hook for Claude Code (flag-based)
# Blocks git commit unless code review approval flag exists.

# Read JSON from stdin
INPUT=$(cat)

# Extract the command from tool_input.command (nested JSON structure)
if command -v jq &> /dev/null; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
    # Fallback: simple pattern matching for tool_input.command
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
fi

# Skip gh commands (they may contain "git commit" in PR body text)
if [[ "$COMMAND" =~ ^gh[[:space:]] ]]; then
    exit 0
fi

# Only process git commit commands
if [[ ! "$COMMAND" =~ git[[:space:]]+commit ]]; then
    exit 0
fi

# Extract target directory if command contains "cd <path> &&"
TARGET_DIR=""
if [[ "$COMMAND" =~ ^cd[[:space:]]+([^[:space:]&]+)[[:space:]]*\&\& ]]; then
    TARGET_DIR="${BASH_REMATCH[1]}"
    # Expand ~ to home directory
    TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
fi

# Get repository root from target directory or current directory
if [[ -n "$TARGET_DIR" && -d "$TARGET_DIR" ]]; then
    REPO_ROOT=$(cd "$TARGET_DIR" && git rev-parse --show-toplevel 2>/dev/null || echo "unknown")
else
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "unknown")
fi

# Calculate repository-specific flag file path
REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
REVIEW_FLAG="/tmp/claude/review-approved-${REPO_HASH}"

# Check if review approval flag exists
if [[ -f "$REVIEW_FLAG" ]]; then
    # Review approved - remove flag and allow commit
    rm -f "$REVIEW_FLAG"
    exit 0
fi

# Review not completed - block commit with helpful message
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "⛔ Code Review Required" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "" >&2
echo "Commits require code review approval." >&2
echo "" >&2
echo "Run the review workflow:" >&2
echo "  /code:review-commit" >&2
echo "" >&2
echo "The review team will:" >&2
echo "  1. Analyze your changes for issues" >&2
echo "  2. Automatically fix critical/important problems" >&2
echo "  3. Iterate until code quality meets standards" >&2
echo "  4. Approve commit when ready (up to 5 iterations)" >&2
echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
exit 2  # Exit code 2 blocks the tool call
