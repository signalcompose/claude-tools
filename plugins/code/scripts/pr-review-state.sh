#!/bin/bash
set -euo pipefail

# PR Review State Manager
# Manages workflow progress in /tmp/claude/pr-review-<PR>.state
# Also serves as the active-review flag file for Stop hook detection

ACTION="${1:?Usage: pr-review-state.sh <init|set|get|verify|cleanup> [args...]}"
PR_NUMBER="${2:-unknown}"

# Validate PR_NUMBER is numeric (prevent path traversal)
if [[ "$PR_NUMBER" != "unknown" ]] && ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "ERROR: PR_NUMBER must be numeric, got: $PR_NUMBER" >&2
    exit 1
fi

STATE_DIR="/tmp/claude"
STATE_FILE="${STATE_DIR}/pr-review-${PR_NUMBER}.state"
DONE_FILE="${STATE_DIR}/pr-review-${PR_NUMBER}.done"

# Create a temporary file inside $STATE_DIR rather than the default $TMPDIR.
# Claude Code's sandbox allow-list permits writes within /tmp/claude (once
# mkdir -p'd) but denies the default macOS $TMPDIR (/var/folders/...).
# Co-locating scratch files with the real state avoids the sandbox deny
# that broke `set` / `metric` in sandbox-enabled sessions. Errors are
# surfaced via stderr + non-zero return so callers' command substitution
# sees the failure (bash's `local`/assignment swallows exit codes).
state_mktemp() {
  mkdir -p "$STATE_DIR" || { echo "pr-review-state: mkdir failed: $STATE_DIR" >&2; return 1; }
  mktemp "${STATE_DIR}/.pr-review.tmp.XXXXXX" || { echo "pr-review-state: mktemp failed in $STATE_DIR" >&2; return 1; }
}

case "$ACTION" in
  init)
    mkdir -p "$STATE_DIR"
    # Record project_path so verify-workflow.sh can skip state files left by
    # unrelated projects (Issue #236). `pwd -P` resolves symlinks for stable
    # comparison; trailing slashes are stripped by pwd by default.
    # session_id is recorded as supplementary telemetry — verify-workflow.sh
    # currently keys off project_path only, but storing session_id now keeps
    # future debug / cross-session correlation cheap.
    PROJECT_PATH="$(pwd -P 2>/dev/null || pwd)"
    SESSION_ID="${CLAUDE_SESSION_ID:-}"
    if ! command -v jq >/dev/null 2>&1; then
      # jq unavailable: fall back to printf. Escape backslash and double-quote
      # to keep the emitted JSON valid even for unusual filesystem paths. We
      # do not attempt full JSON escape (control chars, unicode) since POSIX
      # filesystem conventions disallow those in directory names.
      PROJECT_PATH_ESC="${PROJECT_PATH//\\/\\\\}"
      PROJECT_PATH_ESC="${PROJECT_PATH_ESC//\"/\\\"}"
      SESSION_ID_ESC="${SESSION_ID//\\/\\\\}"
      SESSION_ID_ESC="${SESSION_ID_ESC//\"/\\\"}"
      printf '{"pr":"%s","session_id":"%s","project_path":"%s","phase":"started","reviewers_done":false,"security_done":false,"fixer_done":false,"rereview_done":false,"iterations":0,"final_critical":-1,"final_important":-1}' \
        "$PR_NUMBER" "$SESSION_ID_ESC" "$PROJECT_PATH_ESC" > "$STATE_FILE"
    else
      jq -n \
        --arg pr "$PR_NUMBER" \
        --arg session "$SESSION_ID" \
        --arg project "$PROJECT_PATH" \
        '{pr:$pr, session_id:$session, project_path:$project, phase:"started",
          reviewers_done:false, security_done:false, fixer_done:false,
          rereview_done:false, iterations:0, final_critical:-1, final_important:-1}' \
        > "$STATE_FILE"
    fi
    echo "State initialized for PR #$PR_NUMBER"
    ;;
  set)
    KEY="${3:?Missing key}"
    VALUE="${4:?Missing value}"
    if [ ! -f "$STATE_FILE" ]; then
      echo "ERROR: State file not found. Run 'init' first." >&2
      exit 1
    fi
    if ! command -v jq &>/dev/null; then
      echo "ERROR: jq is required but not found" >&2
      exit 1
    fi
    TMP=$(state_mktemp) || exit 1
    trap 'rm -f "${TMP:-}"' EXIT
    jq --arg k "$KEY" --arg v "$VALUE" \
      '.[$k] = ($v | if . == "true" then true elif . == "false" then false else (try tonumber // .) end)' \
      "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"
    echo "State updated: $KEY=$VALUE"
    ;;
  get|verify)
    if [ ! -f "$STATE_FILE" ]; then
      # get returns empty JSON; verify returns sentinel string
      if [ "$ACTION" = "verify" ]; then echo "NO_STATE"; else echo "{}"; fi
      exit 0
    fi
    cat "$STATE_FILE"
    ;;
  cleanup)
    # If the state shows a converged review (critical=0 AND important=0 AND
    # rereview_done=true), preserve it as a `.done` marker so the Stop hook
    # can recognize a legitimate completed review in future sessions — even
    # after the transcript still carries evidence of the pr-review-team run.
    # Otherwise (unconverged / missing fields), remove the state file
    # unchanged — we don't want to leave misleading "done" markers for
    # reviews that never finished.
    if [ -f "$STATE_FILE" ] && command -v jq >/dev/null 2>&1 && \
       jq -e '.final_critical == 0 and .final_important == 0 and .rereview_done == true' \
          "$STATE_FILE" >/dev/null 2>&1; then
      # mv -f: overwrite a prior .done for the same PR. The newer converged
      # state supersedes any older marker — TTL-based GC in verify-workflow.sh
      # would have pruned it eventually, but explicit overwrite here keeps
      # behavior deterministic and avoids relying on mv's default.
      # Failure (cross-device, permissions) must NOT be silent: if mv doesn't
      # complete, the stale .state would be mistaken for an in-progress review
      # in the next Stop hook fire.
      mv -f "$STATE_FILE" "$DONE_FILE" || {
        echo "ERROR: mv failed: $STATE_FILE -> $DONE_FILE" >&2
        exit 1
      }
      echo "State marked as .done for PR #$PR_NUMBER (converged)"
    else
      rm -f "$STATE_FILE"
      echo "State cleaned up for PR #$PR_NUMBER"
    fi
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    exit 1
    ;;
esac
