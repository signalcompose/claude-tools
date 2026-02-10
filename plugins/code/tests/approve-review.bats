#!/usr/bin/env bats
# Unit tests for approve-review.sh (flag-based workflow)

setup() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"

    # Initialize git repo
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Export test variables
    export CLAUDE_PLUGIN_ROOT="${BATS_TEST_DIRNAME}/.."
    export SCRIPT_PATH="${CLAUDE_PLUGIN_ROOT}/scripts/approve-review.sh"

    # Create test file
    echo "initial content" > test.txt
    git add test.txt
    git commit -q -m "Initial commit"
}

teardown() {
    # Clean up approval file (before removing test directory)
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        REPO_ROOT=$(cd "$TEST_DIR" && git rev-parse --show-toplevel 2>/dev/null || echo "$TEST_DIR")
        REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
        rm -f "/tmp/claude/review-approved-${REPO_HASH}"
    fi

    # Clean up test directory
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        cd /
        rm -rf "$TEST_DIR"
    fi
}

@test "approve-review.sh exists and is executable" {
    [ -x "$SCRIPT_PATH" ]
}

@test "fails when no working directory changes exist" {
    # No changes in working directory
    run bash "$SCRIPT_PATH"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "No changes found" ]] || [[ "$output" =~ "Git error" ]]
}

@test "succeeds with working directory changes" {
    # Modify file (working directory change, not staged)
    echo "modified content" > test.txt

    run bash "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Review approved" ]]
}

@test "creates approval flag file" {
    # Modify file
    echo "test modification" > test.txt

    # Run script
    bash "$SCRIPT_PATH"

    # Check approval flag file exists
    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    REVIEW_FILE="/tmp/claude/review-approved-${REPO_HASH}"

    [ -f "$REVIEW_FILE" ]
}

@test "approval flag file is per-repository (uses repo hash)" {
    # Create two test repos
    REPO1=$(mktemp -d)
    REPO2=$(mktemp -d)

    # Set up cleanup trap to ensure removal even on test failure
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
    echo "modified1" > file1.txt
    bash "$SCRIPT_PATH"
    REPO1_ROOT=$(git rev-parse --show-toplevel)
    REPO1_HASH=$(echo "$REPO1_ROOT" | shasum -a 256 | cut -c1-16)
    FILE1="/tmp/claude/review-approved-${REPO1_HASH}"

    # Repo 2
    cd "$REPO2"
    git init -q
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "content2" > file2.txt
    git add file2.txt
    git commit -q -m "Init"
    echo "modified2" > file2.txt
    bash "$SCRIPT_PATH"
    REPO2_ROOT=$(git rev-parse --show-toplevel)
    REPO2_HASH=$(echo "$REPO2_ROOT" | shasum -a 256 | cut -c1-16)
    FILE2="/tmp/claude/review-approved-${REPO2_HASH}"

    # Approval files should be different
    [ "$FILE1" != "$FILE2" ]
    [ -f "$FILE1" ]
    [ -f "$FILE2" ]
}

@test "handles unstaged new files" {
    # Create new file (not staged)
    # Untracked files are not included in git diff HEAD, so this should fail
    echo "new file content" > newfile.txt

    run bash "$SCRIPT_PATH"
    # Untracked files don't appear in git diff HEAD, so script will fail with "No changes found"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No changes found" ]] || [[ "$output" =~ "Git error" ]]
}

@test "handles unstaged deleted files" {
    # Delete tracked file (not staged)
    rm test.txt

    run bash "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Review approved" ]]
}

@test "fails outside git repository" {
    # Move to non-git directory
    NON_GIT_DIR=$(mktemp -d)
    cd "$NON_GIT_DIR"

    run bash "$SCRIPT_PATH"
    [ "$status" -eq 1 ]

    rm -rf "$NON_GIT_DIR"
}

@test "overwrites existing approval flag on re-approval" {
    # First modification and approval
    echo "first change" > test.txt
    bash "$SCRIPT_PATH"

    REPO_ROOT=$(git rev-parse --show-toplevel)
    REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
    REVIEW_FILE="/tmp/claude/review-approved-${REPO_HASH}"

    [ -f "$REVIEW_FILE" ]
    FIRST_TIMESTAMP=$(stat -f %m "$REVIEW_FILE" 2>/dev/null || stat -c %Y "$REVIEW_FILE" 2>/dev/null)

    # Wait to ensure different timestamp
    sleep 1

    # Second modification and approval
    echo "second change" > test.txt
    bash "$SCRIPT_PATH"

    [ -f "$REVIEW_FILE" ]
    SECOND_TIMESTAMP=$(stat -f %m "$REVIEW_FILE" 2>/dev/null || stat -c %Y "$REVIEW_FILE" 2>/dev/null)

    # File should have been updated (newer timestamp)
    [ "$SECOND_TIMESTAMP" -gt "$FIRST_TIMESTAMP" ]
}
