#!/bin/bash

# CVI Speak-Sync Script
# Synchronous voice playback with configuration support
# Requires dangerouslyDisableSandbox: true for audio API access

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

# Set defaults (handle empty strings from malformed config)
[ -z "$SPEECH_RATE" ] && SPEECH_RATE=200
[ -z "$VOICE_LANG" ] && VOICE_LANG=ja
[ -z "$VOICE_EN" ] && VOICE_EN=Samantha
[ -z "$VOICE_JA" ] && VOICE_JA=system
[ -z "$AUTO_DETECT_LANG" ] && AUTO_DETECT_LANG=false
[ -z "$VOICE_MODE" ] && VOICE_MODE=auto

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

# Display macOS notification (background - non-blocking)
# Use separate -e arguments to prevent command injection
osascript \
    -e 'on run argv' \
    -e '  set msg to item 1 of argv' \
    -e '  set sessionDir to item 2 of argv' \
    -e '  display notification msg with title "ClaudeCode - " & sessionDir & " - Task Done"' \
    -e 'end run' \
    -- "$MSG" "$SESSION_DIR" &

# Play Glass sound to indicate completion (background - non-blocking)
afplay /System/Library/Sounds/Glass.aiff &

# Speak text synchronously (foreground - waits for completion)
# Note: requires dangerouslyDisableSandbox: true for audio API access
if [ "$SELECTED_VOICE" = "system" ]; then
    # Use system default voice (no -v flag)
    say -r "$SPEECH_RATE" "$MSG"
else
    # Use configured voice
    say -r "$SPEECH_RATE" -v "$SELECTED_VOICE" "$MSG"
fi

# Output expected format for hook compatibility
echo "Speaking: $MSG"
