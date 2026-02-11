#!/bin/bash
# SessionStart hook: Clean up stale lock files from crashed/terminated sessions
# This prevents hung locks from blocking future voice notifications

# Debug mode (set DEBUG=1 to enable)
DEBUG=${DEBUG:-0}
debug_log() {
    if [ "$DEBUG" -eq 1 ]; then
        echo "[cleanup-stale-locks.sh] $*" >&2
    fi
}

LOCK_DIR="/tmp/cvi"
ERROR_LOG="$HOME/.cvi/error.log"

# Exit early if lock directory doesn't exist
if [ ! -d "$LOCK_DIR" ]; then
    debug_log "Lock directory doesn't exist, nothing to clean up"
    exit 0
fi

# Log with timestamp
log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] ${message}" >> "$ERROR_LOG"
}

# Ensure error log directory exists
mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null

debug_log "Starting stale lock cleanup in $LOCK_DIR"

CHECKED=0
# Use temp file for counting cleaned locks (subshell variable issue)
CLEANED_COUNT_FILE="/tmp/cvi/cleanup_count.$$"
echo "0" > "$CLEANED_COUNT_FILE"

# Check each lock file
for LOCK_FILE in "$LOCK_DIR"/*.lock; do
    # Skip if no lock files found (glob didn't match)
    [ -e "$LOCK_FILE" ] || continue

    CHECKED=$((CHECKED + 1))

    # Extract project hash from lock filename
    LOCK_FILENAME=$(basename "$LOCK_FILE")
    PROJECT_HASH="${LOCK_FILENAME%.lock}"
    PID_FILE="${LOCK_DIR}/${PROJECT_HASH}.lock.pid"

    debug_log "Checking lock file: $LOCK_FILE"

    # Try to acquire lock (non-blocking) and perform checks while holding it
    # This prevents race condition where another process acquires lock between test and cleanup
    (
        if flock -n 200 2>/dev/null; then
            # Lock acquired - perform cleanup while holding lock
            debug_log "Lock acquired for cleanup check"

            SHOULD_CLEAN=0

            # Check if corresponding PID file exists
            if [ -f "$PID_FILE" ]; then
                PID=$(cat "$PID_FILE" 2>/dev/null)

                # Validate PID is numeric
                if [[ "$PID" =~ ^[0-9]+$ ]]; then
                    # Check if process exists
                    if ps -p "$PID" > /dev/null 2>&1; then
                        debug_log "Process $PID exists, lock is valid (skip)"
                        exit 0  # Exit subshell without cleanup
                    else
                        debug_log "Process $PID does not exist, cleaning up stale lock"
                        log_error "Cleaned stale lock: $LOCK_FILE (PID $PID not found)"
                        SHOULD_CLEAN=1
                    fi
                else
                    debug_log "Invalid PID in $PID_FILE: $PID, cleaning up"
                    log_error "Cleaned stale lock: $LOCK_FILE (invalid PID: $PID)"
                    SHOULD_CLEAN=1
                fi

                # Remove PID file
                rm -f "$PID_FILE"
            else
                debug_log "No PID file, cleaning up orphaned lock"
                log_error "Cleaned orphaned lock: $LOCK_FILE (no PID file)"
                SHOULD_CLEAN=1
            fi

            # Remove lock file (while still holding lock via flock)
            if [ "$SHOULD_CLEAN" -eq 1 ]; then
                rm -f "$LOCK_FILE"
                # Increment cleaned count via temp file
                CURRENT_COUNT=$(cat "$CLEANED_COUNT_FILE" 2>/dev/null || echo "0")
                echo "$((CURRENT_COUNT + 1))" > "$CLEANED_COUNT_FILE"
            fi
        else
            debug_log "Lock is held by active process (skip)"
        fi
    ) 200>"$LOCK_FILE"
done

CLEANED=$(cat "$CLEANED_COUNT_FILE" 2>/dev/null || echo "0")
rm -f "$CLEANED_COUNT_FILE"

debug_log "Cleanup complete: checked=$CHECKED, cleaned=$CLEANED"

# Rotate error log if it exceeds 1MB
if [ -f "$ERROR_LOG" ]; then
    LOG_SIZE=$(stat -f%z "$ERROR_LOG" 2>/dev/null || echo 0)
    if [ "$LOG_SIZE" -gt 1048576 ]; then
        debug_log "Rotating error log (size: $LOG_SIZE bytes)"
        # Use flock to prevent race condition during rotation
        (
            flock -x 200
            mv "$ERROR_LOG" "${ERROR_LOG}.old"
            touch "$ERROR_LOG"
        ) 200>"${ERROR_LOG}.lock"
        rm -f "${ERROR_LOG}.lock"
    fi
fi

exit 0
