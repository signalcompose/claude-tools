#!/bin/bash
# gemini-search.sh - Execute web search using Gemini CLI

set -e

QUERY="$1"

if [ -z "$QUERY" ]; then
    echo "Usage: gemini-search.sh <query>"
    echo "Example: gemini-search.sh 'Claude Code latest features 2026'"
    exit 1
fi

# Check Gemini CLI availability
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    exit 1
elif [ $exit_code -ne 0 ]; then
    echo ""
    echo "ERROR: Gemini CLI failed with exit code $exit_code"
    exit $exit_code
fi

exit 0
