#!/bin/bash
# gemini-search.sh - Execute web search using Antigravity CLI (agy)
#
# Replaces the legacy Gemini CLI (Google transitioned Gemini CLI -> Antigravity CLI).
#
# Key detail: the prompt is passed as the `--print` argument (NOT via stdin).
# But `agy --print` still reads stdin, and in a non-TTY context (such as Claude
# Code's Bash tool, which runs on a socket) it blocks forever waiting for EOF.
# We redirect stdin from /dev/null so it gets an immediate EOF and prints the
# response to stdout. Verified empirically: the prompt arg is honored and web
# grounding works. A pseudo-TTY wrapper (`script`) is NOT needed and does not
# work in that socket environment.

set -e
set -o pipefail

RAW_QUERY="$1"

if [ -z "$RAW_QUERY" ]; then
    echo "Usage: gemini-search.sh <query>"
    echo "Example: gemini-search.sh 'Claude Code latest features 2026'"
    exit 1
fi

# Sanitize query to prevent prompt injection
# Remove newlines and control characters that could manipulate prompt structure
QUERY=$(echo "$RAW_QUERY" | tr -d '\n\r' | sed 's/[`$]//g')

# Reject a query that sanitizes to empty (e.g. only `$` / backtick characters),
# which the pre-sanitization -z check above would not catch.
if [ -z "$QUERY" ]; then
    echo "ERROR: Query is empty after sanitization (only stripped characters). Provide searchable text." >&2
    exit 1
fi

# Check Antigravity CLI availability
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/check-gemini.sh" ]; then
    echo "ERROR: check-gemini.sh not found in $SCRIPT_DIR"
    echo "Plugin installation may be corrupted. Try reinstalling."
    exit 1
fi
"$SCRIPT_DIR/check-gemini.sh" || exit 1

# Resolve agy binary (PATH first, then the default install location)
if command -v agy >/dev/null 2>&1; then
    AGY_BIN="$(command -v agy)"
elif [ -x "$HOME/.local/bin/agy" ]; then
    AGY_BIN="$HOME/.local/bin/agy"
else
    echo "ERROR: agy binary not found. Run check-gemini.sh for install instructions."
    exit 1
fi

# Optional model override. By default we let agy pick its model (web grounding
# works well with the default). Set AGY_MODEL to a name from `agy models`.
MODEL_ARGS=()
if [ -n "$AGY_MODEL" ]; then
    MODEL_ARGS=(--model "$AGY_MODEL")
fi

# Determine timeout command (gtimeout for macOS with coreutils, timeout for Linux)
if command -v gtimeout &> /dev/null; then
    TIMEOUT_CMD="gtimeout"
elif command -v timeout &> /dev/null; then
    TIMEOUT_CMD="timeout"
else
    TIMEOUT_CMD=""
    echo "WARNING: No timeout command available (gtimeout/timeout not found)." >&2
    echo "Command will run without timeout protection. On macOS: brew install coreutils" >&2
fi

PROMPT="WebSearch: $QUERY

Please search the web and provide comprehensive, up-to-date information about the query above. Include:
- Key findings and facts
- Relevant sources (URLs when available)
- Current/latest information
- Summary of the most important points"

# Execute with timeout (120 seconds) or without if no timeout command available.
# NOTE: `</dev/null` is required (see header) to avoid a hang in non-TTY contexts.
set +e  # Temporarily disable exit on error to capture exit code
if [ -n "$TIMEOUT_CMD" ]; then
    $TIMEOUT_CMD 120 "$AGY_BIN" "${MODEL_ARGS[@]}" --print "$PROMPT" </dev/null
else
    "$AGY_BIN" "${MODEL_ARGS[@]}" --print "$PROMPT" </dev/null
fi

EXIT_CODE=$?
set -e  # Re-enable exit on error

if [ $EXIT_CODE -eq 124 ] && [ -n "$TIMEOUT_CMD" ]; then
    echo ""
    echo "ERROR: Search timed out after 120 seconds."
    echo "Try a more specific query or check your network connection."
    exit 124
elif [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "ERROR: Antigravity CLI (agy) failed with exit code $EXIT_CODE"
    echo "Run 'agy --help' directly for troubleshooting."
    echo "Common causes: not signed in (run 'agy'), network problems, rate limiting."
    exit $EXIT_CODE
fi

exit 0
