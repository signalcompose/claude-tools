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

# Project-specific lock directory and PID file
LOCK_DIR="/tmp/cvi/${PROJECT_HASH}.lock"
PID_FILE="${LOCK_DIR}/pid"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Acquire project-specific lock using mkdir (atomic operation)
debug_log "Acquiring lock: $LOCK_DIR"

# Try to acquire lock (wait up to 30 seconds)
TIMEOUT=30
START_TIME=$(date +%s)
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        debug_log "Failed to acquire lock within ${TIMEOUT} seconds"
        log_error "Lock timeout: Another voice notification in progress (project: $PROJECT_HASH)"
        echo "Error: Another voice notification is already in progress for this project" >&2
        exit 1
    fi
    sleep 0.1
done

# Lock acquired, set up cleanup trap
trap 'rm -f "$PID_FILE"; rm -rf "$LOCK_DIR" 2>/dev/null' EXIT SIGTERM SIGINT SIGHUP
debug_log "Lock acquired, calling speak-sync.sh"

# Execute speak-sync.sh in background and record PID
"${SCRIPT_DIR}/speak-sync.sh" "$TEXT" &
SAY_PID=$!
echo "$SAY_PID" > "$PID_FILE"
debug_log "speak-sync.sh PID: $SAY_PID"

# Wait for completion
wait $SAY_PID
EXIT_CODE=$?
debug_log "speak-sync.sh completed with exit code: $EXIT_CODE"

# Cleanup is handled by trap
debug_log "Lock will be released by trap, final exit code: $EXIT_CODE"
exit $EXIT_CODE
