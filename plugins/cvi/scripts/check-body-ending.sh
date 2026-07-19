#!/bin/bash

# Stop hook: require Japanese prose somewhere in the current turn and require
# the final non-empty prose line to contain Japanese or be a Voice line when
# the configured response language is Japanese. An intentional code-block-only
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

# Collect all assistant text blocks after the last real user prompt.
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
' "$TRANSCRIPT_PATH" 2>&1)
JQ_STATUS=$?
if [ "$JQ_STATUS" -ne 0 ]; then
    JQ_ERROR=$(printf '%s' "$JQ_OUTPUT" | tr '\n' ' ' | head -c 200)
    echo "[cvi] Failed to parse transcript for body-ending check (jq exit $JQ_STATUS): $JQ_ERROR" >&2
    exit 0
fi
TEXT_BLOCKS=$JQ_OUTPUT

if [ "$TEXT_BLOCKS" = "[]" ]; then
    exit 0
fi

# Fence-aware scanner shared by stripping and balance detection. Following the
# CommonMark rules for backtick fences:
# - A fence line has at most 3 leading spaces (tabs are not fence indentation)
#   followed by a run of 3+ backticks; 4+ spaces of indent is not a fence.
# - An opening fence whose info string contains a backtick is invalid and the
#   line stays prose.
# - A fence opened by a run of 3+ backticks is only closed by a run at least
#   as long followed by nothing but whitespace, so a ```` fence that displays
#   ``` fences keeps the inner markers and their contents as code, and a line
#   like ```oops inside a fence is code rather than a closing fence.
# mode=strip prints prose lines outside fences with inline code removed;
# mode=balance prints "open" or "balanced" for the final fence state.
fence_scan() {
    awk -v mode="$1" '
      # Sets globals run (backtick-run length) and tail (text after the run).
      # Returns 1 when the line is a fence candidate, 0 otherwise.
      function fence_parse(line,    i) {
        i = 0
        while (substr(line, i + 1, 1) == " ") i++
        if (i > 3) return 0
        run = 0
        while (substr(line, i + run + 1, 1) == "`") run++
        if (run < 3) return 0
        tail = substr(line, i + run + 1)
        return 1
      }
      {
        if (fence_parse($0)) {
          if (!infence) {
            # A backtick in the info string invalidates the opening fence;
            # the line falls through and stays prose.
            if (tail !~ /`/) { infence = 1; open_run = run; next }
          } else {
            # Close only on a long-enough run with a whitespace-only suffix;
            # any other candidate line is fence content either way.
            if (run >= open_run && tail ~ /^[[:space:]]*$/) infence = 0
            next
          }
        }
        if (mode == "strip" && !infence) { gsub(/`[^`]*`/, ""); print }
      }
      END { if (mode == "balance") print (infence ? "open" : "balanced") }
    '
}

strip_code() {
    fence_scan strip
}

# When fences are balanced across blocks, strip code from the complete response
# so a fence opened in one block can close in another. For malformed responses
# with an unmatched fence, strip each block independently so the unmatched fence
# neither exposes its code as prose nor hides prose in a later block.
JQ_OUTPUT=$(printf '%s' "$TEXT_BLOCKS" | jq -r 'join("\n")' 2>&1)
JQ_STATUS=$?
if [ "$JQ_STATUS" -ne 0 ]; then
    JQ_ERROR=$(printf '%s' "$JQ_OUTPUT" | tr '\n' ' ' | head -c 200)
    echo "[cvi] Failed to join assistant text blocks (jq exit $JQ_STATUS): $JQ_ERROR" >&2
    exit 0
fi
JOINED_TEXT=$JQ_OUTPUT

FENCE_STATE=$(printf '%s\n' "$JOINED_TEXT" | fence_scan balance)
if [ "$FENCE_STATE" = "balanced" ]; then
    CLEAN_TEXT=$(printf '%s\n' "$JOINED_TEXT" | strip_code)
else
    JQ_OUTPUT=$(printf '%s' "$TEXT_BLOCKS" | jq -c '.[]' 2>&1)
    JQ_STATUS=$?
    if [ "$JQ_STATUS" -ne 0 ]; then
        JQ_ERROR=$(printf '%s' "$JQ_OUTPUT" | tr '\n' ' ' | head -c 200)
        echo "[cvi] Failed to enumerate assistant text blocks (jq exit $JQ_STATUS): $JQ_ERROR" >&2
        exit 0
    fi

    CLEAN_TEXT=$(
        while IFS= read -r BLOCK_JSON; do
            BLOCK_OUTPUT=$(printf '%s' "$BLOCK_JSON" | jq -r '.' 2>&1)
            BLOCK_STATUS=$?
            if [ "$BLOCK_STATUS" -ne 0 ]; then
                BLOCK_ERROR=$(printf '%s' "$BLOCK_OUTPUT" | tr '\n' ' ' | head -c 200)
                echo "[cvi] Failed to decode assistant text block (jq exit $BLOCK_STATUS): $BLOCK_ERROR" >&2
                exit 1
            fi
            printf '%s\n' "$BLOCK_OUTPUT" | strip_code
        done <<< "$JQ_OUTPUT"
    )
    CLEAN_STATUS=$?
    if [ "$CLEAN_STATUS" -ne 0 ]; then
        exit 0
    fi
fi

MISSING_JAPANESE=false
INVALID_ENDING=false
# Require a non-whitespace character so whitespace-only residue (for example a
# trailing space-only line after a code fence) still counts as code-block-only.
if [ "$RESPONSE_LANG" = "japanese" ] && \
   printf '%s' "$CLEAN_TEXT" | grep -q '[^[:space:]]'; then
    JQ_OUTPUT=$(printf '%s' "$CLEAN_TEXT" | jq -Rs \
        'test("[\\p{Hiragana}\\p{Katakana}\\p{Han}]")' 2>&1)
    JQ_STATUS=$?
    if [ "$JQ_STATUS" -ne 0 ]; then
        JQ_ERROR=$(printf '%s' "$JQ_OUTPUT" | tr '\n' ' ' | head -c 200)
        echo "[cvi] Japanese-character regex test failed (jq exit $JQ_STATUS): $JQ_ERROR; skipping check" >&2
    elif [ "$JQ_OUTPUT" = "false" ]; then
        MISSING_JAPANESE=true
    else
        LAST_NONEMPTY_LINE=$(printf '%s\n' "$CLEAN_TEXT" | awk 'NF{line=$0} END{print line}')
        JQ_OUTPUT=$(printf '%s' "$LAST_NONEMPTY_LINE" | jq -Rs \
            'test("[\\p{Hiragana}\\p{Katakana}\\p{Han}]")' 2>&1)
        JQ_STATUS=$?
        if [ "$JQ_STATUS" -ne 0 ]; then
            JQ_ERROR=$(printf '%s' "$JQ_OUTPUT" | tr '\n' ' ' | head -c 200)
            echo "[cvi] Japanese prose was detected, but final-line Japanese-character validation failed (jq exit $JQ_STATUS): $JQ_ERROR; allowing response (fail-open to avoid breaking the Stop hook)" >&2
        elif [ "$JQ_OUTPUT" = "false" ] && \
             ! printf '%s\n' "$LAST_NONEMPTY_LINE" | grep -Eq '^[[:space:]]*\**[Vv]oice\**[[:space:]]*:'; then
            INVALID_ENDING=true
        fi
    fi
fi

if [ "$MISSING_JAPANESE" = "true" ] || [ "$INVALID_ENDING" = "true" ]; then
    # Keep this detection equivalent to check-speak-called.sh. Hook execution
    # order is not guaranteed, so the body correction must not contradict the
    # speak hook when both requirements are violated at the same time.
    SPEAK_CALLED=false
    if is_speak_called "$TRANSCRIPT_PATH"; then
        SPEAK_CALLED=true
    fi

    if [ "$MISSING_JAPANESE" = "true" ] && [ "$SPEAK_CALLED" = "true" ]; then
        REASON="ターン内のどこにも日本語の散文本文が見つかりません（コードブロックのみで構成される応答は例外です）。日本語の散文本文を追加してください。/cvi:speak は再度呼ばないでください（音声の二重再生を防ぐため、本文の修正のみ行ってください）。"
    elif [ "$MISSING_JAPANESE" = "true" ]; then
        REASON="ターン内のどこにも日本語の散文本文が見つかりません（コードブロックのみで構成される応答は例外です）。日本語の散文本文を追加した上で /cvi:speak も呼んでください。"
    elif [ "$SPEAK_CALLED" = "true" ]; then
        REASON="日本語の本文はありますが、応答の締めくくり（最後の行）が日本語でもVoice行でもありません。日本語の散文、または /cvi:speak のVoice行で締めてください。/cvi:speak は再度呼ばないでください（音声の二重再生を防ぐため、本文の修正のみ行ってください）。"
    else
        REASON="日本語の本文はありますが、応答の締めくくり（最後の行）が日本語でもVoice行でもありません。日本語の散文、または /cvi:speak のVoice行で締めた上で /cvi:speak も呼んでください。"
    fi
    jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
fi

exit 0
