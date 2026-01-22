#!/bin/bash
# check-gemini.sh - Verify Gemini CLI installation and configuration

set -e

# Check if gemini command exists
if ! command -v gemini &> /dev/null; then
    echo "ERROR: Gemini CLI is not installed."
    echo ""
    echo "To install Gemini CLI:"
    echo "  npm install -g @anthropic-ai/gemini"
    echo "  # or"
    echo "  brew install gemini-cli"
    echo ""
    echo "After installation, run 'gemini' to authenticate."
    exit 1
fi

# Check if GOOGLE_API_KEY is set (optional, gemini can use OAuth)
if [ -z "$GOOGLE_API_KEY" ]; then
    # Check if gemini is authenticated via OAuth
    if ! gemini --version &> /dev/null; then
        echo "WARNING: Gemini CLI may not be authenticated."
        echo "Run 'gemini' to complete OAuth authentication."
        exit 1
    fi
fi

echo "OK: Gemini CLI is ready."
exit 0
