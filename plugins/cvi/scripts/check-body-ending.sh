#!/bin/bash

# Stop hook: require Japanese prose in the final visible text block when the
# configured response language is Japanese. An intentional code-block-only
# response is allowed as an exception because it has no prose body to rewrite.
#
# Known limitation: if the final text block has not been flushed when Stop fires,
# the preceding block can be mistaken for the final one and cause a false block.
# The retry only asks for a corrected ending, and stop_hook_active prevents a loop.
# Hook ordering within one matcher is not guaranteed by Claude Code. Placement
# after check-speak-called.sh in hooks.json expresses intent only; hooks may run
# in parallel.

INPUT=$(cat)

# Fail open when jq is unavailable or the hook input cannot be parsed.
if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi
if ! printf '%s' "$INPUT" | jq empty >/dev/null 2>&1; then
    exit 0
fi

# Guard against repeated Stop-hook blocking.
STOP_HOOK_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config.sh" || { exit 0; }
load_cvi_config || exit 0

if [ "$CVI_ENABLED" = "off" ]; then
    exit 0
fi

# Keep this in sync with enforce-cvi-rules.sh. This may move to config.sh later.
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    RESPONSE_LANG=$(grep '"language"' "$SETTINGS_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
RESPONSE_LANG=${RESPONSE_LANG:-japanese}

TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ] || \
   [ ! -r "$TRANSCRIPT_PATH" ] || [ ! -s "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

# Select only the last assistant text block after the last real user prompt.
# Tool-result and metadata user entries do not start a new turn.
FINAL_TEXT=$(jq -rs '
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
  | last // empty
' "$TRANSCRIPT_PATH" 2>/dev/null) || exit 0

if [ -z "$FINAL_TEXT" ]; then
    exit 0
fi

strip_code() {
    awk '
      /^[[:space:]]*```/ { infence = !infence; next }
      !infence { gsub(/`[^`]*`/, ""); print }
    '
}

CLEAN_TEXT=$(printf '%s\n' "$FINAL_TEXT" | strip_code)
LAST_NONEMPTY_LINE=$(printf '%s\n' "$CLEAN_TEXT" | awk 'NF { line=$0 } END { print line }')

VOICE_ENDING=false
if printf '%s\n' "$LAST_NONEMPTY_LINE" | grep -qE '^[[:space:]]*\**[Vv]oice\**[[:space:]]*:'; then
    VOICE_ENDING=true
fi

MISSING_JAPANESE=false
if [ "$RESPONSE_LANG" = "japanese" ] && [ -n "$CLEAN_TEXT" ]; then
    if ! printf '%s' "$CLEAN_TEXT" | jq -Rs -e \
        'test("[\\p{Hiragana}\\p{Katakana}\\p{Han}]")' >/dev/null 2>&1; then
        MISSING_JAPANESE=true
    fi
fi

if [ "$VOICE_ENDING" = "true" ] || [ "$MISSING_JAPANESE" = "true" ]; then
    # Keep this detection equivalent to check-speak-called.sh. Hook execution
    # order is not guaranteed, so the body correction must not contradict the
    # speak hook when both requirements are violated at the same time.
    SPEAK_CALLED=false
    if grep -q '"type":"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null && \
       grep -qE '"skill":"cvi:speak"|"name":"mcp__(plugin_cvi_)?cvi-voice__speak"' \
            "$TRANSCRIPT_PATH" 2>/dev/null; then
        SPEAK_CALLED=true
    fi

    if [ "$SPEAK_CALLED" = "true" ]; then
        REASON="応答には日本語の散文本文が必要です（コードブロックのみで構成される応答は例外です）。Voice 行だけ・英語だけで終えず、日本語の散文本文で締め直してください。/cvi:speak は再度呼ばないでください（音声の二重再生を防ぐため、本文の締め直しのみ行ってください）。"
    else
        REASON="応答には日本語の散文本文が必要です（コードブロックのみで構成される応答は例外です）。Voice 行だけ・英語だけで終えず、本文を日本語で書き直した上で /cvi:speak も呼んでください。"
    fi
    jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
fi

exit 0
