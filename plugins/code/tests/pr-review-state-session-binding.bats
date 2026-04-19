#!/usr/bin/env bats
# Tests for Issue #236: pr-review-team state files must be bound to the
# originating project so stale state from unrelated sessions/projects does
# not block Stop hook in a different session.

setup() {
    # Canonicalize so tests match `pwd -P` output used in production scripts
    # (macOS resolves /var/folders → /private/var/folders on mktemp dirs).
    export TEST_DIR=$(cd "$(mktemp -d)" && pwd -P)
    export STATE_DIR="${TEST_DIR}/claude"
    mkdir -p "$STATE_DIR"

    # Isolate from any existing /tmp/claude/pr-review-*.state files: the
    # production script picks STATE_FILES[0] (glob-sorted first), so a
    # real-session state present at test time would be selected instead of
    # ours. Move them to a per-test backup and restore in teardown.
    mkdir -p /tmp/claude
    export TEST_STATE_BACKUP="${TEST_DIR}/state-backup"
    mkdir -p "$TEST_STATE_BACKUP"
    shopt -s nullglob
    local existing=(/tmp/claude/pr-review-*.state /tmp/claude/pr-review-*.done)
    shopt -u nullglob
    if [ "${#existing[@]}" -gt 0 ]; then
        mv "${existing[@]}" "$TEST_STATE_BACKUP/" 2>/dev/null || true
    fi

    # Resolve script paths relative to this test file.
    PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export INIT_SCRIPT="${PLUGIN_ROOT}/scripts/pr-review-state.sh"
    export VERIFY_SCRIPT="${PLUGIN_ROOT}/skills/pr-review-team/scripts/verify-workflow.sh"

    # Verify scripts exist before running any test.
    [ -x "$INIT_SCRIPT" ] || skip "init script not executable: $INIT_SCRIPT"
    [ -x "$VERIFY_SCRIPT" ] || skip "verify script not executable: $VERIFY_SCRIPT"
}

teardown() {
    # Remove test-created state files before restoring backups.
    rm -f /tmp/claude/pr-review-9999.state /tmp/claude/pr-review-9999.done

    # Restore any pre-existing state files that setup moved aside.
    if [ -d "$TEST_STATE_BACKUP" ]; then
        shopt -s nullglob
        local restored=("$TEST_STATE_BACKUP"/pr-review-*.state "$TEST_STATE_BACKUP"/pr-review-*.done)
        shopt -u nullglob
        if [ "${#restored[@]}" -gt 0 ]; then
            mv "${restored[@]}" /tmp/claude/ 2>/dev/null || true
        fi
    fi
    rm -rf "$TEST_DIR"
}

# Helper: invoke verify-workflow.sh with a minimal hook input JSON.
run_verify() {
    local transcript_path="${1:-}"
    printf '{"stop_hook_active":false,"transcript_path":"%s"}' "$transcript_path" \
        | "$VERIFY_SCRIPT"
}

@test "init records current project_path in state JSON" {
    cd "$TEST_DIR"
    run "$INIT_SCRIPT" init 9999
    [ "$status" -eq 0 ]

    # State file lives under the hard-coded /tmp/claude path.
    [ -f /tmp/claude/pr-review-9999.state ]

    # project_path should equal the cwd where init was invoked.
    project=$(jq -r '.project_path' /tmp/claude/pr-review-9999.state)
    [ "$project" = "$TEST_DIR" ]
}

@test "init records session_id when CLAUDE_SESSION_ID env is set" {
    cd "$TEST_DIR"
    CLAUDE_SESSION_ID="test-session-abc" run "$INIT_SCRIPT" init 9999
    [ "$status" -eq 0 ]

    session=$(jq -r '.session_id' /tmp/claude/pr-review-9999.state)
    [ "$session" = "test-session-abc" ]
}

@test "verify-workflow skips state from a different project" {
    # Create state as if it came from another project.
    mkdir -p /tmp/claude
    jq -n --arg pp "/some/other/project/path" \
        '{pr:"9999", session_id:"", project_path:$pp, phase:"started",
          reviewers_done:false, security_done:false, fixer_done:false,
          rereview_done:false, iterations:0, final_critical:-1, final_important:-1}' \
        > /tmp/claude/pr-review-9999.state

    cd "$TEST_DIR"
    run run_verify ""
    # Exit 0 and no block output — the state belongs to another project.
    [ "$status" -eq 0 ]
    # Output must NOT contain a block decision.
    [[ "$output" != *'"decision":"block"'* ]]
}

@test "verify-workflow skips legacy state without project_path" {
    # Simulate a pre-#236 state file (no project_path field).
    mkdir -p /tmp/claude
    printf '{"pr":"9999","phase":"started","reviewers_done":false,"security_done":false,"fixer_done":false,"rereview_done":false,"iterations":0,"final_critical":-1,"final_important":-1}' \
        > /tmp/claude/pr-review-9999.state

    cd "$TEST_DIR"
    run run_verify ""
    [ "$status" -eq 0 ]
    # Legacy state is safely ignored for Stop purposes (Issue #236).
    [[ "$output" != *'"decision":"block"'* ]]
}

@test "verify-workflow proceeds for matching project_path" {
    # Create a state file belonging to the current project.
    cd "$TEST_DIR"
    mkdir -p /tmp/claude
    jq -n --arg pp "$TEST_DIR" \
        '{pr:"9999", session_id:"", project_path:$pp, phase:"started",
          reviewers_done:false, security_done:false, fixer_done:false,
          rereview_done:false, iterations:0, final_critical:-1, final_important:-1}' \
        > /tmp/claude/pr-review-9999.state

    # Without security_done=true and no transcript evidence, the hook should
    # emit a block. We only confirm the hook engaged (i.e., did not silently
    # skip) — the exact content depends on transcript heuristics.
    run run_verify ""
    [ "$status" -eq 0 ]
    # For a matching-project state in "started" phase, the hook should
    # evaluate the workflow checks and produce a block payload.
    [[ "$output" == *"decision"*"block"* ]]
}
