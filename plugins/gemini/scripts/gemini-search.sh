#!/bin/bash
# gemini-search.sh - Execute web search using Gemini CLI

set -e

RAW_QUERY="$1"

if [ -z "$RAW_QUERY" ]; then
    echo "Usage: gemini-search.sh <query>"
    echo "Example: gemini-search.sh 'Claude Code latest features 2026'"
    exit 1
fi

# Sanitize query to prevent prompt injection
# Remove newlines and control characters that could manipulate prompt structure
QUERY=$(echo "$RAW_QUERY" | tr -d '\n\r' | sed 's/[`$]//g')

# Check Gemini CLI availability
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/check-gemini.sh" ]; then
    echo "ERROR: check-gemini.sh not found in $SCRIPT_DIR"
    echo "Plugin installation may be corrupted. Try reinstalling."
    exit 1
fi
"$SCRIPT_DIR/check-gemini.sh" || exit 1

# Execute gemini with web search prompt
# Using gemini-2.5-flash for fast responses
# Timeout after 60 seconds
set +e  # Temporarily disable exit on error to capture exit code
timeout 60 gemini -m gemini-2.5-flash --prompt "WebSearch: $QUERY

Please search the web and provide comprehensive, up-to-date information about the query above. Include:
- Key findings and facts
- Relevant sources (URLs when available)
- Current/latest information
- Summary of the most important points"

exit_code=$?
set -e  # Re-enable exit on error

if [ $exit_code -eq 124 ]; then
    echo ""
    echo "WARNING: Search timed out after 60 seconds."
    echo "Try a more specific query or check your network connection."
    exit 124
elif [ $exit_code -ne 0 ]; then
    echo ""
    echo "ERROR: Gemini CLI failed with exit code $exit_code"
    echo "Run 'gemini --help' directly for troubleshooting."
    echo "Common causes: authentication issues, network problems, rate limiting."
    exit $exit_code
fi

exit 0
