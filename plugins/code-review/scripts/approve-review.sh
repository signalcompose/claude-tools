#!/bin/bash
# Approve code review by saving staged changes hash
# This allows the pre-commit hook to verify review was done

# Use project-local .claude directory or /tmp/claude as fallback
if [[ -d ".claude" ]]; then
    REVIEW_FILE=".claude/review-approved"
else
    mkdir -p /tmp/claude
    REVIEW_FILE="/tmp/claude/review-approved"
fi

# Get current staged changes hash
HASH=$(git diff --cached --raw 2>/dev/null | shasum -a 256 | cut -d' ' -f1)

if [[ -z "$HASH" ]]; then
    echo "No staged changes found." >&2
    exit 1
fi

# Save hash to approval file
echo "$HASH" > "$REVIEW_FILE"
echo "Review approved. Hash: ${HASH:0:16}..."
echo "You can now commit the staged changes."
