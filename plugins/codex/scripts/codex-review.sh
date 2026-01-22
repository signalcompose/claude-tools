#!/bin/bash
# codex-review.sh - Execute Codex CLI for code review
# Usage: codex-review.sh [--staged | file_or_directory]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check Codex availability
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

set +e  # Temporarily disable exit on error to capture exit code

if [ "$TARGET" = "--staged" ]; then
    # Review staged changes
    STAGED_DIFF=$(git diff --cached)

    if [ -z "$STAGED_DIFF" ]; then
        echo "No staged changes to review."
        echo "Stage changes with: git add <files>"
        exit 0
    fi

    echo "Reviewing staged changes..."
    echo ""

    # Pass staged diff to codex for review
    timeout 120 codex exec "Review the following git diff for potential issues, bugs, and improvements:

$STAGED_DIFF" 2>&1
else
    # Review file or directory
    if [ ! -e "$TARGET" ]; then
        echo "ERROR: Target not found: $TARGET"
        exit 1
    fi

    echo "Reviewing: $TARGET"
    echo ""

    # Execute codex review command
    timeout 120 codex review "$TARGET" 2>&1
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
    exit $EXIT_CODE
fi

exit 0
