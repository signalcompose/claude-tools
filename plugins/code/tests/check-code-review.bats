#!/usr/bin/env bats
# Tests for check-code-review.sh (flag-based workflow)

setup() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"

    # Initialize git repo
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Export test variables
    export SCRIPT_PATH="/Users/yamato/Src/proj_claude-tools/claude-tools/plugins/code/scripts/check-code-review.sh"

    # Create test file
    echo "initial content" > test.txt
    git add test.txt
    git commit -q -m "Initial commit"
}

teardown() {
    # Clean up markers
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        REPO_ROOT=$(cd "$TEST_DIR" && git rev-parse --show-toplevel 2>/dev/null || echo "$TEST_DIR")
        REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
        rm -f "/tmp/claude/review-approved-${REPO_HASH}"
        rm -f "/tmp/claude/review-in-progress-${REPO_HASH}"
        rm -f "/tmp/claude/fixer-commit-${REPO_HASH}"
        rm -f "/tmp/claude/fixer-commit-${REPO_HASH}.lock"
    fi

    # Clean up test directory
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        cd /
        rm -rf "$TEST_DIR"
    fi
}

# ============================================================================
# 1. Review-In-Progress Marker Lifecycle (Criticality 10/10)
# ============================================================================

@test "review-in-progress marker blocks manual commits" {
    # Setup: Create review marker
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"

    mkdir -p /tmp/claude
    touch "$REVIEW_MARKER"
    echo "Review started at $(date)" > "$REVIEW_MARKER"

    # Modify file
    echo "modified" > test.txt

    # Prepare JSON input (simulating PreToolUse hook)
    INPUT=$(cat <<'EOF'
{
  "tool_input": {
    "command": "git commit -m 'test commit'"
  }
}
EOF
)

    # Run hook with INPUT
    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Blocked with exit code 2
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Review In Progress - Manual Commits Blocked" ]]
}

@test "stale review-in-progress marker (>1 hour) is removed" {
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"

    mkdir -p /tmp/claude
    touch "$REVIEW_MARKER"

    # Set marker timestamp to 2 hours ago
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        touch -t $(date -v-2H +%Y%m%d%H%M.%S) "$REVIEW_MARKER"
    else
        # Linux
        touch -d "2 hours ago" "$REVIEW_MARKER"
    fi

    # Modify file
    echo "modified" > test.txt

    # Prepare JSON input
    INPUT='{"tool_input":{"command":"git commit -m '\''test'\''}}'

    # Run hook
    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Marker removed, commit blocked (no approval flag exists)
    [ ! -f "$REVIEW_MARKER" ]
    [ "$status" -eq 2 ]
    [[ "$output" =~ "stale" ]]
}

@test "fresh review-in-progress marker (<1 hour) is not removed" {
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"

    mkdir -p /tmp/claude
    touch "$REVIEW_MARKER"
    echo "Review started at $(date)" > "$REVIEW_MARKER"

    # Modify file
    echo "modified" > test.txt

    # Prepare JSON input
    INPUT='{"tool_input":{"command":"git commit -m '\''test'\''}}'

    # Run hook
    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Marker still exists, commit blocked
    [ -f "$REVIEW_MARKER" ]
    [ "$status" -eq 2 ]
}

# ============================================================================
# 2. Fixer-Commit Atomic Detection (Criticality 9/10)
# ============================================================================

@test "fixer-commit marker allows commit during review" {
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"
    FIXER_COMMIT_MARKER="/tmp/claude/fixer-commit-${REPO_HASH}"

    mkdir -p /tmp/claude
    touch "$REVIEW_MARKER"
    touch "$FIXER_COMMIT_MARKER"

    # Modify file
    echo "fixed" > test.txt

    # Prepare JSON input
    INPUT='{"tool_input":{"command":"git commit -m '\''fix: resolve issue'\''}}'

    # Run hook
    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Commit allowed, marker NOT removed (PreToolUse context)
    [ "$status" -eq 0 ]
    [[ "$output" =~ "allowing fixer agent commit" ]]
    [ -f "$FIXER_COMMIT_MARKER" ]  # Not removed in PreToolUse hook
}

@test "flock lock file is cleaned up after fixer commit check" {
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"
    FIXER_COMMIT_MARKER="/tmp/claude/fixer-commit-${REPO_HASH}"
    LOCK_FILE="${FIXER_COMMIT_MARKER}.lock"

    mkdir -p /tmp/claude
    touch "$REVIEW_MARKER"
    touch "$FIXER_COMMIT_MARKER"

    # Modify file
    echo "fixed" > test.txt

    # Prepare JSON input
    INPUT='{"tool_input":{"command":"git commit -m '\''fix'\''}}'

    # Run hook
    bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Lock file cleaned up
    [ ! -f "$LOCK_FILE" ]
}

@test "manual commit during review without fixer marker is blocked" {
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"

    mkdir -p /tmp/claude
    touch "$REVIEW_MARKER"
    # No fixer-commit marker

    # Modify file
    echo "manual change" > test.txt

    # Prepare JSON input
    INPUT='{"tool_input":{"command":"git commit -m '\''manual'\''}}'

    # Run hook
    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Blocked with exit code 2
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Manual Commits Blocked" ]]
}

# ============================================================================
# 3. Flag-Based Approval Flow (Criticality 8/10)
# ============================================================================

@test "review-approved flag allows commit and is removed" {
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    REVIEW_FLAG="/tmp/claude/review-approved-${REPO_HASH}"

    mkdir -p /tmp/claude
    touch "$REVIEW_FLAG"

    # Modify file
    echo "approved change" > test.txt

    # Prepare JSON input
    INPUT='{"tool_input":{"command":"git commit -m '\''approved'\''}}'

    # Run hook
    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Commit allowed, flag removed
    [ "$status" -eq 0 ]
    [ ! -f "$REVIEW_FLAG" ]
}

@test "review-approved flag is per-repository" {
    # Create two repos
    REPO1=$(mktemp -d)
    REPO2=$(mktemp -d)

    # Setup cleanup
    cleanup_repos() {
        cd /
        rm -rf "$REPO1" "$REPO2" 2>/dev/null || true
        rm -f "/tmp/claude/review-approved-"* 2>/dev/null || true
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

    # Repo 2
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
    # No flag for repo2

    # Verify: Flags are different paths
    [ "$FLAG1" != "$FLAG2" ]
    [ -f "$FLAG1" ]
    [ ! -f "$FLAG2" ]
}

@test "no approval flag blocks commit with helpful message" {
    # No review-approved flag created

    # Modify file
    echo "unapproved change" > test.txt

    # Prepare JSON input
    INPUT='{"tool_input":{"command":"git commit -m '\''unapproved'\''}}'

    # Run hook
    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Blocked with helpful message
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Code Review Required" ]]
    [[ "$output" =~ "/code:review-commit" ]]
}

# ============================================================================
# 4. Command Filtering
# ============================================================================

@test "gh commands are skipped (not processed)" {
    INPUT='{"tool_input":{"command":"gh pr create --title '\''test'\''"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Allowed (exit 0)
    [ "$status" -eq 0 ]
}

@test "non-git-commit commands are skipped" {
    INPUT='{"tool_input":{"command":"git status"}}'

    run bash -c "echo '$INPUT' | bash $SCRIPT_PATH"

    # Verify: Allowed (exit 0)
    [ "$status" -eq 0 ]
}
