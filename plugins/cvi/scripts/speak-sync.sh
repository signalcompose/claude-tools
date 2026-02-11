#!/bin/bash

# CVI Speak-Sync Script
# Synchronous voice playback with configuration support
# Based on speak.sh but executes 'say' in foreground for blocking behavior

set -euo pipefail

# Error logging
ERROR_LOG="$HOME/.cvi/error.log"

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null
    echo "[${timestamp}] [speak-sync.sh] ${message}" >> "$ERROR_LOG"
}

# Get the text to speak from arguments
MSG="$*"

if [ -z "$MSG" ]; then
    log_error "No text provided"
    echo "Error: No text provided"
    echo "Usage: speak-sync.sh <text to speak>"
    exit 1
fi

# Check if CVI is enabled
CONFIG_FILE="$HOME/.cvi/config"
if [ -f "$CONFIG_FILE" ]; then
    CVI_ENABLED=$(grep "^CVI_ENABLED=" "$CONFIG_FILE" | cut -d'=' -f2)
fi
CVI_ENABLED=${CVI_ENABLED:-on}

# Exit early if disabled
if [ "$CVI_ENABLED" = "off" ]; then
    echo "CVI is disabled. Enable with: /cvi:state on"
    exit 0
fi

# Load configuration from file
if [ -f "$CONFIG_FILE" ]; then
    SPEECH_RATE=$(grep "^SPEECH_RATE=" "$CONFIG_FILE" | cut -d'=' -f2- || echo "")
    VOICE_LANG=$(grep "^VOICE_LANG=" "$CONFIG_FILE" | cut -d'=' -f2- || echo "")
    VOICE_EN=$(grep "^VOICE_EN=" "$CONFIG_FILE" | cut -d'=' -f2- || echo "")
    VOICE_JA=$(grep "^VOICE_JA=" "$CONFIG_FILE" | cut -d'=' -f2- || echo "")
    AUTO_DETECT_LANG=$(grep "^AUTO_DETECT_LANG=" "$CONFIG_FILE" | cut -d'=' -f2- || echo "")
    VOICE_MODE=$(grep "^VOICE_MODE=" "$CONFIG_FILE" | cut -d'=' -f2- || echo "")
    VOICE_FIXED=$(grep "^VOICE_FIXED=" "$CONFIG_FILE" | cut -d'=' -f2- || echo "")
fi

# Set defaults
SPEECH_RATE=${SPEECH_RATE:-200}
VOICE_LANG=${VOICE_LANG:-ja}
VOICE_EN=${VOICE_EN:-Samantha}
VOICE_JA=${VOICE_JA:-system}
AUTO_DETECT_LANG=${AUTO_DETECT_LANG:-false}
VOICE_MODE=${VOICE_MODE:-auto}

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

# Get current session directory name for notification
SESSION_DIR=$(basename "$(pwd)")

# Escape special characters for AppleScript to prevent command injection
# Escape backslashes first, then double quotes
SAFE_MSG=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')
SAFE_SESSION_DIR=$(printf '%s' "$SESSION_DIR" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Display macOS notification (background - non-blocking)
osascript -e "display notification \"$SAFE_MSG\" with title \"ClaudeCode ($SAFE_SESSION_DIR) Task Done\"" &

# Play Glass sound to indicate completion (background - non-blocking)
afplay /System/Library/Sounds/Glass.aiff &

# Speak synchronously in FOREGROUND (blocking - waits for completion)
# This is the key difference from speak.sh
# Use printf + pipe to prevent command injection
if [ "$SELECTED_VOICE" = "system" ]; then
    # Use system default (no -v flag)
    if ! printf '%s' "$MSG" | say -r "$SPEECH_RATE" -f -; then
        log_error "say command failed (system voice, rate=$SPEECH_RATE)"
        exit 1
    fi
else
    # Use specific voice
    if ! printf '%s' "$MSG" | say -v "$SELECTED_VOICE" -r "$SPEECH_RATE" -f -; then
        log_error "say command failed (voice=$SELECTED_VOICE, rate=$SPEECH_RATE)"
        exit 1
    fi
fi

# Only print after speech completes
echo "Speaking: $MSG"
