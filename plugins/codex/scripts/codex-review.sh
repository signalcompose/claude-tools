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
    echo "  codex-review.sh --staged     # Review all uncommitted changes (staged + unstaged)"
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
    # Review ALL uncommitted changes (staged + unstaged) using official Codex CLI
    # Check: git diff --quiet (unstaged) OR git diff --cached --quiet (staged)
    # Each returns 0 if no diff, 1 if changes exist; ! inverts to trigger if ANY changes found
    if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "Reviewing all uncommitted changes (staged + unstaged)..."
        echo ""

        # Use official Codex review subcommand for uncommitted changes
        # This provides structured review with prioritized suggestions
        if [ -n "$TIMEOUT_CMD" ]; then
            "$TIMEOUT_CMD" 120 codex exec review uncommitted 2>&1
        else
            codex exec review uncommitted 2>&1
        fi
    else
        echo "No uncommitted changes to review."
        echo "Make changes or stage files with: git add <files>"
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

    # Build file content for review via stdin
    # For directories, concatenate all text files; for single file, use directly
    if [ -d "$TARGET" ]; then
        # Directory: find and concatenate text files
        FILE_CONTENT=$(find "$TARGET" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" \) -print0 2>/dev/null | while IFS= read -r -d '' file; do
            echo "=== FILE: $file ==="
            cat "$file" 2>/dev/null || true
            echo ""
        done)
    else
        # Single file: read directly
        FILE_CONTENT=$(cat "$TARGET" 2>/dev/null)
    fi

    if [ -z "$FILE_CONTENT" ]; then
        echo "ERROR: No readable content found in: $TARGET"
        exit 1
    fi

    # Execute codex exec with review prompt via stdin
    REVIEW_PROMPT="Review this code for bugs, security issues, and best practices. Focus on critical issues first. Provide actionable suggestions."

    if [ -n "$TIMEOUT_CMD" ]; then
        echo "$FILE_CONTENT" | "$TIMEOUT_CMD" 120 codex exec --sandbox read-only "$REVIEW_PROMPT" 2>&1
    else
        echo "$FILE_CONTENT" | codex exec --sandbox read-only "$REVIEW_PROMPT" 2>&1
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
    if [ "$TARGET" = "--staged" ]; then
        echo "Run 'codex exec review uncommitted' directly for detailed error output."
    else
        echo "Run 'codex exec --sandbox read-only \"<prompt>\" < <file>' directly for detailed error output."
    fi
    echo "Common causes: invalid API key, network issues, rate limiting."
    exit $EXIT_CODE
fi

exit 0
