#!/bin/bash
# kiro-ask.sh - Execute Kiro CLI for AWS research/troubleshooting
# Usage: kiro-ask.sh "prompt"

set -e
set -o pipefail

# Check for empty prompt first (fast fail)
if [ -z "$1" ]; then
    echo "ERROR: No prompt provided." >&2
    echo "Usage: kiro-ask.sh \"your prompt here\"" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check Kiro CLI availability
if [ ! -f "$SCRIPT_DIR/check-kiro.sh" ]; then
    echo "ERROR: check-kiro.sh not found in $SCRIPT_DIR" >&2
    echo "Plugin installation may be corrupted. Try reinstalling." >&2
    exit 1
fi
"$SCRIPT_DIR/check-kiro.sh" || exit 1

RAW_PROMPT="$1"
# Sanitize prompt to prevent prompt injection
# Remove newlines and control characters that could manipulate prompt structure
PROMPT=$(echo "$RAW_PROMPT" | tr -d '\n\r' | sed 's/[`$]//g')

# Check if sanitization left an empty prompt
if [ -z "$PROMPT" ]; then
    echo "ERROR: Prompt is empty after sanitization." >&2
    echo "Note: Special characters (\`, \$) are removed for security." >&2
    echo "Please provide a prompt with actual text content." >&2
    exit 1
fi

echo "Executing Kiro CLI..."
echo "Prompt: $PROMPT"
echo "---"

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

# Execute with timeout (120 seconds) or without if no timeout command available
set +e  # Temporarily disable exit on error to capture exit code
if [ -n "$TIMEOUT_CMD" ]; then
    $TIMEOUT_CMD 120 kiro-cli chat --no-interactive "$PROMPT" 2>&1
else
    kiro-cli chat --no-interactive "$PROMPT" 2>&1
fi

EXIT_CODE=$?
set -e  # Re-enable exit on error

if [ $EXIT_CODE -eq 124 ]; then
    echo "" >&2
    echo "ERROR: Kiro CLI timed out after 120 seconds." >&2
    exit 124
elif [ $EXIT_CODE -ne 0 ]; then
    echo "" >&2
    echo "ERROR: Kiro CLI failed with exit code $EXIT_CODE" >&2
    echo "Run 'kiro-cli chat --no-interactive <prompt>' directly for detailed error output." >&2
    echo "Common causes: invalid credentials, network issues, rate limiting." >&2
    exit $EXIT_CODE
fi

exit 0
