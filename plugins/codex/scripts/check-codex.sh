#!/bin/bash
# check-codex.sh - Verify Codex CLI installation

set -e
set -o pipefail

if ! command -v codex &> /dev/null; then
    echo "ERROR: Codex CLI is not installed."
    echo ""
    echo "To install Codex CLI:"
    echo "  npm install -g @openai/codex"
    echo ""
    echo "After installation, ensure OPENAI_API_KEY is set:"
    echo "  export OPENAI_API_KEY=your-api-key"
    exit 1
fi

# Check authentication: OPENAI_API_KEY or OAuth (auth.json)
if [ -z "$OPENAI_API_KEY" ] && [ ! -f "$HOME/.codex/auth.json" ]; then
    echo "ERROR: Codex CLI is not authenticated."
    echo ""
    echo "Option 1: Run 'codex' to complete OAuth authentication"
    echo "Option 2: Set OPENAI_API_KEY environment variable"
    exit 1
fi

# Inform user which auth method is being used
if [ -n "$OPENAI_API_KEY" ]; then
    echo "OK: Codex CLI is available (using API key)."
elif [ -f "$HOME/.codex/auth.json" ]; then
    echo "OK: Codex CLI is available (using OAuth)."
fi
exit 0
