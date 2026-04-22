#!/usr/bin/env bats
# Tests for #257: autopilot-state.sh `advance` must refuse when the previous
# phase left neither a Skill-tool invocation record nor a skip declaration.
# Covers both the phase-evidence gate (#253) and the post-pr-review
# convergence gate (#254).

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
    bash "$STATE_SH" init "$TEST_DIR/plan.md" >/dev/null
}

teardown() {
    [ -n "${TEST_DIR:-}" ] && rm -rf "$TEST_DIR" || true
}

@test "advance refuses when no invocation and no skip-declare" {
    run bash "$STATE_SH" advance
    [ "$status" -ne 0 ]
    [[ "$output" == *"no evidence for phase 'sprint'"* ]]
}

@test "advance succeeds after record-invocation" {
    bash "$STATE_SH" record-invocation sprint code:sprint-impl tu_abc >/dev/null
    run bash "$STATE_SH" advance
    [ "$status" -eq 0 ]
    [[ "$output" == *"sprint -> audit"* ]]
}

@test "advance succeeds after skip-declare with sufficient reason" {
    bash "$STATE_SH" skip-declare sprint "nothing to implement this run" >/dev/null
    run bash "$STATE_SH" advance
    [ "$status" -eq 0 ]
}

# Canonical skill name for each phase — kept in sync with
# expected_skill_for_phase() in autopilot-state.sh.
phase_skill() {
    case "$1" in
        sprint)          echo "code:sprint-impl" ;;
        audit)           echo "code:audit-compliance" ;;
        simplify)        echo "simplify" ;;
        ship)            echo "code:shipping-pr" ;;
        post-pr-review)  echo "code:pr-review-team" ;;
        retrospective)   echo "code:retrospective" ;;
    esac
}

@test "advance refuses when recorded skill does not match expected" {
    bash "$STATE_SH" record-invocation sprint wrong-skill-name >/dev/null
    run bash "$STATE_SH" advance
    [ "$status" -ne 0 ]
    [[ "$output" == *"no evidence for phase 'sprint'"* ]]
}

@test "advance refuses post-pr-review->retrospective without convergence" {
    # Walk to post-pr-review using canonical skill names at each phase.
    for p in sprint audit simplify ship post-pr-review; do
        bash "$STATE_SH" record-invocation "$p" "$(phase_skill "$p")" >/dev/null
        bash "$STATE_SH" advance >/dev/null || true
    done
    # Phase should now be post-pr-review, about to advance to retrospective.
    bash "$STATE_SH" get .phase | grep -q "post-pr-review"

    run bash "$STATE_SH" advance
    [ "$status" -ne 0 ]
    [[ "$output" == *"review_iterations"* ]]
    [[ "$output" == *"pr-review-team contract unmet"* ]]
}

@test "advance succeeds to retrospective once contract met" {
    for p in sprint audit simplify ship post-pr-review; do
        bash "$STATE_SH" record-invocation "$p" "$(phase_skill "$p")" >/dev/null
        bash "$STATE_SH" advance >/dev/null || true
    done
    bash "$STATE_SH" record-review-iteration >/dev/null
    bash "$STATE_SH" record-review-iteration >/dev/null
    bash "$STATE_SH" metric critical 0 >/dev/null
    bash "$STATE_SH" metric important 0 >/dev/null

    run bash "$STATE_SH" advance
    [ "$status" -eq 0 ]
    [ "$(bash "$STATE_SH" get .phase)" = "retrospective" ]
}

@test "AUTOPILOT_STATE_ALLOW_UNVERIFIED bypasses the gate" {
    AUTOPILOT_STATE_ALLOW_UNVERIFIED=1 run bash "$STATE_SH" advance
    [ "$status" -eq 0 ]
}

@test "record-invocation appends to invocations[]" {
    bash "$STATE_SH" record-invocation sprint code:sprint-impl tu_xyz >/dev/null
    local count
    count=$(bash "$STATE_SH" get '.invocations | length')
    [ "$count" = "1" ]
    [ "$(bash "$STATE_SH" get '.invocations[0].skill')" = "code:sprint-impl" ]
    [ "$(bash "$STATE_SH" get '.invocations[0].tool_use_id')" = "tu_xyz" ]
}

@test "record-review-iteration increments counter" {
    bash "$STATE_SH" record-review-iteration >/dev/null
    bash "$STATE_SH" record-review-iteration >/dev/null
    [ "$(bash "$STATE_SH" get .review_iterations)" = "2" ]
}
