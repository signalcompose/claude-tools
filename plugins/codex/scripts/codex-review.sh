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
    # Review uncommitted changes using official Codex review subcommand
    # Requires at least some staged changes to proceed
    # Note: git diff --quiet returns 0 if no diff, 1 if there is a diff
    if ! git diff --cached --quiet; then
        echo "Reviewing uncommitted changes..."
        echo ""

        # Use official Codex review subcommand for uncommitted changes
        # This reviews ALL uncommitted changes (staged + unstaged), providing
        # structured review with prioritized suggestions
        if [ -n "$TIMEOUT_CMD" ]; then
            $TIMEOUT_CMD 120 codex exec review uncommitted 2>&1
        else
            codex exec review uncommitted 2>&1
        fi
    else
        echo "No staged changes to review."
        echo "Stage changes with: git add <files>"
        exit 0
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
