#!/bin/bash

# Stop hook: require Japanese prose somewhere in the current turn when the
# configured response language is Japanese. An intentional code-block-only
# response is allowed as an exception because it has no prose body to rewrite.
#
# The retry only asks for a corrected body, and stop_hook_active prevents a loop.
# Hook ordering within one matcher is not guaranteed by Claude Code. Placement
# after check-speak-called.sh in hooks.json expresses intent only; hooks may run
# in parallel.

INPUT=$(cat)

# Fail open when jq is unavailable or the hook input cannot be parsed.
if ! command -v jq >/dev/null 2>&1; then
    echo "[cvi] jq is unavailable; skipping body-ending check" >&2
    exit 0
fi
if ! printf '%s' "$INPUT" | jq empty >/dev/null 2>&1; then
    echo "[cvi] Invalid Stop hook input; skipping body-ending check" >&2
    exit 0
fi

# Guard against repeated Stop-hook blocking.
STOP_HOOK_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config.sh" || { echo "[cvi] Failed to source lib/config.sh" >&2; exit 0; }

load_cvi_config || {
    echo "[cvi] Failed to load CVI config; skipping body-ending check" >&2
    exit 0
}

if [ "$CVI_ENABLED" = "off" ]; then
    exit 0
fi

load_response_lang

TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ] || \
   [ ! -r "$TRANSCRIPT_PATH" ] || [ ! -s "$TRANSCRIPT_PATH" ]; then
    echo "[cvi] transcript_path is missing, unreadable, or empty; skipping body-ending check" >&2
    exit 0
fi

# Concatenate all assistant text blocks after the last real user prompt.
# Tool-result and metadata user entries do not start a new turn.
JQ_OUTPUT=$(jq -rs '
  def real_user:
    .type == "user"
    and (has("toolUseResult") | not)
    and (.isMeta != true)
    and (((.message.content // "") | if type == "array"
          then (map(.type == "tool_result") | any | not) else true end));
  . as $all
  | (reduce range(0; ($all | length)) as $i
      (-1; if ($all[$i] | real_user) then $i else . end)) as $u
  | $all[($u + 1):]
  | [ .[] | select(.type == "assistant")
      | (.message.content // [])[] | select(.type == "text") | .text ]
  | join("\n")
' "$TRANSCRIPT_PATH" 2>&1)
JQ_STATUS=$?
if [ "$JQ_STATUS" -ne 0 ]; then
    JQ_ERROR=$(printf '%s' "$JQ_OUTPUT" | tr '\n' ' ' | head -c 200)
    echo "[cvi] Failed to parse transcript for body-ending check (jq exit $JQ_STATUS): $JQ_ERROR" >&2
    exit 0
fi
TURN_TEXT=$JQ_OUTPUT

if [ -z "$TURN_TEXT" ]; then
    exit 0
fi

strip_code() {
    awk '
      /^[[:space:]]*```/ { infence = !infence; next }
      !infence { gsub(/`[^`]*`/, ""); print }
    '
}

CLEAN_TEXT=$(printf '%s\n' "$TURN_TEXT" | strip_code)

MISSING_JAPANESE=false
if [ "$RESPONSE_LANG" = "japanese" ] && [ -n "$CLEAN_TEXT" ]; then
    JQ_OUTPUT=$(printf '%s' "$CLEAN_TEXT" | jq -Rs \
        'test("[\\p{Hiragana}\\p{Katakana}\\p{Han}]")' 2>&1)
    JQ_STATUS=$?
    if [ "$JQ_STATUS" -ne 0 ]; then
        JQ_ERROR=$(printf '%s' "$JQ_OUTPUT" | tr '\n' ' ' | head -c 200)
        echo "[cvi] Japanese-character regex test failed (jq exit $JQ_STATUS): $JQ_ERROR; skipping check" >&2
    elif [ "$JQ_OUTPUT" = "false" ]; then
        MISSING_JAPANESE=true
    fi
fi

if [ "$MISSING_JAPANESE" = "true" ]; then
    # Keep this detection equivalent to check-speak-called.sh. Hook execution
    # order is not guaranteed, so the body correction must not contradict the
    # speak hook when both requirements are violated at the same time.
    SPEAK_CALLED=false
    if is_speak_called "$TRANSCRIPT_PATH"; then
        SPEAK_CALLED=true
    fi

    if [ "$SPEAK_CALLED" = "true" ]; then
        REASON="ターン内のどこにも日本語の散文本文が見つかりません（コードブロックのみで構成される応答は例外です）。日本語の散文本文を追加してください。/cvi:speak は再度呼ばないでください（音声の二重再生を防ぐため、本文の修正のみ行ってください）。"
    else
        REASON="ターン内のどこにも日本語の散文本文が見つかりません（コードブロックのみで構成される応答は例外です）。日本語の散文本文を追加した上で /cvi:speak も呼んでください。"
    fi
    jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
fi

exit 0
