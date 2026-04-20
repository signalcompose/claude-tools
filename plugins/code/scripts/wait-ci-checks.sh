#!/bin/bash
set -euo pipefail

# Deterministic CI check polling for PR review workflow
# Returns structured STATUS line: PASS / FAIL / TIMEOUT / ERROR

PR_NUMBER="${1:?Usage: wait-ci-checks.sh <PR_NUMBER>}"
MAX_ATTEMPTS=3
WAIT_SECONDS=30

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
    echo "=== CI Check Attempt $attempt/$MAX_ATTEMPTS ==="

    CHECKS=$(gh pr checks "$PR_NUMBER" 2>/dev/null) || {
        echo "STATUS: ERROR (gh command failed)"
        echo "ACTION: Check network, gh auth status, and PR number — sandbox bypass is not the fix"
        exit 0
    }

    echo "$CHECKS"
    echo ""

    if echo "$CHECKS" | grep -qiE "pending|queued|in_progress"; then
        if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
            echo "PENDING checks found. Waiting ${WAIT_SECONDS}s..."
            sleep "$WAIT_SECONDS"
            continue
        else
            echo ""
            echo "STATUS: TIMEOUT"
            echo "ACTION: Manual verification recommended for pending checks"
            exit 0
        fi
    fi

    if echo "$CHECKS" | grep -qi "fail"; then
        echo ""
        echo "STATUS: FAIL"
        exit 0
    fi

    echo ""
    echo "STATUS: PASS"
    exit 0
done
