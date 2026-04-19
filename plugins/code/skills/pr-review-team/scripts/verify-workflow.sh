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

# TTL check: stale state files (>1 hour) are from dead sessions — clean up and allow stop
STATE_FILE="${STATE_FILES[0]}"
STATE_MAX_AGE=3600
STATE_MTIME=$(stat -f %m "$STATE_FILE" 2>/dev/null || stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
if [ $((NOW - STATE_MTIME)) -gt $STATE_MAX_AGE ]; then
    rm -f "$STATE_FILE"
    exit 0
fi

# Read progress from state file
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "{}")

# Validate STATE is parseable JSON before field extraction. A corrupt / empty
# / truncated state file would otherwise produce an empty STATE_PROJECT via
# the `//` fallback, which the legacy-state branch below would silently
# interpret as "no binding" and skip — masking a genuine in-progress review.
# On indeterminate data we skip (TTL-based GC removes the file eventually)
# rather than block, because raising a hard error on a race-induced truncated
# state would create a different false-block pattern.
if ! echo "$STATE" | jq -e . >/dev/null 2>&1; then
    exit 0
fi

# Extract all state fields in a single jq call — includes project_path for
# the Issue #236 cross-project binding check alongside the workflow fields.
read -r STATE_PROJECT SECURITY_DONE FIXER_DONE REREVIEW_DONE FINAL_CRITICAL FINAL_IMPORTANT < <(echo "$STATE" | jq -r '[(.project_path // ""), (.security_done // false | tostring), (.fixer_done // false | tostring), (.rereview_done // false | tostring), (.final_critical // -1 | tostring), (.final_important // -1 | tostring)] | @tsv')

# Project binding check (Issue #236): skip state files that belong to a
# different project. Without this, a stale state from session A (working on
# project /foo) would block Stop in session B (working on project /bar). We
# do NOT delete mismatched states here — the owning session may still be
# active and will clean up on its own; TTL-based GC above handles truly
# abandoned ones. `pwd -P` resolves symlinks so a checkout accessed via a
# symlinked path still matches the canonical path recorded at init time.
CURRENT_PROJECT="$(pwd -P 2>/dev/null || pwd)"
if [ -n "$STATE_PROJECT" ] && [ "$STATE_PROJECT" != "$CURRENT_PROJECT" ]; then
    # State belongs to another project — not our concern, let Stop proceed.
    exit 0
fi
# Legacy state files (pre-#236) genuinely lack a project_path field. Since we
# validated JSON above, an empty STATE_PROJECT at this point reflects the
# real schema rather than a parse failure. Treat legacy state as safe to
# ignore for Stop purposes — blocking on it causes the exact Issue #236
# regression. The TTL cleanup above removes legacy files eventually.
if [ -z "$STATE_PROJECT" ]; then
    exit 0
fi

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
