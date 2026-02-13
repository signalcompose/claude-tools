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

# Read sandbox.enabled from a single JSON settings file.
# Args: $1 = file path
# Prints: "true", "false", or "unknown"
_read_sandbox_setting() {
    local file="$1"

    [ -f "$file" ] || { echo "unknown"; return; }

    if ! command -v jq &> /dev/null; then
        log_error "jq command not found - cannot parse $(basename "$file")"
        echo "unknown"
        return
    fi

    local jq_output
    if ! jq_output=$(jq -r '.sandbox.enabled // "null"' "$file" 2>&1); then
        log_error "jq failed to parse $file: $jq_output"
        echo "unknown"
        return
    fi

    if [ "$jq_output" = "true" ] || [ "$jq_output" = "false" ]; then
        echo "$jq_output"
    else
        echo "unknown"
    fi
}

# Detect if sandbox is enabled in Claude Code settings.
# Returns: 0 if sandbox explicitly enabled, 1 otherwise.
# Priority: settings.local.json > settings.json > default (disabled).
# Unknown states default to "disabled" to prioritize CVI functionality.
# Rationale: False negatives (CVI runs in sandbox and may fail) are acceptable,
#            but false positives (blocking CVI when sandbox is off) hurt UX.
is_sandbox_enabled() {
    local settings_files=(
        "$HOME/.claude/settings.local.json"
        "$HOME/.claude/settings.json"
    )

    local result
    for file in "${settings_files[@]}"; do
        result=$(_read_sandbox_setting "$file")
        if [ "$result" = "true" ]; then
            return 0
        elif [ "$result" = "false" ]; then
            return 1
        fi
        # "unknown" -> continue to next file
    done

    # Default: disabled (no definitive setting found)
    return 1
}

# Skip audio commands if sandbox is enabled
if is_sandbox_enabled; then
    # Sandbox is enabled, skip audio playback
    # Output expected format for hook compatibility
    echo "Speaking: $MSG"
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

# Generate speech audio file (works in sandboxed/non-GUI contexts)
# Using say -o instead of osascript to avoid GUI session dependency
# Use /tmp/ directly (same pattern as notify-input.sh)
TEMP_AUDIO="/tmp/claude_speak_$$.aiff"

# Ensure cleanup on exit (including signals)
trap 'rm -f "$TEMP_AUDIO"' EXIT

if [ "$SELECTED_VOICE" = "system" ]; then
    # Use system default (no -v flag)
    # Use printf + pipe to prevent command injection (preserve security pattern)
    if ! printf '%s' "$MSG" | say -r "$SPEECH_RATE" -o "$TEMP_AUDIO" -f -; then
        log_error "say command failed (system voice, rate=$SPEECH_RATE)"
        rm -f "$TEMP_AUDIO"
        exit 1
    fi
else
    # Use specific voice
    # Use printf + pipe to prevent command injection (preserve security pattern)
    if ! printf '%s' "$MSG" | say -v "$SELECTED_VOICE" -r "$SPEECH_RATE" -o "$TEMP_AUDIO" -f -; then
        log_error "say command failed (voice=$SELECTED_VOICE, rate=$SPEECH_RATE)"
        rm -f "$TEMP_AUDIO"
        exit 1
    fi
fi

# Play audio file synchronously (foreground - waits for completion)
if ! afplay "$TEMP_AUDIO"; then
    log_error "afplay command failed for $TEMP_AUDIO"
    rm -f "$TEMP_AUDIO"
    exit 1
fi

# Cleanup temporary file
rm -f "$TEMP_AUDIO"

# Only print after speech completes
echo "Speaking: $MSG"
