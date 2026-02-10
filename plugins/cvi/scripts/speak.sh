#!/bin/bash

# CVI Speak Script - PostToolUse hook based
# Writes message to current file for immediate playback

MSG="$*"

if [ -z "$MSG" ]; then
    echo "Error: No text provided"
    echo "Usage: speak.sh <text to speak>"
    exit 1
fi

# Check CVI enabled
CONFIG_FILE="$HOME/.cvi/config"
if [ -f "$CONFIG_FILE" ]; then
    CVI_ENABLED=$(grep "^CVI_ENABLED=" "$CONFIG_FILE" | cut -d'=' -f2)
fi
CVI_ENABLED=${CVI_ENABLED:-on}

if [ "$CVI_ENABLED" = "off" ]; then
    echo "CVI is disabled. Enable with: /cvi:state on"
    exit 0
fi

# Write to current file (not queue)
mkdir -p "$HOME/.cvi"
if ! echo "$MSG" > "$HOME/.cvi/speak-current"; then
    echo "Error: Failed to write message to ~/.cvi/speak-current"
    exit 1
fi

echo "Speaking: $MSG"
