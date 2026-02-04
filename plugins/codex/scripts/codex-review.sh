#!/bin/bash
# codex-review.sh - Execute Codex CLI for code review
# Usage: codex-review.sh [--staged | file_or_directory]

set -e
set -o pipefail

# Temp file cleanup management
TEMP_FILES=()
cleanup() {
    for f in "${TEMP_FILES[@]}"; do
        rm -f "$f"
    done
}
trap cleanup EXIT

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

    # Maximum content size limit (500KB) to avoid API token limits
    MAX_CONTENT_SIZE=512000

    # Supported file extensions for code review (quoted to prevent glob expansion)
    # Includes: shell, python, javascript/typescript, go, rust, java, c/c++,
    # ruby, php, swift, kotlin, vue, css/scss, sql, xml, toml, markdown, json, yaml
    FILE_EXTENSIONS='-name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.rb" -o -name "*.php" -o -name "*.swift" -o -name "*.kt" -o -name "*.vue" -o -name "*.css" -o -name "*.scss" -o -name "*.sql" -o -name "*.xml" -o -name "*.toml" -o -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml"'

    # Build file content for review via stdin
    # For directories, concatenate all text files; for single file, use directly
    if [ -d "$TARGET" ]; then
        # Create temp file for find errors
        FIND_ERRORS=$(mktemp)
        TEMP_FILES+=("$FIND_ERRORS")

        # First, check if directory has any matching files
        # shellcheck disable=SC2086
        FILE_COUNT=$(eval "find \"$TARGET\" -type f \( $FILE_EXTENSIONS \)" 2>"$FIND_ERRORS" | wc -l | tr -d ' ')

        # Report find errors if any occurred
        if [ -s "$FIND_ERRORS" ]; then
            echo "WARNING: Some files/directories could not be accessed:" >&2
            cat "$FIND_ERRORS" >&2
            echo "" >&2
        fi

        if [ "$FILE_COUNT" -eq 0 ]; then
            echo "ERROR: No supported source files found in: $TARGET"
            echo "Supported extensions: .sh, .py, .js, .jsx, .ts, .tsx, .go, .rs, .java, .c, .cpp, .h, .hpp,"
            echo "                      .rb, .php, .swift, .kt, .vue, .css, .scss, .sql, .xml, .toml,"
            echo "                      .md, .json, .yaml, .yml"
            exit 1
        fi

        echo "Found $FILE_COUNT file(s) to review..."

        # Collect content with error reporting using process substitution
        FILE_CONTENT=""
        READ_ERRORS=0
        # shellcheck disable=SC2086
        while IFS= read -r -d '' file; do
            FILE_HEADER="=== FILE: $file ==="
            if file_content=$(cat "$file" 2>&1); then
                FILE_CONTENT+="$FILE_HEADER"$'\n'"$file_content"$'\n\n'
            else
                echo "WARNING: Could not read file: $file - $file_content" >&2
                READ_ERRORS=$((READ_ERRORS + 1))
            fi
        done < <(eval "find \"$TARGET\" -type f \( $FILE_EXTENSIONS \) -print0" 2>>"$FIND_ERRORS")

        if [ $READ_ERRORS -gt 0 ]; then
            echo "WARNING: $READ_ERRORS file(s) could not be read (see above)" >&2
            echo "" >&2
        fi
    else
        # Single file: read directly with error capture
        if [ ! -r "$TARGET" ]; then
            echo "ERROR: Cannot read file (permission denied): $TARGET"
            exit 1
        fi

        CAT_ERROR=$(mktemp)
        TEMP_FILES+=("$CAT_ERROR")

        if ! FILE_CONTENT=$(cat "$TARGET" 2>"$CAT_ERROR"); then
            echo "ERROR: Failed to read file: $TARGET"
            if [ -s "$CAT_ERROR" ]; then
                cat "$CAT_ERROR" >&2
            fi
            exit 1
        fi
    fi

    if [ -z "$FILE_CONTENT" ]; then
        echo "ERROR: No readable content found in: $TARGET"
        exit 1
    fi

    # Check content size limit
    CONTENT_SIZE=${#FILE_CONTENT}
    if [ "$CONTENT_SIZE" -gt "$MAX_CONTENT_SIZE" ]; then
        echo "WARNING: Content size (${CONTENT_SIZE} bytes) exceeds limit (${MAX_CONTENT_SIZE} bytes)." >&2
        echo "         Truncating to first ${MAX_CONTENT_SIZE} bytes. Consider reviewing smaller scope." >&2
        FILE_CONTENT="${FILE_CONTENT:0:$MAX_CONTENT_SIZE}"
        echo "" >&2
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
