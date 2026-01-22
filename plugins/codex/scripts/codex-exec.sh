#!/bin/bash
# codex-exec.sh - Execute Codex CLI for research/queries
# Usage: codex-exec.sh "prompt"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check Codex availability
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

# Execute with timeout (120 seconds)
set +e  # Temporarily disable exit on error to capture exit code
timeout 120 codex exec "$PROMPT" 2>&1

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
