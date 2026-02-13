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

# Skip if --no-verify flag is present (emergency bypass)
if [[ "$COMMAND" =~ (^|[[:space:]])--no-verify([[:space:]]|$) ]]; then
    echo "⚠️  Code review skipped (--no-verify flag detected)" >&2
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

# Calculate review-in-progress marker path
REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"

# Calculate fixer-commit marker path
FIXER_COMMIT_MARKER="/tmp/claude/fixer-commit-${REPO_HASH}"

# Safety: Check review marker age (prevent stale markers)
if [[ -f "$REVIEW_MARKER" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        MARKER_AGE=$(($(date +%s) - $(stat -f %m "$REVIEW_MARKER")))
    else
        # Linux
        MARKER_AGE=$(($(date +%s) - $(stat -c %Y "$REVIEW_MARKER")))
    fi
    MAX_AGE=$((60 * 60))  # 1 hour

    if [[ $MARKER_AGE -gt $MAX_AGE ]]; then
        echo "⚠️  Review marker is stale (${MARKER_AGE}s old), removing..." >&2
        rm -f "$REVIEW_MARKER"
    fi
fi

# Detect fixer agent commits during active review
if [[ -f "$REVIEW_MARKER" ]]; then
    # Review is in progress
    # Use flock for atomic marker check-and-delete to prevent race conditions
    FIXER_ALLOWED=0
    (
        flock -x 200
        if [[ -f "$FIXER_COMMIT_MARKER" ]]; then
            # Fixer agent committing during review - allow
            echo "📝 Review in progress: allowing fixer agent commit" >&2

            # Remove marker after successful check
            # (next commit will go through normal review flow)
            rm -f "$FIXER_COMMIT_MARKER"
            exit 0
        fi
        exit 1
    ) 200>"${FIXER_COMMIT_MARKER}.lock"
    FIXER_ALLOWED=$?

    # Cleanup lock file
    rm -f "${FIXER_COMMIT_MARKER}.lock"

    # If flock block exited 0, the marker was present - allow commit
    if [[ $FIXER_ALLOWED -eq 0 ]]; then
        exit 0
    else
        # Manual commit during review - block
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "⛔ Review In Progress - Manual Commits Blocked" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "" >&2
        echo "A code review is currently in progress." >&2
        echo "Please wait for the review team to complete." >&2
        echo "" >&2
        echo "The fixer agent is working on resolving issues." >&2
        echo "Manual commits during review could cause conflicts." >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        exit 2
    fi
fi

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
