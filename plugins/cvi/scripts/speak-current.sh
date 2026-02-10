#!/bin/bash

# CVI Speak Current - PostToolUse hook handler
# Reads ~/.cvi/speak-current and plays audio immediately
# Called by PostToolUse hook after Skill tool execution

CURRENT_FILE="$HOME/.cvi/speak-current"

# No current file = nothing to speak
[ ! -f "$CURRENT_FILE" ] && exit 0

# Read message
if ! MSG=$(cat "$CURRENT_FILE" 2>/dev/null); then
    echo "Error: Failed to read current file $CURRENT_FILE" >&2
    exit 1
fi

# Delete file immediately (mark as processed)
rm -f "$CURRENT_FILE" || echo "Warning: Failed to delete $CURRENT_FILE" >&2
[ -z "$MSG" ] && exit 0

# Check CVI enabled
CONFIG_FILE="$HOME/.cvi/config"
if [ -f "$CONFIG_FILE" ]; then
    CVI_ENABLED=$(grep "^CVI_ENABLED=" "$CONFIG_FILE" | cut -d'=' -f2)
fi
CVI_ENABLED=${CVI_ENABLED:-on}
[ "$CVI_ENABLED" = "off" ] && exit 0

# Load CVI config
if [ -f "$CONFIG_FILE" ]; then
    SPEECH_RATE=$(grep "^SPEECH_RATE=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_LANG=$(grep "^VOICE_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_EN=$(grep "^VOICE_EN=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_JA=$(grep "^VOICE_JA=" "$CONFIG_FILE" | cut -d'=' -f2)
    AUTO_DETECT_LANG=$(grep "^AUTO_DETECT_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_MODE=$(grep "^VOICE_MODE=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_FIXED=$(grep "^VOICE_FIXED=" "$CONFIG_FILE" | cut -d'=' -f2)
fi

SPEECH_RATE=${SPEECH_RATE:-200}
VOICE_LANG=${VOICE_LANG:-ja}
VOICE_EN=${VOICE_EN:-Samantha}
VOICE_JA=${VOICE_JA:-system}
AUTO_DETECT_LANG=${AUTO_DETECT_LANG:-false}
VOICE_MODE=${VOICE_MODE:-auto}

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

# Wait for say to finish and check for errors (say is the critical command)
wait "$SAY_PID" 2>/dev/null
SAY_EXIT=$?
if [ $SAY_EXIT -ne 0 ]; then
    echo "Warning: say command failed (exit $SAY_EXIT), voice='${SELECTED_VOICE}', rate='${SPEECH_RATE}'" >&2
fi
