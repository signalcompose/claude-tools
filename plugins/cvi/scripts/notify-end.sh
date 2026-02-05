#!/bin/bash

# Read hook input from stdin
INPUT=$(cat)

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

# Get current session directory name
SESSION_DIR=$(basename "$(pwd)")

# Extract transcript path
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path')

# NOTE: Stop hook executes BEFORE the current response is written to transcript.
# This is a known Claude Code limitation. For reliable voice notification,
# use /cvi:speak command instead of relying solely on this hook.

# If transcript path exists, extract latest assistant message
if [ -f "$TRANSCRIPT_PATH" ]; then
    # Search ALL assistant entries for [VOICE] tag in text content (excludes thinking blocks)
    # This handles cases where the last entry has no text (e.g., only tool calls)
    VOICE_CONTENT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | \
        jq -r '.message.content[] | select(.type == "text") | .text' 2>/dev/null | \
        grep -oE '\[VOICE\][^\[]*\[/VOICE\]' | tail -1)

    if [ -n "$VOICE_CONTENT" ]; then
        # [VOICE] tag found - extract the message
        MSG=$(echo "$VOICE_CONTENT" | sed 's/\[VOICE\]//; s/\[\/VOICE\]//')
    else
        # No [VOICE] tag - get text from last assistant entry with text content
        LAST_TEXT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | \
            jq -r '.message.content[] | select(.type == "text") | .text' 2>/dev/null | \
            tail -1)
        MSG=$(echo "$LAST_TEXT" | tr '\n' ' ' | cut -c1-200)
    fi

    # Fallback message if no message found (language-aware)
    if [ -z "$MSG" ]; then
        # Load language setting
        VOICE_LANG=$(grep "^VOICE_LANG=" "$HOME/.cvi/config" 2>/dev/null | cut -d'=' -f2)
        VOICE_LANG=${VOICE_LANG:-ja}
        if [ "$VOICE_LANG" = "en" ]; then
            MSG="Task completed"
        else
            MSG="タスクが完了しました"
        fi
    fi
else
    # Load language setting
    VOICE_LANG=$(grep "^VOICE_LANG=" "$HOME/.cvi/config" 2>/dev/null | cut -d'=' -f2)
    VOICE_LANG=${VOICE_LANG:-ja}
    if [ "$VOICE_LANG" = "en" ]; then
        MSG="Task completed"
    else
        MSG="タスクが完了しました"
    fi
fi

# Display macOS notification
osascript -e "display notification \"$MSG\" with title \"ClaudeCode ($SESSION_DIR) Task Done\""

# Play Glass sound at full volume
afplay -v 1.0 /System/Library/Sounds/Glass.aiff &

# Read message aloud with volume control (60% = 0.6)
TEMP_AUDIO="/tmp/claude_notify_$$.aiff"

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

# === 完全に独立したバックグラウンド実行 ===
# 音声再生とクリーンアップを独立したプロセスとして実行
# スクリプト本体は即座に終了し、Claude Codeをブロックしない

# ロックファイルで音声再生中を示す
LOCK_FILE="/tmp/cvi_speaking.lock"
touch "$LOCK_FILE"

# 音声再生 + 一時ファイルとロックファイルの削除
(afplay -v 0.6 "$TEMP_AUDIO" && rm -f "$TEMP_AUDIO" "$LOCK_FILE") &
