#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOOK="${PLUGIN_DIR}/scripts/check-body-ending.sh"
SPEAK_HOOK="${PLUGIN_DIR}/scripts/check-speak-called.sh"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

export HOME="${TMP_DIR}/home"
mkdir -p "$HOME/.claude" "$HOME/.cvi" "${TMP_DIR}/transcripts"
printf 'CVI_ENABLED=on\n' > "$HOME/.cvi/config"
printf '{"language":"japanese"}\n' > "$HOME/.claude/settings.json"

PASS=0
FAIL=0
CASE_ID=0

write_transcript() {
    local path=$1
    local text=$2
    jq -cn '{type:"user",message:{content:"request"}}' > "$path"
    jq -cn --arg text "$text" \
        '{type:"assistant",message:{content:[{type:"text",text:$text}]}}' >> "$path"
}

run_hook() {
    local input=$1
    OUTPUT=$(printf '%s' "$input" | bash "$HOOK" 2>/dev/null)
    STATUS=$?
}

run_speak_hook() {
    local input=$1
    OUTPUT=$(printf '%s' "$input" | bash "$SPEAK_HOOK" 2>/dev/null)
    STATUS=$?
}

record() {
    local name=$1
    local expected=$2
    local require_empty=${3:-false}
    local decision="allow"
    if [ -n "$OUTPUT" ]; then
        decision=$(printf '%s' "$OUTPUT" | jq -r '.decision // "invalid"' 2>/dev/null || printf 'invalid')
    fi
    if [ "$STATUS" -eq 0 ] && [ "$decision" = "$expected" ] && \
       { [ "$require_empty" != "true" ] || [ -z "$OUTPUT" ]; }; then
        printf 'PASS: %s\n' "$name"
        PASS=$((PASS + 1))
    else
        printf 'FAIL: %s (status=%s decision=%s output=%s)\n' "$name" "$STATUS" "$decision" "$OUTPUT"
        FAIL=$((FAIL + 1))
    fi
}

case_text() {
    local name=$1
    local language=$2
    local text=$3
    local expected=$4
    CASE_ID=$((CASE_ID + 1))
    local transcript="${TMP_DIR}/transcripts/case-${CASE_ID}.jsonl"
    printf '{"language":"%s"}\n' "$language" > "$HOME/.claude/settings.json"
    write_transcript "$transcript" "$text"
    run_hook "$(jq -cn --arg path "$transcript" '{transcript_path:$path}')"
    record "$name" "$expected"
}

case_text 'Voice-only ending blocks' japanese 'Voice: "Task completed."' block
case_text 'Voice-only ending allows in English mode' english 'Voice: "Task completed."' allow
case_text 'Japanese multiline body allows' japanese $'作業が完了しました。\n変更内容を確認済みです。' allow
case_text 'Japanese text after Voice allows' japanese $'Voice: "Task completed."\n作業は完了しました。' allow
case_text 'Japanese body followed by invalid English prose blocks' japanese $'作業が完了しました。\nFinal English only.' block
case_text 'Japanese body with Japanese final line allows' japanese $'作業を実施しました。\n確認も完了しました。' allow
case_text 'English-only ending blocks in Japanese mode' japanese 'Task completed successfully.' block
case_text 'English-only ending allows in English mode' english 'Task completed successfully.' allow

fallback_transcript="${TMP_DIR}/transcripts/default-language.jsonl"
write_transcript "$fallback_transcript" 'Task completed successfully.'
rm "$HOME/.claude/settings.json"
STDERR_FILE="${TMP_DIR}/default-language.stderr"
OUTPUT=$(printf '%s' "$(jq -cn --arg path "$fallback_transcript" '{transcript_path:$path}')" | \
    bash "$HOOK" 2>"$STDERR_FILE")
STATUS=$?
if ! grep -q "defaulting to 'japanese'" "$STDERR_FILE"; then
    OUTPUT='{"decision":"invalid"}'
fi
record 'missing settings defaults to Japanese with warning' block
printf '{}\n' > "$HOME/.claude/settings.json"
STDERR_FILE="${TMP_DIR}/missing-language.stderr"
OUTPUT=$(printf '%s' "$(jq -cn --arg path "$fallback_transcript" '{transcript_path:$path}')" | \
    bash "$HOOK" 2>"$STDERR_FILE")
STATUS=$?
if ! grep -q "could not parse 'language'.*defaulting to 'japanese'" "$STDERR_FILE"; then
    OUTPUT='{"decision":"invalid"}'
fi
record 'settings without language defaults to Japanese with warning' block
printf '{"language":"japanese"}\n' > "$HOME/.claude/settings.json"

transcript="${TMP_DIR}/transcripts/stop-active.jsonl"
write_transcript "$transcript" 'Voice: "Task completed."'
run_hook "$(jq -cn --arg path "$transcript" '{stop_hook_active:true,transcript_path:$path}')"
record 'stop_hook_active allows' allow

