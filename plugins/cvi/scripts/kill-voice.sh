#!/bin/bash

# ユーザーが新しい指示を入力した時に実行される
# 現在のプロジェクトで再生中の音声のみを停止する

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

# Project-specific PID and lock files
LOCK_DIR="/tmp/cvi"
PID_FILE="${LOCK_DIR}/${PROJECT_HASH}.lock.pid"
LOCK_FILE="${LOCK_DIR}/${PROJECT_HASH}.lock"

# If PID file exists, kill the specific process
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE" 2>/dev/null)

    # Retry once if initializing (handle race condition)
    if [ "$PID" = "INITIALIZING" ]; then
        debug_log "Process is initializing, retrying after 50ms"
        sleep 0.05  # 50ms
        PID=$(cat "$PID_FILE" 2>/dev/null)
    fi

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
        # Cleanup PID file and lock file
        rm -f "$PID_FILE"
        rm -f "$LOCK_FILE"
        debug_log "Cleaned up PID file and lock file"
    else
        debug_log "Invalid PID value: $PID (expected numeric)"
    fi
else
    debug_log "No PID file found, nothing to kill"
fi

# Note: Glass sound (afplay) is short and doesn't need to be killed
# Note: Temporary audio files are cleaned up by speak-sync.sh
