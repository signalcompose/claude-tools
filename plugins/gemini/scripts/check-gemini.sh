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

# Note: GOOGLE_API_KEY is optional - Gemini CLI can use OAuth authentication
# We cannot reliably verify OAuth status without making an API call
# Authentication errors will be reported at search time if OAuth is not configured
if [ -z "$GOOGLE_API_KEY" ]; then
    echo "INFO: GOOGLE_API_KEY not set. Gemini CLI will use OAuth authentication."
    echo "If not authenticated, run 'gemini' to complete OAuth setup."
fi

echo "OK: Gemini CLI is installed."
exit 0
