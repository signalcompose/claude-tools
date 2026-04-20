#!/bin/bash
set -euo pipefail

# PR Review Team - Stop Hook (Command-based, deterministic)
# Verifies workflow completion using state file + transcript fallback
# Includes TTL-based stale state cleanup (1 hour max age)

INPUT=$(cat)

# Infinite loop prevention
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

# Session detection via flag file.
#   .state → an in-progress review (active workflow)
#   .done  → a completed, converged review preserved by cleanup
# pass-through priority: if a matching .done exists we trust it (review was
# properly completed earlier) and skip the workflow checks. Otherwise we look
# for .state; if neither exists but transcript shows pr-review-team, block so
# the leader surfaces the missing initialization.
# Initialize arrays before the glob so `set -u` doesn't trip on empty matches
# in bash 3.2 (macOS default). nullglob makes the pattern expand to nothing,
# leaving the pre-initialized empty array intact — safe to count with `${#arr[@]}`.
STATE_FILES=()
DONE_FILES=()
shopt -s nullglob
STATE_FILES=(/tmp/claude/pr-review-*.state)
DONE_FILES=(/tmp/claude/pr-review-*.done)
shopt -u nullglob

NOW=$(date +%s)

# Garbage-collect expired .done markers (24h) so they don't accumulate.
# `.done` is auto-kept longer than `.state` (24h vs 1h) because it legitimately
# spans multiple sessions — a merged PR's done marker needs to outlive the
# session that produced it.
DONE_MAX_AGE=86400
if [ ${#DONE_FILES[@]} -gt 0 ]; then
    for f in "${DONE_FILES[@]}"; do
        mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
        if [ $((NOW - mtime)) -gt $DONE_MAX_AGE ]; then
            rm -f "$f"
        fi
    done
    # Rescan .done after GC
    DONE_FILES=()
    shopt -s nullglob
    DONE_FILES=(/tmp/claude/pr-review-*.done)
    shopt -u nullglob
fi

# Ordering is deliberate: if a `.state` exists we ALWAYS run the workflow
# checks on it, even if an unrelated `.done` from a prior merged PR is still
# present. Using `.done` to short-circuit here would let a stale marker from
# PR X mask an in-progress, unconverged review of PR Y.
#
# `.done` pass-through only applies when there is NO active `.state` —
# i.e. the session has no in-flight review and we're looking for whether to
# credit a recently-completed one against the transcript evidence below.

# If no .state either, decide between pass (no workflow in progress) and
# block (pr-review-team launched without state init). A lingering `.done`
# is treated as corroborating evidence that a review was properly completed
# this session, so the transcript reference doesn't trigger a false block.
if [ ${#STATE_FILES[@]} -eq 0 ]; then
    if [ ${#DONE_FILES[@]} -gt 0 ]; then
        exit 0
    fi
    TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
    if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
        # Use a narrow match: only the explicit "Launching skill:" marker signals an
        # actual invocation. The broader `code:pr-review-team` pattern also matched
        # the skill listing injected into the session's system-reminder (available
        # skills), producing false positives in sessions that never invoked the
        # skill. See Issue #230.
        # Word boundary on the right prevents matching a future sibling skill
        # such as `code:pr-review-team-advanced`.
        if grep -qE 'Launching skill: code:pr-review-team($|[^a-zA-Z0-9_-])' "$TRANSCRIPT_PATH" 2>/dev/null; then
            printf 'pr-review-team ran without pr-review-state.sh init. Run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh init <PR>` at the start of the skill — iteration convergence cannot be verified without state.' \
              | jq -Rs '{"decision":"block","reason":.}'
            exit 0
        fi
    fi
    exit 0
fi

STATE_MAX_AGE=3600
CURRENT_PROJECT="$(pwd -P 2>/dev/null || pwd)"

# Select the state file belonging to the current project. The previous
# single-slot approach (STATE_FILES[0]) was unsafe: if a stale state from
# project A sorted before project B's active state, we would early-exit on
# the A mismatch and silently skip B's workflow checks — inverting the
# Issue #236 bug into a "current project's review ignored" bug.
#
# Policy per state file encountered:
#   * expired  (mtime > TTL)           → delete (GC) and continue scan
#   * parse error / non-JSON           → skip (TTL will eventually collect)
#   * legacy (no project_path)         → skip for Stop purposes (Issue #236
#                                        safe-default; blocking would cause
#                                        the same cross-session regression)
#   * project_path matches current     → select it, stop scanning
#   * project_path different           → skip (owning session cleans up; we
#                                        are not authoritative over theirs)
#
# If no file matches the current project, Stop proceeds — there is no
# in-flight review owned by this session to verify.
STATE_FILE=""
STATE=""
for candidate in "${STATE_FILES[@]}"; do
    mtime=$(stat -f %m "$candidate" 2>/dev/null || stat -c %Y "$candidate" 2>/dev/null || echo 0)
    if [ $((NOW - mtime)) -gt $STATE_MAX_AGE ]; then
        rm -f "$candidate"
        continue
    fi
    candidate_state=$(cat "$candidate" 2>/dev/null || echo "")
    if [ -z "$candidate_state" ] || ! echo "$candidate_state" | jq -e . >/dev/null 2>&1; then
        continue
    fi
    candidate_project=$(echo "$candidate_state" | jq -r '.project_path // ""' 2>/dev/null || echo "")
    if [ -z "$candidate_project" ]; then
        # Legacy pre-#236 state: skip to avoid cross-session false-block.
        continue
    fi
    if [ "$candidate_project" = "$CURRENT_PROJECT" ]; then
        STATE_FILE="$candidate"
        STATE="$candidate_state"
        break
    fi
done

if [ -z "$STATE_FILE" ]; then
    exit 0
fi

# Extract all state fields in a single jq call — includes project_path for
# parity with the scan step. IFS=$'\t' ensures we split only on the @tsv
# separator; default IFS would also split on spaces, corrupting paths like
# "/Users/John Doe/...". On jq failure we skip rather than continue with
# indeterminate fields (matches the "skip on parse trouble" policy above).
if ! STATE_FIELDS=$(echo "$STATE" | jq -r '[(.project_path // ""), (.security_done // false | tostring), (.fixer_done // false | tostring), (.rereview_done // false | tostring), (.bot_feedback_read // false | tostring), (.final_critical // -1 | tostring), (.final_important // -1 | tostring)] | @tsv' 2>/dev/null); then
    exit 0
fi
IFS=$'\t' read -r STATE_PROJECT SECURITY_DONE FIXER_DONE REREVIEW_DONE BOT_FEEDBACK_READ FINAL_CRITICAL FINAL_IMPORTANT <<< "$STATE_FIELDS"

# Load transcript once for all checks (avoid repeated file reads)
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || echo "")
TRANSCRIPT=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    TRANSCRIPT=$(cat "$TRANSCRIPT_PATH" 2>/dev/null || true)
fi

MISSING=""

# Check 1: Security checklist completion
if [ "$SECURITY_DONE" != "true" ]; then
    if [ -n "$TRANSCRIPT" ]; then
        if ! echo "$TRANSCRIPT" | grep -q "security-checklist.md" 2>/dev/null; then
            MISSING="${MISSING}\n- Security checklist was not read"
        fi
    else
        MISSING="${MISSING}\n- Security checklist was not completed (state: security_done=false)"
    fi
fi

# Check 2: Fixer agent spawned when issues were found
if [ -n "$TRANSCRIPT" ]; then
    if echo "$TRANSCRIPT" | grep -qE '"Critical Issues"|"Important Issues"' 2>/dev/null; then
        if [ "$FIXER_DONE" != "true" ]; then
            MISSING="${MISSING}\n- Fixer agent was not spawned (direct editing is prohibited)"
        fi
    fi
fi

# Check 3: After fixes, re-review must have happened (no self-declaring convergence).
# The iteration contract: find issues → fix → re-run reviewers → record final counts.
# Skipping re-review means the fix is unverified.
if [ "$FIXER_DONE" = "true" ] && [ "$REREVIEW_DONE" != "true" ]; then
    MISSING="${MISSING}\n- After fixer_done=true, re-review (iteration N+1) was not recorded. Re-run reviewers and call 'pr-review-state.sh set <PR> rereview_done true'."
fi

# Check 3b: rereview_done=true must be backed by transcript evidence of at
# least 2 reviewer agent launches (initial + post-fix). This prevents the
# leader from self-declaring convergence by flipping the flag without
# actually re-running the reviewers — which is effectively "judging your own
# fix without independent verification" and defeats the purpose of Step 5.
if [ "$FIXER_DONE" = "true" ] && [ "$REREVIEW_DONE" = "true" ] && [ -n "$TRANSCRIPT" ]; then
    REVIEWER_LAUNCHES=$(echo "$TRANSCRIPT" | grep -cE '"subagent_type":[[:space:]]*"pr-review-toolkit:code-reviewer"' 2>/dev/null || echo 0)
    if [ "$REVIEWER_LAUNCHES" -lt 2 ]; then
        MISSING="${MISSING}\n- rereview_done=true but transcript shows only ${REVIEWER_LAUNCHES} code-reviewer agent launch(es). Re-review requires a fresh reviewer invocation after the fix, not state manipulation."
    fi
fi

# Check 3c: Before declaring convergence the leader must have consulted
# GitHub bot feedback (claude-review check-run annotations, PR review
# comments). Accept either an explicit state flag or transcript evidence
# of a matching gh command — otherwise block so the leader runs the check.
if [ "$FIXER_DONE" = "true" ] && [ "$BOT_FEEDBACK_READ" != "true" ]; then
    if [ -n "$TRANSCRIPT" ]; then
        if ! echo "$TRANSCRIPT" | grep -qE 'gh pr view [^|]*--json[^|]*(reviews|comments)|gh api [^|]*pulls/[0-9]+/(comments|reviews)|gh api [^|]*check-runs/[0-9]+/annotations' 2>/dev/null; then
            MISSING="${MISSING}\n- Bot feedback (claude-review check / PR review comments) was not read. Run 'gh pr view <PR> --json reviews,comments' or equivalent, then 'pr-review-state.sh set <PR> bot_feedback_read true'."
        fi
    else
        MISSING="${MISSING}\n- bot_feedback_read=false and transcript unavailable — cannot verify bot feedback was consulted."
    fi
fi

# Check 4: Convergence — final_critical and final_important must both be 0.
# -1 means "not recorded yet"; any positive count means unresolved findings.
if [ "$FINAL_CRITICAL" = "-1" ] || [ "$FINAL_IMPORTANT" = "-1" ]; then
    if [ "$FIXER_DONE" = "true" ]; then
        MISSING="${MISSING}\n- final_critical/final_important not recorded. Run 'pr-review-state.sh set <PR> final_critical <N>' and 'final_important <N>' after the last review."
    fi
elif [ "$FINAL_CRITICAL" != "0" ] || [ "$FINAL_IMPORTANT" != "0" ]; then
    MISSING="${MISSING}\n- Convergence not reached (final_critical=${FINAL_CRITICAL}, final_important=${FINAL_IMPORTANT}). Run another fix+review iteration or report to user for manual decision."
fi

if [ -n "$MISSING" ]; then
    REASON=$(printf 'PR review workflow incomplete:%b\n\nComplete all required steps before stopping.' "$MISSING")
    printf '%s' "$REASON" | jq -Rs '{"decision":"block","reason":.}'
    exit 0
fi

exit 0
