#!/usr/bin/env bats
# Tests for check-gitignore-security.sh REF_FILE path resolution and behavior

PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPT="${PLUGIN_ROOT}/scripts/check-gitignore-security.sh"

# ---------------------------------------------------------------------------
# Isolation helpers
# ---------------------------------------------------------------------------

setup() {
    local _tmp
    _tmp=$(mktemp -d 2>/dev/null) || { skip "mktemp -d failed (sandbox or quota?)"; }
    [ -n "$_tmp" ] && [ -d "$_tmp" ] || { skip "mktemp -d produced invalid path: [$_tmp]"; }
    export TEST_DIR
    TEST_DIR=$(cd "$_tmp" && pwd -P)
    case "$TEST_DIR" in
        /private/var/folders/*|/var/folders/*|/tmp/*|/private/tmp/*) ;;
        *) skip "TEST_DIR not under an expected temp prefix: $TEST_DIR" ;;
    esac
}

teardown() {
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Helper: create a minimal git repo with an (optionally pre-populated) .gitignore
_make_git_repo() {
    local dir="$1"
    local gitignore_content="${2:-}"
    git init -q "$dir"
    printf '%s' "$gitignore_content" > "${dir}/.gitignore"
}

# ---------------------------------------------------------------------------
# Path-arithmetic tests (cheap contract for reference file shape)
# ---------------------------------------------------------------------------

@test "gitignore-security-patterns.md reference file exists" {
    local ref_file="${PLUGIN_ROOT}/references/gitignore-security-patterns.md"
    [ -f "$ref_file" ]
}

@test "check-gitignore-security.sh REF_FILE resolves to an existing path" {
    local script_dir="${PLUGIN_ROOT}/scripts"
    local ref_file="${script_dir}/../references/gitignore-security-patterns.md"
    [ -f "$ref_file" ]
}

@test "gitignore-security-patterns.md contains the code:security-patterns marker" {
    local ref_file="${PLUGIN_ROOT}/references/gitignore-security-patterns.md"
    grep -q "code:security-patterns:" "$ref_file"
}

# ---------------------------------------------------------------------------
# Behavioral tests
# ---------------------------------------------------------------------------

@test "non-git-commit command is ignored (exit 0, no stderr)" {
    local output stderr_output
    stderr_output=$(printf '{"tool_input":{"command":"ls"}}' | bash "$SCRIPT" 2>&1 >/dev/null)
    local exit_code=$?
    [ "$exit_code" -eq 0 ]
    [ -z "$stderr_output" ]
}

@test "missing marker in .gitignore blocks (exit 2, stderr BLOCKED)" {
    local repo="${TEST_DIR}/repo"
    _make_git_repo "$repo" ""
    local stderr_file="${TEST_DIR}/stderr.txt"
    run bash -c "cd '$repo' && printf '{\"tool_input\":{\"command\":\"git commit -m foo\"}}' | bash '$SCRIPT' 2>'$stderr_file' >/dev/null"
    [ "$status" -eq 2 ]
    grep -q "BLOCKED" "$stderr_file"
}

@test "valid marker in .gitignore passes (exit 0)" {
    local repo="${TEST_DIR}/repo"
    local ref_file="${PLUGIN_ROOT}/references/gitignore-security-patterns.md"
    local real_hash
    real_hash=$(grep -o 'code:security-patterns:[a-f0-9]*' "$ref_file" | head -1 | cut -d: -f3)
    [ -n "$real_hash" ] || { echo "ref file hash not found" >&2; return 1; }
    _make_git_repo "$repo" "# code:security-patterns:${real_hash}"
    run bash -c "cd '$repo' && printf '{\"tool_input\":{\"command\":\"git commit -m foo\"}}' | bash '$SCRIPT'"
    [ "$status" -eq 0 ]
    # Confirm we went through the clean-pass branch, not an advisory path
    [[ "$output" != *"BLOCKED"* ]]
    [[ "$output" != *"not in a git repo"* ]]
    [[ "$output" != *"reference file missing"* ]]
    [[ "$output" != *"outdated"* ]]   # clean-pass, not the warn-only path
}

@test "hash-mismatch in .gitignore warns and exits 0 (outdated patterns)" {
    local repo="${TEST_DIR}/repo"
    _make_git_repo "$repo" "# code:security-patterns:deadbeef"
    run bash -c "cd '$repo' && printf '{\"tool_input\":{\"command\":\"git commit -m foo\"}}' | bash '$SCRIPT'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"outdated"* ]]
    [[ "$output" != *"BLOCKED"* ]]
}

@test "not in git repo warns and exits 0" {
    local empty_dir="${TEST_DIR}/notarepo"
    mkdir -p "$empty_dir"
    local stderr_output
    stderr_output=$(cd "$empty_dir" && printf '{"tool_input":{"command":"git commit -m foo"}}' | bash "$SCRIPT" 2>&1 >/dev/null)
    local exit_code=$?
    [ "$exit_code" -eq 0 ]
    [[ "$stderr_output" == *"not in a git repo"* ]]
}

@test "REF_FILE missing blocks commit (exit 2, stderr mentions missing reference)" {
    # Create a copy of the script in a location where ../references/ does not exist
    local fake_scripts_dir="${TEST_DIR}/fake-plugin/scripts"
    mkdir -p "$fake_scripts_dir"
    cp "$SCRIPT" "${fake_scripts_dir}/check-gitignore-security.sh"

    local repo="${TEST_DIR}/repo"
    _make_git_repo "$repo" "# code:security-patterns:abc123"

    local fake_script="${fake_scripts_dir}/check-gitignore-security.sh"
    local stderr_file="${TEST_DIR}/stderr2.txt"
    run bash -c "cd '$repo' && printf '{\"tool_input\":{\"command\":\"git commit -m foo\"}}' | bash '$fake_script' 2>'$stderr_file' >/dev/null"
    [ "$status" -eq 2 ]
    grep -q "BLOCKED" "$stderr_file"
}
