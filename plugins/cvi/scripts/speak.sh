#!/bin/bash

# CVI Speak Script - Reporter Agent Architecture
# Directly executes voice notification (no queue file).
# Called by Reporter Agent via SendMessage.

# Get the text to speak from arguments
MSG="$*"

if [ -z "$MSG" ]; then
    echo "Error: No text provided"
    echo "Usage: speak.sh <text to speak>"
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

# Set default values first
SPEECH_RATE=200
VOICE_LANG=ja
VOICE_EN=Samantha
VOICE_JA=system
AUTO_DETECT_LANG=false
VOICE_MODE=auto

# Load CVI config (override defaults if non-empty)
if [ -f "$CONFIG_FILE" ]; then
    CONFIG_SPEECH_RATE=$(grep "^SPEECH_RATE=" "$CONFIG_FILE" | cut -d'=' -f2)
    CONFIG_VOICE_LANG=$(grep "^VOICE_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    CONFIG_VOICE_EN=$(grep "^VOICE_EN=" "$CONFIG_FILE" | cut -d'=' -f2)
    CONFIG_VOICE_JA=$(grep "^VOICE_JA=" "$CONFIG_FILE" | cut -d'=' -f2)
    CONFIG_AUTO_DETECT_LANG=$(grep "^AUTO_DETECT_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    CONFIG_VOICE_MODE=$(grep "^VOICE_MODE=" "$CONFIG_FILE" | cut -d'=' -f2)
    CONFIG_VOICE_FIXED=$(grep "^VOICE_FIXED=" "$CONFIG_FILE" | cut -d'=' -f2)

    # Override defaults only if non-empty
    [ -n "$CONFIG_SPEECH_RATE" ] && SPEECH_RATE="$CONFIG_SPEECH_RATE"
    [ -n "$CONFIG_VOICE_LANG" ] && VOICE_LANG="$CONFIG_VOICE_LANG"
    [ -n "$CONFIG_VOICE_EN" ] && VOICE_EN="$CONFIG_VOICE_EN"
    [ -n "$CONFIG_VOICE_JA" ] && VOICE_JA="$CONFIG_VOICE_JA"
    [ -n "$CONFIG_AUTO_DETECT_LANG" ] && AUTO_DETECT_LANG="$CONFIG_AUTO_DETECT_LANG"
    [ -n "$CONFIG_VOICE_MODE" ] && VOICE_MODE="$CONFIG_VOICE_MODE"
    [ -n "$CONFIG_VOICE_FIXED" ] && VOICE_FIXED="$CONFIG_VOICE_FIXED"
fi

# Validate SPEECH_RATE is numeric
if ! [[ "$SPEECH_RATE" =~ ^[0-9]+$ ]]; then
    echo "Warning: Invalid SPEECH_RATE='$SPEECH_RATE' in config, using default 200" >&2
    SPEECH_RATE=200
fi

# Detect language if AUTO_DETECT_LANG is enabled, otherwise use configured VOICE_LANG
if [ "$AUTO_DETECT_LANG" = "true" ]; then
    if echo "$MSG" | grep -q '[ぁ-んァ-ヶー一-龠]'; then
        DETECTED_LANG="ja"
    else
        DETECTED_LANG="en"
    fi
else
    DETECTED_LANG="$VOICE_LANG"
fi

# Select voice based on mode and detected language
if [ "$VOICE_MODE" = "fixed" ] && [ -n "$VOICE_FIXED" ]; then
    SELECTED_VOICE="$VOICE_FIXED"
elif [ "$DETECTED_LANG" = "ja" ]; then
    SELECTED_VOICE="$VOICE_JA"
else
    SELECTED_VOICE="$VOICE_EN"
fi

# Sanitize message (escape backslashes, double quotes, and replace newlines with spaces)
SAFE_MSG=$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')

# Execute audio (runs outside sandbox, so osascript/afplay/say are not blocked)
SESSION_DIR=$(basename "$(pwd)")
osascript -e "display notification \"$SAFE_MSG\" with title \"ClaudeCode ($SESSION_DIR) Task Done\"" 2>/dev/null &
afplay /System/Library/Sounds/Glass.aiff 2>/dev/null &
if [ "$SELECTED_VOICE" = "system" ]; then
    say -r "$SPEECH_RATE" -- "$SAFE_MSG" 2>/dev/null &
else
    say -v "$SELECTED_VOICE" -r "$SPEECH_RATE" -- "$SAFE_MSG" 2>/dev/null &
fi
SAY_PID=$!

# Wait for say to finish and check for errors
# Note: Only checking exit code of the critical 'say' command.
# osascript/afplay failures are intentionally ignored (non-critical).
wait "$SAY_PID" 2>/dev/null
SAY_EXIT=$?
if [ $SAY_EXIT -ne 0 ]; then
    echo "Warning: say command failed (exit $SAY_EXIT), voice='${SELECTED_VOICE}', rate='${SPEECH_RATE}'" >&2
    exit 1
fi

echo "Speaking: $MSG"
