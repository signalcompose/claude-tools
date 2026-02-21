#!/usr/bin/env bash
# dev-cycle-stop.sh — Stop hook for /code:dev-cycle auto-chain enforcement
#
# Reads .claude/dev-cycle.state.json to determine if the dev-cycle is
# still in progress. If so, blocks Claude from stopping and instructs
# it to invoke the next skill.
#
# When no state file exists (standalone skill usage), exits cleanly.

set -euo pipefail

# Fail open if jq is not available
if ! command -v jq &>/dev/null; then
  exit 0
fi

STATE_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/dev-cycle.state.json"

# No state file → not in a dev-cycle → allow stop
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Read hook input from stdin (Claude Code provides stop_hook_active)
HOOK_INPUT=$(cat)

# Validate JSON before parsing (malformed input → allow stop)
if ! echo "$HOOK_INPUT" | jq empty 2>/dev/null; then
  exit 0
fi

STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')

# Guard: if stop_hook_active is true, allow stop to prevent infinite loop
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0
fi

# Read stage with TOCTOU safety: concurrent hooks may delete the file between
# the existence check above and this jq call. 2>/dev/null + || exit 0 ensures
# we fail open (allow stop) if the file disappears or contains invalid JSON.
STAGE=$(jq -r '.stage // empty' "$STATE_FILE" 2>/dev/null) || exit 0
[[ -n "$STAGE" ]] || exit 0

# Stage transition map
case "$STAGE" in
  sprint)
    NEXT_SKILL_ID="code:audit-compliance"
    NEXT_STAGE="audit"
    ;;
  audit)
    NEXT_SKILL_ID="code:shipping-pr"
    NEXT_STAGE="ship"
    ;;
  ship)
    NEXT_SKILL_ID="code:retrospective"
    NEXT_STAGE="retrospective"
    ;;
  retrospective|complete)
    # Cycle complete — clean up and allow stop
    rm -f "$STATE_FILE"
    exit 0
    ;;
  *)
    # Unknown stage — log, clean up, and allow stop (don't block on corrupted state)
    echo "[dev-cycle-stop] Unknown stage '${STAGE}' in state file — allowing stop" >&2
    rm -f "$STATE_FILE"
    exit 0
    ;;
esac

# --- Context Budget Check ---
# 方法1: Stop hook stdin から直接読み取り（利用可能な場合）
REMAINING=$(echo "$HOOK_INPUT" | jq -r '.context_window.remaining_percentage // empty' 2>/dev/null)

# 方法2: sidecar ファイルからフォールバック
if [[ -z "$REMAINING" || "$REMAINING" == "null" ]]; then
  SIDECAR_FILE="${CLAUDE_PROJECT_DIR:-.}/.claude/.context-budget.json"
  if [[ -f "$SIDECAR_FILE" ]]; then
    SIDECAR_DATA=$(jq '.' "$SIDECAR_FILE" 2>/dev/null) || true
    if [[ -n "$SIDECAR_DATA" ]]; then
      REMAINING=$(echo "$SIDECAR_DATA" | jq -r '.remaining // empty')
      SIDECAR_TS=$(echo "$SIDECAR_DATA" | jq -r '.ts // 0')
      NOW=$(date +%s)
      # 5分以上古いデータは無視
      if [[ $((NOW - SIDECAR_TS)) -gt 300 ]]; then
        REMAINING=""
      fi
    fi
  fi
fi

# 予算データがなければ現行動作（強制続行）
if [[ -n "$REMAINING" && "$REMAINING" != "null" ]]; then
  REMAINING_INT=${REMAINING%.*}

  # 閾値判定
  case "$NEXT_STAGE" in
    audit)         MIN_REMAINING=50 ;;
    ship)          MIN_REMAINING=30 ;;
    retrospective) MIN_REMAINING=15 ;;
    *)             MIN_REMAINING=0 ;;
  esac

  if [[ "$REMAINING_INT" -lt "$MIN_REMAINING" ]]; then
    # 予算不足: 拡張 state ファイルに記録
    case "$NEXT_STAGE" in
      audit)         SKIPPED='["audit","ship","retrospective"]' ;;
      ship)          SKIPPED='["ship","retrospective"]' ;;
      retrospective) SKIPPED='["retrospective"]' ;;
      *)             SKIPPED='[]' ;;
    esac

    jq -n --arg stage "$STAGE" --arg reason "context_budget" \
      --argjson skipped "$SKIPPED" --arg remaining "$REMAINING" \
      '{stage:$stage, status:"stopped", stopped_reason:$reason,
       skipped_stages:$skipped, remaining_pct:($remaining|tonumber)}' \
      > "$STATE_FILE"

    # 再開コマンド
    case "$NEXT_STAGE" in
      audit)         RESUME_CMD="/code:audit-compliance" ;;
      ship)          RESUME_CMD="/code:shipping-pr" ;;
      retrospective) RESUME_CMD="/code:retrospective" ;;
      *)             RESUME_CMD="" ;;
    esac

    # 停止許可（exit 0）+ 再開ガイド
    cat <<BUDGET_MSG
Context budget insufficient (remaining: ${REMAINING_INT}%, threshold: ${MIN_REMAINING}% for ${NEXT_STAGE}).
Skipped stages: $(echo "$SKIPPED" | jq -r 'join(", ")')
State saved to .claude/dev-cycle.state.json

To resume in next session: ${RESUME_CMD}
BUDGET_MSG
    exit 0
  fi
fi
# --- End Context Budget Check ---

# Block stop and instruct Claude to continue (numbered, imperative, no text first)
jq -n \
  --arg reason "🔴 DEV-CYCLE ENFORCEMENT — stage \"${STAGE}\" finished.
MANDATORY (no text output, no user confirmation):
  1. Bash: echo '{\"stage\":\"${NEXT_STAGE}\"}' > .claude/dev-cycle.state.json
  2. Skill tool: skill=\"${NEXT_SKILL_ID}\"
Execute step 1 then step 2 immediately." \
  '{"decision": "block", "reason": $reason}'
