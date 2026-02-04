#!/bin/bash
# approve-review.sh - Save approval hash for staged changes
# Called by SKILL.md after code review passes

set -e

# Self-resolve plugin root (supports multiple invocation contexts)
resolve_plugin_root() {
    # Priority 1: Environment variable (set by hooks/code blocks)
    if [[ -n "$CLAUDE_PLUGIN_ROOT" ]]; then
        echo "$CLAUDE_PLUGIN_ROOT"
        return 0
    fi

    # Priority 2: Derive from script location (BASH_SOURCE)
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local plugin_root="${script_dir%/scripts}"
    if [[ -d "$plugin_root/.claude-plugin" ]]; then
        echo "$plugin_root"
        return 0
    fi

    # Priority 3: Search plugin cache
    local cache_base="$HOME/.claude/plugins/cache/claude-tools/code"
    if [[ -d "$cache_base" ]]; then
        local latest_version
        latest_version=$(ls -1t "$cache_base" 2>/dev/null | head -1)
        if [[ -n "$latest_version" && -d "$cache_base/$latest_version" ]]; then
            echo "$cache_base/$latest_version"
            return 0
        fi
    fi

    return 1
}

PLUGIN_ROOT=$(resolve_plugin_root) || {
    echo "Warning: Cannot determine plugin root (continuing anyway)" >&2
}

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
