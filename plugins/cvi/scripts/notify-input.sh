#!/bin/bash
set -euo pipefail

# Load shared config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config.sh" || { echo "[cvi] Failed to source lib/config.sh" >&2; exit 1; }
load_cvi_config

# Exit early if disabled
if [ "$CVI_ENABLED" = "off" ]; then
    exit 0
fi

# Get project root directory
PROJECT_ROOT=$(pwd)

# Generate project-specific hash (16 characters)
PROJECT_HASH=$(echo "$PROJECT_ROOT" | md5 | cut -c1-16)

# Project-specific lock directory
LOCK_DIR="/tmp/claude/cvi/${PROJECT_HASH}.lock"

# If lock directory exists, voice is playing, skip this notification
if [ -d "$LOCK_DIR" ]; then
    exit 0
fi

# Play Glass notification sound
afplay -v 1.0 /System/Library/Sounds/Glass.aiff &

# Read message aloud with volume control (60% = 0.6)
TEMP_AUDIO="/tmp/claude_input_$$.aiff"

# Set message based on language (fallback message)
if [ "$VOICE_LANG" = "en" ]; then
    MSG="Please confirm"
else
    MSG="確認をお願いします"
fi

# Detect language if AUTO_DETECT_LANG is enabled
if [ "$AUTO_DETECT_LANG" = "true" ]; then
    if echo "$MSG" | grep -q '[ぁ-んァ-ヶー一-龠]'; then
        DETECTED_LANG="ja"
    else
        DETECTED_LANG="en"
    fi
else
    # Use configured language
    DETECTED_LANG="$VOICE_LANG"
fi

# Select voice based on mode and detected language
if [ "$VOICE_MODE" = "fixed" ] && [ -n "$VOICE_FIXED" ]; then
    # Fixed mode: use specified voice for all languages
    SELECTED_VOICE="$VOICE_FIXED"
else
    # Auto mode: select voice based on detected language
    if [ "$DETECTED_LANG" = "ja" ]; then
        SELECTED_VOICE="$VOICE_JA"
    else
        SELECTED_VOICE="$VOICE_EN"
    fi
fi

# Generate audio with selected voice
if [ "$SELECTED_VOICE" = "system" ]; then
    # Use system default (no -v flag)
    say -r "$SPEECH_RATE" -o "$TEMP_AUDIO" "$MSG"
else
    # Use specific voice
    say -v "$SELECTED_VOICE" -r "$SPEECH_RATE" -o "$TEMP_AUDIO" "$MSG"
fi

# Play with 60% volume and cleanup in background
(afplay -v 0.6 "$TEMP_AUDIO" && rm -f "$TEMP_AUDIO") &
