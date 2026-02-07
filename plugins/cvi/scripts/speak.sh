#!/bin/bash

# CVI Speak Script - Queue-based (sandbox-compatible)
# Writes message to queue file instead of directly playing audio.
# Audio playback is handled by PostToolUse hook (speak-from-queue.sh)
# which runs outside the sandbox.

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

# Ensure ~/.cvi/ directory exists
if ! mkdir -p "$HOME/.cvi" 2>/dev/null; then
    echo "Error: Failed to create directory $HOME/.cvi" >&2
    exit 1
fi

# Write message to queue file (sandbox allows ~/.cvi/ writes per plugin permissions)
if ! echo "$MSG" > "$HOME/.cvi/speak-queue" 2>/dev/null; then
    echo "Error: Failed to write to ~/.cvi/speak-queue" >&2
    exit 1
fi

echo "Speaking: $MSG"
