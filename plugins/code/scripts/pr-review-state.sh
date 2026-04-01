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

case "$ACTION" in
  init)
    mkdir -p "$STATE_DIR"
    printf '{"pr":"%s","phase":"started","reviewers_done":false,"security_done":false,"fixer_done":false,"rereview_done":false,"iterations":0,"final_critical":-1,"final_important":-1}' "$PR_NUMBER" > "$STATE_FILE"
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
    TMP=$(mktemp)
    trap 'rm -f "$TMP"' EXIT
    jq --arg k "$KEY" --arg v "$VALUE" \
      '.[$k] = ($v | if . == "true" then true elif . == "false" then false else (try tonumber // .) end)' \
      "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"
    echo "State updated: $KEY=$VALUE"
    ;;
  get)
    if [ ! -f "$STATE_FILE" ]; then
      echo "{}"
      exit 0
    fi
    cat "$STATE_FILE"
    ;;
  verify)
    if [ ! -f "$STATE_FILE" ]; then
      echo "NO_STATE"
      exit 0
    fi
    cat "$STATE_FILE"
    ;;
  cleanup)
    rm -f "$STATE_FILE"
    echo "State cleaned up for PR #$PR_NUMBER"
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    exit 1
    ;;
esac
