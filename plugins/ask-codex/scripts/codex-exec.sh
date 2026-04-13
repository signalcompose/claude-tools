#!/bin/bash
# codex-exec.sh - Execute Codex CLI for research/queries
# Usage: codex-exec.sh "prompt"

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
    echo "ERROR: No prompt provided."
    echo "Usage: codex-exec.sh \"your prompt here\""
    exit 1
fi

PROMPT="$1"

echo "Executing Codex CLI..."
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
    $TIMEOUT_CMD 120 codex exec "$PROMPT" 2>&1
else
    codex exec "$PROMPT" 2>&1
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
    echo "Run 'codex exec <prompt>' directly for detailed error output."
    echo "Common causes: invalid API key, network issues, rate limiting."
    exit $EXIT_CODE
fi

exit 0
