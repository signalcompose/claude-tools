#!/bin/bash

# Check if CVI is enabled
CONFIG_FILE="$HOME/.cvi/config"
if [ -f "$CONFIG_FILE" ]; then
    CVI_ENABLED=$(grep "^CVI_ENABLED=" "$CONFIG_FILE" | cut -d'=' -f2)
fi
CVI_ENABLED=${CVI_ENABLED:-on}

# Exit early if disabled
if [ "$CVI_ENABLED" = "off" ]; then
    exit 0
fi

# Check if another voice notification is already playing
LOCK_FILE="/tmp/cvi_speaking.lock"
if [ -f "$LOCK_FILE" ]; then
    # Another voice is speaking, skip this notification
    exit 0
fi

# Play Glass notification sound
afplay -v 1.0 /System/Library/Sounds/Glass.aiff &

# Read message aloud with volume control (60% = 0.6)
TEMP_AUDIO="/tmp/claude_input_$$.aiff"

# Load configuration from file
CONFIG_FILE="$HOME/.cvi/config"
if [ -f "$CONFIG_FILE" ]; then
    SPEECH_RATE=$(grep "^SPEECH_RATE=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_LANG=$(grep "^VOICE_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_EN=$(grep "^VOICE_EN=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_JA=$(grep "^VOICE_JA=" "$CONFIG_FILE" | cut -d'=' -f2)
    AUTO_DETECT_LANG=$(grep "^AUTO_DETECT_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_MODE=$(grep "^VOICE_MODE=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_FIXED=$(grep "^VOICE_FIXED=" "$CONFIG_FILE" | cut -d'=' -f2)
fi

# Set defaults
SPEECH_RATE=${SPEECH_RATE:-200}
VOICE_LANG=${VOICE_LANG:-ja}
VOICE_EN=${VOICE_EN:-Samantha}
VOICE_JA=${VOICE_JA:-system}
AUTO_DETECT_LANG=${AUTO_DETECT_LANG:-false}
VOICE_MODE=${VOICE_MODE:-auto}

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
