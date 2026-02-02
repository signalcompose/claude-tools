#!/bin/bash
# approve-review.sh - Save approval hash for staged changes
# Called by SKILL.md after code review passes

set -e

# Determine approval file location
if [[ -d ".claude" ]]; then
    if [[ ! -w ".claude" ]]; then
        echo "Error: .claude directory exists but is not writable" >&2
        exit 1
    fi
    REVIEW_FILE=".claude/review-approved"
else
    if ! mkdir -p /tmp/claude; then
        echo "Failed to create /tmp/claude directory" >&2
        exit 1
    fi
    REVIEW_FILE="/tmp/claude/review-approved"
fi

# Get staged changes hash
GIT_OUTPUT=$(git diff --cached --raw 2>&1)
GIT_STATUS=$?
if [[ $GIT_STATUS -ne 0 ]]; then
    echo "Git error: $GIT_OUTPUT" >&2
    exit 1
fi

# Calculate hash
HASH_OUTPUT=$(echo "$GIT_OUTPUT" | shasum -a 256 2>&1)
HASH_STATUS=$?
if [[ $HASH_STATUS -ne 0 ]]; then
    echo "Hash calculation failed: $HASH_OUTPUT" >&2
    exit 1
fi
HASH=$(echo "$HASH_OUTPUT" | cut -d' ' -f1)

# Validate hash (reject empty or no-changes hash)
EMPTY_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
if [[ -z "$HASH" || "$HASH" == "$EMPTY_HASH" ]]; then
    echo "No staged changes found." >&2
    exit 1
fi

# Save approved hash
if ! echo "$HASH" > "$REVIEW_FILE"; then
    echo "Failed to save approval hash to $REVIEW_FILE" >&2
    exit 1
fi

echo "Review approved. Hash: ${HASH:0:16}..."
echo "You can now commit the staged changes."
