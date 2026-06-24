#!/bin/bash
# check-gemini.sh - Verify Antigravity CLI (agy) installation and configuration
#
# Background:
#   Google transitioned "Gemini CLI" to "Antigravity CLI" (binary: agy).
#   Gemini CLI stopped serving requests on 2026-06-18 for Google AI Pro/Ultra
#   and free-tier users, so this plugin now uses `agy`.
#   See: https://antigravity.google
#
# Output contract: all human-readable diagnostics go to stderr; stdout is left
# clean so callers (gemini-search.sh) can include the search result verbatim.
# Success/failure is signalled via the exit code.

set -e
set -o pipefail

INSTALL_CMD="curl -fsSL https://antigravity.google/cli/install.sh | bash"

# Resolve agy: PATH first, then the default install location (~/.local/bin).
# The installer adds ~/.local/bin to PATH via shell profiles, but a
# non-interactive shell may not have sourced them yet.
if command -v agy >/dev/null 2>&1; then
    AGY_BIN="$(command -v agy)"
elif [ -x "$HOME/.local/bin/agy" ]; then
    AGY_BIN="$HOME/.local/bin/agy"
else
    AGY_BIN=""
fi

if [ -z "$AGY_BIN" ]; then
    # agy is missing. If the legacy Gemini CLI is present, give a
    # migration-focused message; otherwise a plain install message.
    if command -v gemini >/dev/null 2>&1; then
        echo "ERROR: Antigravity CLI (agy) is not installed, but the legacy Gemini CLI was found." >&2
        echo "" >&2
        echo "Google replaced Gemini CLI with Antigravity CLI. Gemini CLI stopped serving" >&2
        echo "requests on 2026-06-18 (AI Pro/Ultra/free tier). Please migrate to 'agy':" >&2
        echo "" >&2
        echo "  1. Install Antigravity CLI:" >&2
        echo "       $INSTALL_CMD" >&2
        echo "  2. Sign in (one-time, opens a browser):" >&2
        echo "       agy" >&2
        echo "  3. (Optional) Import your old Gemini settings:" >&2
        echo "       agy plugin import gemini" >&2
        echo "" >&2
        echo "After signing in, re-run your search." >&2
        exit 1
    fi

    echo "ERROR: Antigravity CLI (agy) is not installed." >&2
    echo "" >&2
    echo "To install Antigravity CLI:" >&2
    echo "  $INSTALL_CMD" >&2
    echo "" >&2
    echo "Then run 'agy' once to sign in (opens a browser for OAuth)." >&2
    exit 1
fi

echo "OK: Antigravity CLI (agy) is installed at $AGY_BIN." >&2
exit 0
