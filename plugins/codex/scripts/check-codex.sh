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

# Verify API key is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "ERROR: OPENAI_API_KEY environment variable is not set."
    echo "Codex CLI requires this to function."
    echo ""
    echo "Set your API key:"
    echo "  export OPENAI_API_KEY=your-api-key"
    exit 1
fi

echo "Codex CLI is available."
exit 0
