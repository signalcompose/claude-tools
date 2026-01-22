#!/bin/bash
# codex-review.sh - Execute Codex CLI for code review
# Usage: codex-review.sh [--staged | file_or_directory]

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check Codex availability
if [ ! -f "$SCRIPT_DIR/check-codex.sh" ]; then
    echo "ERROR: check-codex.sh not found in $SCRIPT_DIR"
    echo "Plugin installation may be corrupted. Try reinstalling."
    exit 1
fi
"$SCRIPT_DIR/check-codex.sh" || exit 1

if [ -z "$1" ]; then
    echo "ERROR: No target specified."
    echo "Usage:"
    echo "  codex-review.sh --staged     # Review staged changes"
    echo "  codex-review.sh <file>       # Review specific file"
    echo "  codex-review.sh <directory>  # Review directory"
    exit 1
fi

TARGET="$1"

echo "Executing Codex Code Review..."
echo "---"

if [ "$TARGET" = "--staged" ]; then
    # Verify we're in a git repository BEFORE disabling error handling
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "ERROR: Not in a git repository or git is not functioning correctly."
        echo "Run 'git status' to diagnose the issue."
        exit 1
    fi
fi

# Determine timeout command (gtimeout for macOS with coreutils, timeout for Linux)
if command -v gtimeout &> /dev/null; then
    TIMEOUT_CMD="gtimeout"
elif command -v timeout &> /dev/null; then
    TIMEOUT_CMD="timeout"
else
    TIMEOUT_CMD=""
    echo "WARNING: No timeout command available (gtimeout/timeout not found)." >&2
    echo "Command will run without timeout protection. On macOS: brew install coreutils" >&2
fi

set +e  # Temporarily disable exit on error to capture exit code

if [ "$TARGET" = "--staged" ]; then
    # Review staged changes
    STAGED_DIFF=$(git diff --cached 2>&1)
    DIFF_EXIT_CODE=$?

    if [ $DIFF_EXIT_CODE -ne 0 ]; then
        echo "ERROR: Failed to get staged changes."
        echo "Git output: $STAGED_DIFF"
        echo "Try running 'git status' to diagnose the issue."
        exit 1
    fi

    if [ -z "$STAGED_DIFF" ]; then
        echo "No staged changes to review."
        echo "Stage changes with: git add <files>"
        exit 0
    fi

    echo "Reviewing staged changes..."
    echo ""

    # Pass staged diff to codex for review
    if [ -n "$TIMEOUT_CMD" ]; then
        $TIMEOUT_CMD 120 codex exec "Review the following git diff for potential issues, bugs, and improvements:

$STAGED_DIFF" 2>&1
    else
        codex exec "Review the following git diff for potential issues, bugs, and improvements:

$STAGED_DIFF" 2>&1
    fi
else
    # Review file or directory
    if [ ! -e "$TARGET" ]; then
        echo "ERROR: Target not found: $TARGET"
        exit 1
    fi

    echo "Reviewing: $TARGET"
    echo ""

    # Execute codex review command
    if [ -n "$TIMEOUT_CMD" ]; then
        $TIMEOUT_CMD 120 codex review "$TARGET" 2>&1
    else
        codex review "$TARGET" 2>&1
    fi
fi

EXIT_CODE=$?
set -e  # Re-enable exit on error

if [ $EXIT_CODE -eq 124 ]; then
    echo ""
    echo "ERROR: Codex CLI timed out after 120 seconds."
    exit 124
elif [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "ERROR: Codex CLI failed with exit code $EXIT_CODE"
    echo "Run 'codex review <target>' directly for detailed error output."
    echo "Common causes: invalid API key, network issues, rate limiting."
    exit $EXIT_CODE
fi

exit 0
