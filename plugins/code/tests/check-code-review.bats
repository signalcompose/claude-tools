#!/usr/bin/env bats
# Tests for check-pr-review-gate.sh (flag-based PR creation gate)

setup() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"

    # Initialize git repo
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Resolve script path relative to test file location
    export SCRIPT_PATH="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/scripts/check-pr-review-gate.sh"

    # Create test file and initial commit
    echo "initial content" > test.txt
    git add test.txt
    git commit -q -m "Initial commit"

    # Calculate repo hash
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    export REVIEW_FLAG="/tmp/claude/review-approved-${REPO_HASH}"

    mkdir -p /tmp/claude
}

teardown() {
    # Clean up flags
    if [[ -n "$REVIEW_FLAG" ]]; then
        rm -f "$REVIEW_FLAG"
    fi

    # Clean up test directory
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        cd /
        rm -rf "$TEST_DIR"
    fi
}

# ============================================================================
# 1. PR Creation Gate (Core Behavior)
# ============================================================================

@test "gh pr create without approval flag is blocked" {
    # No review flag created
    INPUT='{"tool_input":{"command":"gh pr create --title '\''test'\''"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Blocked with exit code 2 and helpful message
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Code Review Required" ]]
    [[ "$output" =~ "/code:review-commit" ]]
}

@test "gh pr create with approval flag is allowed and flag is consumed" {
    # Create approval flag
    touch "$REVIEW_FLAG"
    [ -f "$REVIEW_FLAG" ]

    INPUT='{"tool_input":{"command":"gh pr create --title '\''test'\''"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Allowed and flag consumed
    [ "$status" -eq 0 ]
    [ ! -f "$REVIEW_FLAG" ]
}

@test "gh pr create with --body flag and multiline input is handled" {
    # No review flag
    INPUT='{"tool_input":{"command":"gh pr create --title '\''feat: add feature'\'' --body '\''## Summary\nAdded new feature'\''"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Blocked (no flag)
    [ "$status" -eq 2 ]
}

# ============================================================================
# 2. Command Filtering (Non-PR Commands Bypass)
# ============================================================================

@test "git commit commands are not processed (bypass)" {
    INPUT='{"tool_input":{"command":"git commit -m '\''test'\''"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Allowed (exit 0) — only gh pr create is gated
    [ "$status" -eq 0 ]
}

@test "git status commands are not processed (bypass)" {
    INPUT='{"tool_input":{"command":"git status"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    [ "$status" -eq 0 ]
}

@test "gh pr view commands are not processed (bypass)" {
    INPUT='{"tool_input":{"command":"gh pr view 123"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    [ "$status" -eq 0 ]
}

@test "gh pr merge commands are not processed (bypass)" {
    INPUT='{"tool_input":{"command":"gh pr merge 123 --merge"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    [ "$status" -eq 0 ]
}

# ============================================================================
# 3. Skip-Review Bypass
# ============================================================================

@test "skip-review comment allows gh pr create without flag" {
    # No review flag
    INPUT='{"tool_input":{"command":"gh pr create --title '\''test'\'' # skip-review"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Allowed via bypass
    [ "$status" -eq 0 ]
    [[ "$output" =~ "skip-review" ]]
}

# ============================================================================
# 4. Repository Isolation
# ============================================================================

@test "approval flag is per-repository" {
    # Create two repos
    REPO1=$(mktemp -d)
    REPO2=$(mktemp -d)

    cleanup_repos() {
        cd /
        rm -rf "$REPO1" "$REPO2" 2>/dev/null || true
        rm -f /tmp/claude/review-approved-* 2>/dev/null || true
    }
    trap cleanup_repos EXIT

    # Repo 1
    cd "$REPO1"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "content1" > file1.txt
    git add file1.txt
    git commit -q -m "Init"
    REPO1_ROOT=$(git rev-parse --show-toplevel)
    REPO1_HASH=$(echo "$REPO1_ROOT" | shasum -a 256 | cut -c1-16)
    FLAG1="/tmp/claude/review-approved-${REPO1_HASH}"
    mkdir -p /tmp/claude
    touch "$FLAG1"

    # Repo 2 — no flag
    cd "$REPO2"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "content2" > file2.txt
    git add file2.txt
    git commit -q -m "Init"
    REPO2_ROOT=$(git rev-parse --show-toplevel)
    REPO2_HASH=$(echo "$REPO2_ROOT" | shasum -a 256 | cut -c1-16)
    FLAG2="/tmp/claude/review-approved-${REPO2_HASH}"

    # Verify: Different hashes, only repo1 has flag
    [ "$FLAG1" != "$FLAG2" ]
    [ -f "$FLAG1" ]
    [ ! -f "$FLAG2" ]
}
