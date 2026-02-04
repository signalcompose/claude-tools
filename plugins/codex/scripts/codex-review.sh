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
        # Capture stderr separately (consistent with file/directory review)
        CODEX_STDERR=$(mktemp)
        TEMP_FILES+=("$CODEX_STDERR")

        if [ -n "$TIMEOUT_CMD" ]; then
            "$TIMEOUT_CMD" 120 codex exec review uncommitted 2>"$CODEX_STDERR"
        else
            codex exec review uncommitted 2>"$CODEX_STDERR"
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

    # Maximum content size limit (512KB) to avoid API token limits
    MAX_CONTENT_SIZE=512000

    # Supported file extensions for code review
    # Note: Contains find predicates as a string; eval is required to expand properly
    # Includes: shell, python, javascript/typescript, go, rust, java, c/c++,
    # ruby, php, swift, kotlin, vue, css/scss, sql, xml, toml, markdown, json, yaml
    SUPPORTED_EXTENSIONS="sh py js jsx ts tsx go rs java c cpp h hpp rb php swift kt vue css scss sql xml toml md json yaml yml"
    FILE_EXTENSIONS='-name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.rb" -o -name "*.php" -o -name "*.swift" -o -name "*.kt" -o -name "*.vue" -o -name "*.css" -o -name "*.scss" -o -name "*.sql" -o -name "*.xml" -o -name "*.toml" -o -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml"'

    # Build file content for review via stdin
    # For directories, concatenate all text files; for single file, use directly
    if [ -d "$TARGET" ]; then
        # Create temp file for find errors
        FIND_ERRORS=$(mktemp)
        TEMP_FILES+=("$FIND_ERRORS")

        # First, check if directory has any matching files
        # shellcheck disable=SC2086 -- Intentional: FILE_EXTENSIONS must expand to separate -name arguments
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

        # Collect content with error reporting
        FILE_CONTENT=""
        READ_ERRORS=0
        # shellcheck disable=SC2086 -- Intentional: FILE_EXTENSIONS must expand to separate -name arguments
        # Process substitution feeds null-delimited file list to safely handle filenames with spaces
        while IFS= read -r -d '' file; do
            FILE_HEADER="=== FILE: $file ==="
            # Capture file content and errors separately to avoid mixing them
            if file_content=$(cat "$file" 2>/dev/null); then
                FILE_CONTENT+="$FILE_HEADER"$'\n'"$file_content"$'\n\n'
            else
                read_error=$(cat "$file" 2>&1 >/dev/null || true)
                echo "WARNING: Could not read file: $file - $read_error" >&2
                READ_ERRORS=$((READ_ERRORS + 1))
            fi
        done < <(eval "find \"$TARGET\" -type f \( $FILE_EXTENSIONS \) -print0" 2>>"$FIND_ERRORS")

        if [ $READ_ERRORS -gt 0 ]; then
            echo "WARNING: $READ_ERRORS file(s) could not be read (see above)" >&2
            echo "" >&2
        fi
    else
        # Single file: validate extension first
        FILE_EXT="${TARGET##*.}"
        if ! echo "$SUPPORTED_EXTENSIONS" | grep -qw "$FILE_EXT"; then
            echo "WARNING: File extension .$FILE_EXT may not be a supported source file." >&2
            echo "Supported extensions: $SUPPORTED_EXTENSIONS" >&2
            echo "Proceeding anyway, but review may not be meaningful." >&2
            echo "" >&2
        fi

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
        # Distinguish between "no readable files" vs "file is empty"
        if [ ! -d "$TARGET" ]; then
            echo "WARNING: File is empty: $TARGET"
            echo "Nothing to review."
            exit 0
        else
            echo "ERROR: No readable content found in: $TARGET"
            exit 1
        fi
    fi

    # Check content size limit
    CONTENT_SIZE=${#FILE_CONTENT}
    if [ "$CONTENT_SIZE" -gt "$MAX_CONTENT_SIZE" ]; then
        LOST_BYTES=$((CONTENT_SIZE - MAX_CONTENT_SIZE))
        LOST_PERCENT=$((LOST_BYTES * 100 / CONTENT_SIZE))
        echo "WARNING: Content size (${CONTENT_SIZE} bytes) exceeds limit (${MAX_CONTENT_SIZE} bytes)." >&2
        echo "         Truncating ${LOST_BYTES} bytes (${LOST_PERCENT}% of content)." >&2
        echo "         Files at the end of the list may be partially or completely omitted." >&2
        echo "         Consider reviewing a smaller scope or specific files." >&2
        FILE_CONTENT="${FILE_CONTENT:0:$MAX_CONTENT_SIZE}"
        # Fix potential UTF-8 truncation by removing incomplete trailing bytes
        if ICONV_RESULT=$(printf '%s' "$FILE_CONTENT" | iconv -c -f UTF-8 -t UTF-8 2>/dev/null); then
            FILE_CONTENT="$ICONV_RESULT"
        else
            echo "WARNING: iconv not available or failed; UTF-8 sanitization skipped." >&2
        fi
        echo "" >&2
    fi

    # Execute codex exec with review prompt via stdin
    # Capture stderr separately to distinguish API errors from review output
    REVIEW_PROMPT="Review this code for bugs, security issues, and best practices. Focus on critical issues first. Provide actionable suggestions."
    CODEX_STDERR=$(mktemp)
    TEMP_FILES+=("$CODEX_STDERR")

    if [ -n "$TIMEOUT_CMD" ]; then
        echo "$FILE_CONTENT" | "$TIMEOUT_CMD" 120 codex exec --sandbox read-only "$REVIEW_PROMPT" 2>"$CODEX_STDERR"
    else
        echo "$FILE_CONTENT" | codex exec --sandbox read-only "$REVIEW_PROMPT" 2>"$CODEX_STDERR"
    fi
fi

# Capture exit code before checking stderr
CODEX_EXIT_CODE=$?

# Report codex stderr if any (shows API errors separately from review output)
if [ -n "${CODEX_STDERR:-}" ] && [ -s "$CODEX_STDERR" ]; then
    echo "" >&2
    echo "=== CODEX STDERR ===" >&2
    cat "$CODEX_STDERR" >&2
fi

EXIT_CODE=$CODEX_EXIT_CODE
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
        echo "Run 'cat <file> | codex exec --sandbox read-only \"<prompt>\"' directly for detailed error output."
    fi
    echo "Common causes: invalid API key, network issues, rate limiting."
    exit $EXIT_CODE
fi

exit 0
