#!/bin/bash
# CVI shared config loader
# Usage:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh" || exit 1
#   load_cvi_config

CVI_CONFIG_FILE="$HOME/.cvi/config"

load_cvi_config() {
    # Defaults
    CVI_ENABLED="on"
    SPEECH_RATE="200"
    VOICE_LANG="ja"
    VOICE_EN="Samantha"
    VOICE_JA="system"
    AUTO_DETECT_LANG="false"
    VOICE_MODE="auto"
    VOICE_FIXED=""
    ENGLISH_PRACTICE="off"

    if [ -f "$CVI_CONFIG_FILE" ]; then
        if [ ! -r "$CVI_CONFIG_FILE" ]; then
            echo "[cvi] WARNING: config file exists but is not readable: $CVI_CONFIG_FILE (using defaults)" >&2
            return 0
        fi
        while IFS= read -r line; do
            key="${line%%=*}"
            value="${line#*=}"
            case "$key" in
                CVI_ENABLED)      CVI_ENABLED="${value:-on}" ;;
                SPEECH_RATE)      SPEECH_RATE="${value:-200}" ;;
                VOICE_LANG)       VOICE_LANG="${value:-ja}" ;;
                VOICE_EN)         VOICE_EN="${value:-Samantha}" ;;
                VOICE_JA)         VOICE_JA="${value:-system}" ;;
                AUTO_DETECT_LANG) AUTO_DETECT_LANG="${value:-false}" ;;
                VOICE_MODE)       VOICE_MODE="${value:-auto}" ;;
                VOICE_FIXED)      VOICE_FIXED="$value" ;;
                ENGLISH_PRACTICE) ENGLISH_PRACTICE="${value:-off}" ;;
            esac
        done < <(grep -v '^#' "$CVI_CONFIG_FILE" | grep -v '^$')
    fi
}

load_response_lang() {
    local settings_file="$HOME/.claude/settings.json"

    RESPONSE_LANG="japanese"
    if [ -f "$settings_file" ]; then
        local configured_language
        configured_language=$(jq -r '.language // empty' "$settings_file" 2>/dev/null) || configured_language=""
        if [ -n "$configured_language" ]; then
            RESPONSE_LANG="$configured_language"
        else
            echo "[cvi] WARNING: could not parse 'language' from $settings_file, defaulting to 'japanese'" >&2
        fi
    else
        echo "[cvi] WARNING: settings file not found: $settings_file, defaulting to 'japanese'" >&2
    fi
}

# Returns 0 if sandbox is enabled, 1 if disabled or unknown.
is_sandbox_enabled() {
    local settings_local="$HOME/.claude/settings.local.json"
    local settings_global="$HOME/.claude/settings.json"
    local sandbox_enabled

    # Priority 1: Check settings.local.json
    if [ -f "$settings_local" ]; then
        sandbox_enabled=$(jq -r '.sandbox.enabled // "null"' "$settings_local" 2>/dev/null || echo "null")
        if [ "$sandbox_enabled" = "true" ]; then
            return 0  # Sandbox enabled
        elif [ "$sandbox_enabled" = "false" ]; then
            return 1  # Sandbox explicitly disabled
        fi
    fi

    # Priority 2: Check settings.json
    if [ -f "$settings_global" ]; then
        sandbox_enabled=$(jq -r '.sandbox.enabled // "null"' "$settings_global" 2>/dev/null || echo "null")
        if [ "$sandbox_enabled" = "true" ]; then
            return 0  # Sandbox enabled
        fi
    fi

    # Default: Assume disabled if not specified
    # Rationale: Prioritize CVI notifications over sandbox detection failures
    # If sandbox state is unknown, allow CVI checks to run to avoid missing notifications
    return 1
}

# Returns 0 if a /cvi:speak call (Skill or MCP tool) is recorded in the transcript.
is_speak_called() {
    local transcript="$1"
    grep -q '"type":"tool_use"' "$transcript" 2>/dev/null && \
        grep -qE '"skill":"cvi:speak"|"name":"mcp__(plugin_cvi_)?cvi-voice__speak"' \
            "$transcript" 2>/dev/null
}
