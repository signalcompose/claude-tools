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
timeout 120 codex exec "$PROMPT" 2>&1

EXIT_CODE=$?

if [ $EXIT_CODE -eq 124 ]; then
    echo ""
    echo "ERROR: Codex CLI timed out after 120 seconds."
    exit 124
fi

exit $EXIT_CODE
