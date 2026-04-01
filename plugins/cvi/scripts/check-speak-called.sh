#!/bin/bash

# Stop hook: Enforce /cvi:speak usage
#
# This script checks if /cvi:speak was called in the current session.
# If not, it blocks Claude from stopping and instructs it to call /cvi:speak.
#
# Return values:
# - exit 0: Allow stop (speak was called or CVI is disabled)
# - JSON with decision:block: Block stop and instruct Claude to call /cvi:speak

# Read hook input from stdin
INPUT=$(cat)

# Guard: if stop_hook_active is true, a previous Stop hook already blocked and
# Claude retried. Allow stop unconditionally to prevent infinite loops.
# Reference: plugins/code/scripts/dev-cycle-stop.sh uses the same pattern.
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || true)
# If stop_hook_active is true OR jq failed (empty string), allow stop to prevent infinite loops
if [ "$STOP_HOOK_ACTIVE" = "true" ] || [ -z "$STOP_HOOK_ACTIVE" ]; then
    exit 0
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    # jq not available, allow stop to avoid blocking user
    exit 0
fi

# Function: Detect if sandbox is enabled
# Returns: 0 if sandbox enabled, 1 if disabled or unknown
is_sandbox_enabled() {
    local SETTINGS_LOCAL="$HOME/.claude/settings.local.json"
    local SETTINGS_GLOBAL="$HOME/.claude/settings.json"

    # Priority 1: Check settings.local.json
    if [ -f "$SETTINGS_LOCAL" ]; then
        local sandbox_enabled=$(jq -r '.sandbox.enabled // "null"' "$SETTINGS_LOCAL" 2>/dev/null || echo "null")
        if [ "$sandbox_enabled" = "true" ]; then
            return 0  # Sandbox enabled
        elif [ "$sandbox_enabled" = "false" ]; then
            return 1  # Sandbox explicitly disabled
        fi
    fi

    # Priority 2: Check settings.json
    if [ -f "$SETTINGS_GLOBAL" ]; then
        local sandbox_enabled=$(jq -r '.sandbox.enabled // "null"' "$SETTINGS_GLOBAL" 2>/dev/null || echo "null")
        if [ "$sandbox_enabled" = "true" ]; then
            return 0  # Sandbox enabled
        fi
    fi

    # Default: Assume disabled if not specified
    # Rationale: Prioritize CVI notifications over sandbox detection failures
    # If sandbox state is unknown, allow CVI checks to run to avoid missing notifications
    return 1
}

# Skip CVI check if sandbox is enabled
if is_sandbox_enabled; then
    # Sandbox is enabled, skip /cvi:speak check
    # Allow stop without blocking
    exit 0
fi

# Load shared config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config.sh" || { exit 0; }  # Fail open: allow stop if config unavailable
load_cvi_config

# Exit early if disabled - allow stop
if [ "$CVI_ENABLED" = "off" ]; then
    exit 0
fi

# Extract transcript path from hook input
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path' 2>/dev/null)

# Check if transcript path is valid
if [ -z "$TRANSCRIPT_PATH" ] || [ "$TRANSCRIPT_PATH" = "null" ]; then
    # Could not parse transcript path, allow stop
    exit 0
fi

# Check if transcript exists
if [ ! -f "$TRANSCRIPT_PATH" ]; then
    # No transcript, allow stop (edge case)
    exit 0
fi

# Check if /cvi:speak was called in this session
# Look for Skill tool usage with "cvi:speak" in the transcript
# Pattern looks for tool_use with skill parameter to avoid matching user messages or code blocks
if grep -q '"type":"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null && \
   grep -q '"name":"Skill"' "$TRANSCRIPT_PATH" 2>/dev/null && \
   grep -q '"skill":"cvi:speak"' "$TRANSCRIPT_PATH" 2>/dev/null; then
    # /cvi:speak was called via Skill tool, allow stop
    exit 0
fi

# Alternative check: Look for speak-sync.sh execution in Bash tool_use
# This catches direct script execution
if grep -q '"type":"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null && \
   grep -q '"name":"Bash"' "$TRANSCRIPT_PATH" 2>/dev/null && \
   grep -qE 'scripts/(speak-sync|post-speak)\.sh' "$TRANSCRIPT_PATH" 2>/dev/null; then
    # speak-sync.sh was executed via Bash tool, allow stop
    exit 0
fi

# /cvi:speak was NOT called - block stop and instruct Claude
# VOICE_LANG is already loaded via lib/config.sh
if [ "$VOICE_LANG" = "en" ]; then
    EXAMPLE_MSG="Task completed successfully."
else
    EXAMPLE_MSG="タスクが完了しました。"
fi

cat << EOF
{"decision": "block", "reason": "MANDATORY: You must use the Skill tool to call /cvi:speak before stopping. Do NOT write '/cvi:speak' as text. Use Skill tool with skill='cvi:speak' and args='${EXAMPLE_MSG}' to trigger voice notification."}
EOF
