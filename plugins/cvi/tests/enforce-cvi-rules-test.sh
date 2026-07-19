#!/bin/bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOOK="${PLUGIN_DIR}/scripts/enforce-cvi-rules.sh"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

export HOME="${TMP_DIR}/home"
mkdir -p "$HOME/.claude" "$HOME/.cvi"
printf '{"language":"japanese"}\n' > "$HOME/.claude/settings.json"

PASS=0
FAIL=0

record() {
    local name=$1
    local status=$2
    local expected=$3
    local output=$4
    if [ "$status" -eq 0 ] && [ "$output" = "$expected" ]; then
        printf 'PASS: %s\n' "$name"
        PASS=$((PASS + 1))
    else
        printf 'FAIL: %s (status=%s output=%s)\n' "$name" "$status" "$output"
        FAIL=$((FAIL + 1))
    fi
}

printf 'CVI_ENABLED=off\nENGLISH_PRACTICE=off\n' > "$HOME/.cvi/config"
OUTPUT=$(bash "$HOOK" 2>/dev/null)
STATUS=$?
record 'CVI disabled exits successfully without rules' "$STATUS" '' "$OUTPUT"

printf 'CVI_ENABLED=off\nENGLISH_PRACTICE=on\n' > "$HOME/.cvi/config"
OUTPUT=$(bash "$HOOK" 2>/dev/null)
STATUS=$?
if printf '%s' "$OUTPUT" | grep -q 'ENGLISH PRACTICE MODE IS ON' && \
   ! printf '%s' "$OUTPUT" | grep -q 'CVI CRITICAL RULES'; then
    NORMALIZED='english-practice-only'
else
    NORMALIZED="$OUTPUT"
fi
record 'English practice runs before CVI disabled early exit' "$STATUS" 'english-practice-only' "$NORMALIZED"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
