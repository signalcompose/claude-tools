#!/bin/bash
# check-codex.sh - Verify Codex CLI installation

set -e
set -o pipefail

if ! command -v codex &> /dev/null; then
    echo "ERROR: Codex CLI is not installed." >&2
    echo "" >&2
    echo "To install Codex CLI:" >&2
    echo "  npm install -g @openai/codex" >&2
    echo "" >&2
    echo "After installation, authenticate using one of:" >&2
    echo "  Option 1: Run 'codex' for OAuth authentication" >&2
    echo "  Option 2: export OPENAI_API_KEY=your-api-key" >&2
    exit 1
fi

AUTH_FILE="$HOME/.codex/auth.json"

# Check authentication: OPENAI_API_KEY or OAuth (auth.json)
if [ -z "$OPENAI_API_KEY" ] && [ ! -f "$AUTH_FILE" ]; then
    echo "ERROR: Codex CLI is not authenticated." >&2
    echo "" >&2
    echo "Option 1: Run 'codex' to complete OAuth authentication" >&2
    echo "Option 2: Set OPENAI_API_KEY environment variable" >&2
    exit 1
fi

# Validate OAuth auth file if being used (check it's not empty)
if [ -z "$OPENAI_API_KEY" ] && [ -f "$AUTH_FILE" ]; then
    if [ ! -s "$AUTH_FILE" ]; then
        echo "ERROR: OAuth authentication file is empty." >&2
        echo "" >&2
        echo "Run 'codex' to complete OAuth authentication" >&2
        exit 1
    fi
fi

# Inform user which auth method is being used (API key takes precedence if both exist)
if [ -n "$OPENAI_API_KEY" ]; then
    echo "OK: Codex CLI is available (using API key)."
elif [ -f "$AUTH_FILE" ]; then
    echo "OK: Codex CLI is available (using OAuth)."
else
    # Defensive: should not reach here if earlier checks passed
    echo "ERROR: Authentication state inconsistent. Please re-run the check." >&2
    exit 1
fi
exit 0
