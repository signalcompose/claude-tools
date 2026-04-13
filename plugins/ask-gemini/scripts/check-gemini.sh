#!/bin/bash
# check-gemini.sh - Verify Gemini CLI installation and configuration

set -e
set -o pipefail

# Check if gemini command exists
if ! command -v gemini &> /dev/null; then
    echo "ERROR: Gemini CLI is not installed."
    echo ""
    echo "To install Gemini CLI:"
    echo "  npm install -g @google/gemini-cli"
    echo "  # or use npx directly"
    echo "  npx @google/gemini-cli"
    echo ""
    echo "After installation, run 'gemini' to authenticate."
    exit 1
fi

# Note: GEMINI_API_KEY is the correct variable for Gemini CLI (not GOOGLE_API_KEY)
# GOOGLE_API_KEY works with Gemini API libraries but NOT with Gemini CLI (known bug)
# See: https://github.com/google-gemini/gemini-cli/issues/7557
if [ -z "$GEMINI_API_KEY" ]; then
    echo "INFO: GEMINI_API_KEY not set. Gemini CLI will use OAuth authentication."
    echo "If not authenticated, run 'gemini' to complete OAuth setup."
fi

echo "OK: Gemini CLI is installed."
exit 0
