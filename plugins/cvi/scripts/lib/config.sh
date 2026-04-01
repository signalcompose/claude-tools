#!/bin/bash
# CVI shared config loader
# Usage: source "$(dirname "${BASH_SOURCE[0]}")/lib/config.sh" && load_cvi_config

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

    if [ -f "$CVI_CONFIG_FILE" ] && [ -r "$CVI_CONFIG_FILE" ]; then
        while IFS='=' read -r key value; do
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