run_hook '{}'
record 'missing transcript allows' allow
run_hook '{broken json'
record 'invalid hook input JSON warns and fails open' allow true
run_hook '{"transcript_path":"/does/not/exist"}'
record 'nonexistent transcript allows' allow
empty_transcript="${TMP_DIR}/transcripts/empty.jsonl"
: > "$empty_transcript"
run_hook "$(jq -cn --arg path "$empty_transcript" '{transcript_path:$path}')"
record 'empty transcript allows' allow
unreadable_transcript="${TMP_DIR}/transcripts/unreadable.jsonl"
write_transcript "$unreadable_transcript" 'Voice: "Task completed."'
chmod 000 "$unreadable_transcript"
run_hook "$(jq -cn --arg path "$unreadable_transcript" '{transcript_path:$path}')"
record 'unreadable transcript allows' allow
chmod 600 "$unreadable_transcript"
invalid_transcript="${TMP_DIR}/transcripts/invalid.jsonl"
printf 'not json\n' > "$invalid_transcript"
run_hook "$(jq -cn --arg path "$invalid_transcript" '{transcript_path:$path}')"
record 'invalid JSONL allows' allow

no_jq_bin="${TMP_DIR}/no-jq-bin"
mkdir -p "$no_jq_bin"
for command_path in /bin/cat /bin/dirname; do
    ln -s "$command_path" "$no_jq_bin/${command_path##*/}"
done
OUTPUT=$(printf '{}' | PATH="$no_jq_bin" /bin/bash "$HOOK" 2>/dev/null)
STATUS=$?
record 'missing jq warns and fails open' allow true

broken_plugin="${TMP_DIR}/broken-plugin"
mkdir -p "$broken_plugin/scripts/lib"
cp "$HOOK" "$broken_plugin/scripts/check-body-ending.sh"
printf 'return 1\n' > "$broken_plugin/scripts/lib/config.sh"
OUTPUT=$(printf '{}' | bash "$broken_plugin/scripts/check-body-ending.sh" 2>/dev/null)
STATUS=$?
record 'config source failure warns and fails open' allow true

case_text 'Japanese body plus fenced code allows' japanese $'作業が完了しました。\n```sh\necho done\n```' allow
case_text 'fenced code only allows' japanese $'```sh\necho done\n```' allow
case_text 'Voice inside fenced code allows' japanese $'```text\nVoice: "example"\n```' allow
case_text 'English prose plus fenced code blocks' japanese $'Task completed.\n```sh\necho done\n```' block
case_text 'unquoted Voice without Japanese blocks' japanese 'Voice: Task completed.' block
case_text 'bold Voice without Japanese blocks' japanese '**Voice:** "Task completed."' block

japanese_then_voice_transcript="${TMP_DIR}/transcripts/japanese-then-voice.jsonl"
write_transcript "$japanese_then_voice_transcript" '作業が完了しました。'
jq -cn '{type:"assistant",message:{content:[{type:"tool_use",name:"mcp__plugin_cvi_cvi-voice__speak",input:{text:"done"}}]}}' >> "$japanese_then_voice_transcript"
jq -cn '{type:"assistant",message:{content:[{type:"text",text:"Voice: \"Task completed.\""}]}}' >> "$japanese_then_voice_transcript"
run_hook "$(jq -cn --arg path "$japanese_then_voice_transcript" '{transcript_path:$path}')"
record 'Japanese body before tool call and Voice-only final block allows' allow

printf '{"language":"japanese"}\n' > "$HOME/.claude/settings.json"
boundary_transcript="${TMP_DIR}/transcripts/boundaries.jsonl"
jq -cn '{type:"user",message:{content:"old request"}}' > "$boundary_transcript"
jq -cn '{type:"assistant",message:{content:[{type:"text",text:"以前の日本語です。"}]}}' >> "$boundary_transcript"
jq -cn '{type:"user",message:{content:"current request"}}' >> "$boundary_transcript"
jq -cn '{type:"assistant",message:{content:[{type:"text",text:"途中の日本語です。"}]}}' >> "$boundary_transcript"
jq -cn '{type:"user",message:{content:[{type:"tool_result",content:"ok"}]}}' >> "$boundary_transcript"
jq -cn '{type:"user",isMeta:true,message:{content:"metadata"}}' >> "$boundary_transcript"
jq -cn '{type:"user",toolUseResult:{ok:true},message:{content:"tool result"}}' >> "$boundary_transcript"
jq -cn '{type:"assistant",message:{content:[{type:"text",text:"Final English only."}]}}' >> "$boundary_transcript"
run_hook "$(jq -cn --arg path "$boundary_transcript" '{transcript_path:$path}')"
record 'Japanese earlier in turn does not excuse an invalid final line' block

