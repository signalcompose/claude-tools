#!/bin/bash

# CVI Post-Speak Hook Handler
# Triggered by PostToolUse hook when /cvi:speak is called
# Ensures synchronous voice playback with proper project isolation

set -euo pipefail

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
    echo "Error: No text provided to /cvi:speak" >&2
    exit 1
fi

debug_log "Text to speak: $TEXT"

# Get project root directory
PROJECT_ROOT=$(pwd)
debug_log "Project root: $PROJECT_ROOT"

# Call speak-sync.sh for synchronous playback
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
debug_log "Calling speak-sync.sh"

"${SCRIPT_DIR}/speak-sync.sh" "$TEXT"
EXIT_CODE=$?

debug_log "speak-sync.sh completed with exit code: $EXIT_CODE"
exit $EXIT_CODE
