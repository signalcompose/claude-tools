#!/bin/bash

# CVI Post-Speak Hook Handler
# Triggered by PostToolUse hook when /cvi:speak is called
# Ensures synchronous voice playback with proper project isolation

set -euo pipefail

# Error logging
ERROR_LOG="$HOME/.cvi/error.log"

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null
    echo "[${timestamp}] [post-speak.sh] ${message}" >> "$ERROR_LOG"
}

# Debug mode (set DEBUG=1 to enable)
DEBUG=${DEBUG:-0}
debug_log() {
    if [ "$DEBUG" -eq 1 ]; then
        echo "[post-speak.sh] $*" >&2
    fi
}

# Read hook input from STDIN
HOOK_INPUT=$(cat)
debug_log "Hook input received: $HOOK_INPUT"

# Extract text from hook input (JSON)
# Expected format: {"tool": "Skill", "args": {"skill": "cvi:speak", "args": "<text>"}}
TEXT=$(echo "$HOOK_INPUT" | jq -r '.args.args // empty' 2>/dev/null || echo "")

# If text extraction failed, try alternative format
if [ -z "$TEXT" ]; then
    debug_log "Failed to extract text from .args.args, trying alternative formats"
    # Try direct args field
    TEXT=$(echo "$HOOK_INPUT" | jq -r '.args // empty' 2>/dev/null || echo "")
fi

# Validate text
if [ -z "$TEXT" ] || [ "$TEXT" = "null" ]; then
    debug_log "Error: No text to speak"
    log_error "No text provided to /cvi:speak"
    echo "Error: No text provided to /cvi:speak" >&2
    exit 1
fi

debug_log "Text to speak: $TEXT"

# Get project root directory
PROJECT_ROOT=$(pwd)
debug_log "Project root: $PROJECT_ROOT"

# Generate project-specific hash (16 characters)
PROJECT_HASH=$(echo "$PROJECT_ROOT" | md5 | cut -c1-16)
debug_log "Project hash: $PROJECT_HASH"

# Project-specific lock file and PID file
LOCK_DIR="/tmp/cvi"
LOCK_FILE="${LOCK_DIR}/${PROJECT_HASH}.lock"
PID_FILE="${LOCK_DIR}/${PROJECT_HASH}.lock.pid"

# Create lock directory if it doesn't exist
mkdir -p "$LOCK_DIR"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Acquire project-specific lock and execute speak-sync.sh
debug_log "Acquiring lock: $LOCK_FILE"
(
    # Try to acquire lock (wait up to 30 seconds)
    if ! flock -w 30 200; then
        debug_log "Failed to acquire lock within 30 seconds"
        log_error "Lock timeout: Another voice notification in progress (project: $PROJECT_HASH)"
        echo "Error: Another voice notification is already in progress for this project" >&2
        exit 1
    fi

    debug_log "Lock acquired, calling speak-sync.sh"

    # Execute speak-sync.sh in background and record PID
    # Use atomic write (temp file + mv) to prevent race condition with kill-voice.sh
    echo "INITIALIZING" > "${PID_FILE}.init"
    mv "${PID_FILE}.init" "$PID_FILE"
    "${SCRIPT_DIR}/speak-sync.sh" "$TEXT" &
    SAY_PID=$!
    echo "$SAY_PID" > "${PID_FILE}.tmp"
    mv "${PID_FILE}.tmp" "$PID_FILE"
    debug_log "speak-sync.sh PID: $SAY_PID"

    # Wait for completion
    wait $SAY_PID
    EXIT_CODE=$?
    debug_log "speak-sync.sh completed with exit code: $EXIT_CODE"

    # Cleanup PID file
    rm -f "$PID_FILE"
    debug_log "Cleaned up PID file"

    exit $EXIT_CODE
) 200>"$LOCK_FILE"

EXIT_CODE=$?
debug_log "Lock released, final exit code: $EXIT_CODE"
exit $EXIT_CODE
