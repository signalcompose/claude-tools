#!/usr/bin/env bats
# Tests for #257: PostToolUse hook script autopilot-record-invocation.sh.
# Verifies it only records when the invoked Skill matches the current phase,
# and never blocks the tool call (exit 0 on all paths).

setup() {
    local _tmp
    _tmp=$(mktemp -d 2>/dev/null) || skip "mktemp -d failed"
    [ -n "$_tmp" ] && [ -d "$_tmp" ] || skip "mktemp -d invalid"
    export TEST_DIR
    TEST_DIR=$(cd "$_tmp" && pwd -P)
    case "$TEST_DIR" in
        /private/var/folders/*|/var/folders/*|/tmp/*|/private/tmp/*) ;;
        *) skip "TEST_DIR not under expected temp prefix: $TEST_DIR" ;;
    esac
    export CLAUDE_PROJECT_DIR="$TEST_DIR"
    export STATE_SH="${BATS_TEST_DIRNAME}/../scripts/autopilot-state.sh"
    export HOOK_SH="${BATS_TEST_DIRNAME}/../scripts/autopilot-record-invocation.sh"
    bash "$STATE_SH" init "$TEST_DIR/plan.md" >/dev/null
}

teardown() {
    [ -n "${TEST_DIR:-}" ] && rm -rf "$TEST_DIR" || true
}

@test "hook records when Skill matches current phase (sprint + code:sprint-impl)" {
    run bash "$HOOK_SH" <<<'{"tool_name":"Skill","tool_input":{"skill":"code:sprint-impl"},"tool_use_id":"tu_1"}'
    [ "$status" -eq 0 ]
    [ "$(bash "$STATE_SH" get '.invocations | length')" = "1" ]
}

@test "hook ignores non-Skill tool events" {
    run bash "$HOOK_SH" <<<'{"tool_name":"Bash","tool_input":{"command":"ls"}}'
    [ "$status" -eq 0 ]
    [ "$(bash "$STATE_SH" get '.invocations | length')" = "0" ]
}

@test "hook ignores Skill call whose skill does not match current phase" {
    run bash "$HOOK_SH" <<<'{"tool_name":"Skill","tool_input":{"skill":"cvi:speak"},"tool_use_id":"tu_2"}'
    [ "$status" -eq 0 ]
    [ "$(bash "$STATE_SH" get '.invocations | length')" = "0" ]
}

@test "hook is a no-op when no state file is present" {
    bash "$STATE_SH" cleanup >/dev/null
    run bash "$HOOK_SH" <<<'{"tool_name":"Skill","tool_input":{"skill":"code:sprint-impl"},"tool_use_id":"tu_3"}'
    [ "$status" -eq 0 ]
}

@test "hook tolerates malformed payload without failing" {
    run bash "$HOOK_SH" <<<'not-json'
    [ "$status" -eq 0 ]
}

@test "hook is a no-op when phase is complete" {
    AUTOPILOT_STATE_ALLOW_SET_PHASE=1 bash "$STATE_SH" set phase complete >/dev/null
    run bash "$HOOK_SH" <<<'{"tool_name":"Skill","tool_input":{"skill":"code:sprint-impl"}}'
    [ "$status" -eq 0 ]
    [ "$(bash "$STATE_SH" get '.invocations | length')" = "0" ]
}
