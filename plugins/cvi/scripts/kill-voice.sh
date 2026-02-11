#!/bin/bash

# ユーザーが新しい指示を入力した時に実行される
# 現在のプロジェクトで再生中の音声のみを停止する

# Error logging
ERROR_LOG="$HOME/.cvi/error.log"

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null
    echo "[${timestamp}] [kill-voice.sh] ${message}" >> "$ERROR_LOG"
}

# Debug mode (set DEBUG=1 to enable)
DEBUG=${DEBUG:-0}
debug_log() {
    if [ "$DEBUG" -eq 1 ]; then
        echo "[kill-voice.sh] $*" >&2
    fi
}

# Get project root directory
PROJECT_ROOT=$(pwd)
debug_log "Project root: $PROJECT_ROOT"

# Generate project-specific hash (16 characters)
PROJECT_HASH=$(echo "$PROJECT_ROOT" | md5 | cut -c1-16)
debug_log "Project hash: $PROJECT_HASH"

# Project-specific lock directory and PID file
LOCK_DIR="/tmp/cvi/${PROJECT_HASH}.lock"
PID_FILE="${LOCK_DIR}/pid"

# If lock directory exists, read PID and kill the specific process
if [ -d "$LOCK_DIR" ]; then
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE" 2>/dev/null)

        # Only kill if we have a numeric PID
        if [[ "$PID" =~ ^[0-9]+$ ]]; then
            # Check if process exists before killing
            if ps -p "$PID" > /dev/null 2>&1; then
                debug_log "Killing process: $PID"
                kill "$PID" 2>/dev/null || true
                debug_log "Process killed"
            else
                debug_log "Process $PID does not exist (already terminated)"
            fi
        else
            debug_log "Invalid PID value: $PID (expected numeric)"
        fi
        # Cleanup PID file
        rm -f "$PID_FILE"
        debug_log "Cleaned up PID file"
    else
        debug_log "Lock directory exists but no PID file found"
    fi

    # Remove lock directory (use rm -rf to handle race condition)
    rm -rf "$LOCK_DIR" 2>/dev/null
    debug_log "Cleaned up lock directory"
else
    debug_log "No lock directory found, nothing to kill"
fi

# Note: Glass sound (afplay) is short and doesn't need to be killed
# Note: Temporary audio files are cleaned up by speak-sync.sh