past_turn_transcript="${TMP_DIR}/transcripts/past-turn-boundary.jsonl"
jq -cn '{type:"user",message:{content:"old request"}}' > "$past_turn_transcript"
jq -cn '{type:"assistant",message:{content:[{type:"text",text:"以前の日本語です。"}]}}' >> "$past_turn_transcript"
jq -cn '{type:"user",message:{content:"current request"}}' >> "$past_turn_transcript"
jq -cn '{type:"user",message:{content:[{type:"tool_result",content:"ok"}]}}' >> "$past_turn_transcript"
jq -cn '{type:"user",isMeta:true,message:{content:"metadata"}}' >> "$past_turn_transcript"
jq -cn '{type:"user",toolUseResult:{ok:true},message:{content:"tool result"}}' >> "$past_turn_transcript"
jq -cn '{type:"assistant",message:{content:[{type:"text",text:"Final English only."}]}}' >> "$past_turn_transcript"
run_hook "$(jq -cn --arg path "$past_turn_transcript" '{transcript_path:$path}')"
record 'Japanese from past turn does not cross real-user boundary' block

printf 'CVI_ENABLED=off\n' > "$HOME/.cvi/config"
case_text 'CVI disabled allows Voice and English ending' japanese 'Voice: "Task completed."' allow
printf 'CVI_ENABLED=on\n' > "$HOME/.cvi/config"

independent_transcript="${TMP_DIR}/transcripts/independent.jsonl"
write_transcript "$independent_transcript" '日本語本文で完了します。'
input=$(jq -cn --arg path "$independent_transcript" '{transcript_path:$path}')
run_hook "$input"
record 'body hook allows valid body without speak call' allow
run_speak_hook "$input"
record 'existing speak hook independently blocks missing call' block

simultaneous_transcript="${TMP_DIR}/transcripts/simultaneous.jsonl"
write_transcript "$simultaneous_transcript" 'Voice: "Task completed."'
input=$(jq -cn --arg path "$simultaneous_transcript" '{transcript_path:$path}')
run_hook "$input"
if printf '%s' "$OUTPUT" | grep -q '再度呼ばない'; then
    OUTPUT='{"decision":"invalid"}'
fi
record 'simultaneous violation body reason requires speak without contradiction' block
run_speak_hook "$input"
record 'simultaneous violation speak hook blocks missing call' block

jq -cn '{type:"assistant",message:{content:[{type:"tool_use",name:"Skill",input:{skill:"cvi:speak"}}]}}' >> "$simultaneous_transcript"
jq -cn '{type:"assistant",message:{content:[{type:"text",text:"作業が完了しました。"}]}}' >> "$simultaneous_transcript"
run_hook "$input"
record 'corrected retry body hook allows' allow
run_speak_hook "$input"
record 'corrected retry speak hook allows' allow

mcp_transcript="${TMP_DIR}/transcripts/mcp-speak.jsonl"
write_transcript "$mcp_transcript" 'Voice: "Task completed."'
jq -cn '{type:"assistant",message:{content:[{type:"tool_use",name:"mcp__plugin_cvi_cvi-voice__speak",input:{text:"done"}}]}}' >> "$mcp_transcript"
input=$(jq -cn --arg path "$mcp_transcript" '{transcript_path:$path}')
run_hook "$input"
if ! printf '%s' "$OUTPUT" | grep -q '再度呼ばない'; then
    OUTPUT='{"decision":"invalid"}'
fi
record 'MCP speak tool is detected by body hook' block

bare_mcp_transcript="${TMP_DIR}/transcripts/bare-mcp-speak.jsonl"
write_transcript "$bare_mcp_transcript" 'Voice: "Task completed."'
jq -cn '{type:"assistant",message:{content:[{type:"tool_use",name:"mcp__cvi-voice__speak",input:{text:"done"}}]}}' >> "$bare_mcp_transcript"
input=$(jq -cn --arg path "$bare_mcp_transcript" '{transcript_path:$path}')
run_hook "$input"
if ! printf '%s' "$OUTPUT" | grep -q '再度呼ばない'; then
    OUTPUT='{"decision":"invalid"}'
fi
record 'bare MCP speak tool is detected by body hook' block

printf '{"language":"japanese","sandbox":{"enabled":true}}\n' > "$HOME/.claude/settings.json"
sandbox_transcript="${TMP_DIR}/transcripts/sandbox.jsonl"
write_transcript "$sandbox_transcript" 'Voice: "Task completed."'
input=$(jq -cn --arg path "$sandbox_transcript" '{transcript_path:$path}')
run_hook "$input"
record 'sandbox enabled does not skip body hook' block
run_speak_hook "$input"
record 'sandbox enabled skips speak hook' allow true

printf '{"language":"japanese","sandbox":{"enabled":false}}\n' > "$HOME/.claude/settings.json"
printf '{"sandbox":{"enabled":true}}\n' > "$HOME/.claude/settings.local.json"
run_speak_hook "$input"
local_true_skipped=false
if [ "$STATUS" -eq 0 ] && [ -z "$OUTPUT" ]; then
    local_true_skipped=true
fi
printf '{"sandbox":{"enabled":false}}\n' > "$HOME/.claude/settings.local.json"
run_speak_hook "$input"
if [ "$local_true_skipped" != "true" ]; then
    OUTPUT='{"decision":"invalid"}'
fi
record 'local sandbox settings override global and honor explicit false' block
rm "$HOME/.claude/settings.local.json"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
