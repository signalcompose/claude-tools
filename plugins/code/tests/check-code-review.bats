#!/usr/bin/env bats
# Tests for check-pr-review-gate.sh (flag-based PR creation gate)

setup() {
    # Create temporary test directory. Fail loudly if mktemp is denied
    # (e.g. by a sandbox policy) — otherwise `cd ""` silently stays in the
    # caller's cwd and subsequent `git init`/`git add`/`git commit` would
    # operate on the real checkout. See Issue #239.
    TEST_DIR=$(mktemp -d 2>/dev/null) || { skip "mktemp -d failed (sandbox or quota?)"; }
    [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ] || { skip "mktemp -d produced invalid path: [$TEST_DIR]"; }
    case "$TEST_DIR" in
        /private/var/folders/*|/var/folders/*|/tmp/*|/private/tmp/*) ;;
        *) skip "TEST_DIR not under an expected temp prefix: $TEST_DIR" ;;
    esac
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

    # Clean up test directory. Only rm -rf when TEST_DIR is under a
    # recognised temp prefix — prevents a regression from turning teardown
    # into a repo-nuke (Issue #239).
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        cd /
        case "$TEST_DIR" in
            /private/var/folders/*|/var/folders/*|/tmp/*|/private/tmp/*)
                rm -rf "$TEST_DIR" ;;
            *)
                echo "teardown: refusing to rm -rf unsafe TEST_DIR: $TEST_DIR" >&2 ;;
        esac
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
    # Create two repos. Fail the test loudly if mktemp is denied — `cd ""`
    # would otherwise leave us in the real checkout for the subsequent
    # git init / commit, and cleanup `rm -rf ""` would error rather than
    # remove the real repo, but the intermediate `git init` pollution would
    # still be real. See Issue #239.
    REPO1=$(mktemp -d 2>/dev/null) || { skip "mktemp -d failed (sandbox?)"; }
    REPO2=$(mktemp -d 2>/dev/null) || { skip "mktemp -d failed (sandbox?)"; }
    for _r in "$REPO1" "$REPO2"; do
        [ -n "$_r" ] && [ -d "$_r" ] || { skip "mktemp produced invalid path: [$_r]"; }
        case "$_r" in
            /private/var/folders/*|/var/folders/*|/tmp/*|/private/tmp/*) ;;
            *) skip "mktemp path outside expected temp prefix: $_r" ;;
        esac
    done

    cleanup_repos() {
        cd /
        for _r in "$REPO1" "$REPO2"; do
            case "$_r" in
                /private/var/folders/*|/var/folders/*|/tmp/*|/private/tmp/*)
                    rm -rf "$_r" 2>/dev/null || true ;;
            esac
        done
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
