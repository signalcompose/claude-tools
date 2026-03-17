#!/usr/bin/env bash
# set-review-flag.sh — Create review approval flag for PR creation gate
#
# Uses the same hash algorithm as check-pr-review-gate.sh:
#   REPO_HASH = echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16
#
# IMPORTANT: Must use `echo` (not `printf '%s'`) to match check-pr-review-gate.sh.
# echo appends a trailing newline, which changes the hash.
#
# The flag is consumed (deleted) by check-pr-review-gate.sh when
# gh pr create is executed.

set -euo pipefail

CLAUDE_TMP="/tmp/claude"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "unknown")
REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
FLAG_FILE="${CLAUDE_TMP}/review-approved-${REPO_HASH}"

mkdir -p "$CLAUDE_TMP" || {
    echo "Error: Cannot create directory ${CLAUDE_TMP}" >&2
    exit 1
}
touch "$FLAG_FILE" || {
    echo "Error: Cannot create review flag file: ${FLAG_FILE}" >&2
    exit 1
}
echo "Review flag set: ${FLAG_FILE}"
