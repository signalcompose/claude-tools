#!/bin/bash
# gemini-search.sh - Execute web search using Gemini CLI

set -e

QUERY="$1"

if [ -z "$QUERY" ]; then
    echo "Usage: gemini-search.sh <query>"
    echo "Example: gemini-search.sh 'Claude Code latest features 2026'"
    exit 1
fi

# Execute gemini with web search prompt
# Using gemini-2.5-flash for fast responses
# Timeout after 60 seconds
timeout 60 gemini -m gemini-2.5-flash --prompt "WebSearch: $QUERY

Please search the web and provide comprehensive, up-to-date information about the query above. Include:
- Key findings and facts
- Relevant sources (URLs when available)
- Current/latest information
- Summary of the most important points"

exit_code=$?

if [ $exit_code -eq 124 ]; then
    echo ""
    echo "WARNING: Search timed out after 60 seconds."
    exit 1
fi

exit $exit_code
