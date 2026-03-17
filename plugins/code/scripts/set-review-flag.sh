#!/usr/bin/env bash
# set-review-flag.sh — Create review approval flag for PR creation gate
#
# Uses the same hash algorithm as check-pr-review-gate.sh:
#   REPO_HASH = sha256(REPO_ROOT) | first 16 chars
#
# The flag is consumed (deleted) by check-pr-review-gate.sh when
# gh pr create is executed.

set -euo pipefail

CLAUDE_TMP="/tmp/claude"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "unknown")
REPO_HASH=$(printf '%s' "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
FLAG_FILE="${CLAUDE_TMP}/review-approved-${REPO_HASH}"

mkdir -p "$CLAUDE_TMP"
touch "$FLAG_FILE"
echo "Review flag set: ${FLAG_FILE}"
