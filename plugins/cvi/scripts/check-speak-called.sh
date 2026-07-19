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

# Load shared config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config.sh" || { echo "[cvi] Failed to source lib/config.sh" >&2; exit 0; }  # Fail open: allow stop if config unavailable

# Skip CVI check if sandbox is enabled
if is_sandbox_enabled; then
    # Sandbox is enabled, skip /cvi:speak check
    # Allow stop without blocking
    exit 0
fi

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

# Accept either the Skill-tool wrapper or a direct MCP tool invocation.
# The MCP tool name has two forms: bare `mcp__cvi-voice__speak` (direct
# .mcp.json) and plugin-namespaced `mcp__plugin_cvi_cvi-voice__speak`
# (via the plugin registry). The tool_use guard prevents false matches
# from user-pasted JSON literals.
if is_speak_called "$TRANSCRIPT_PATH"; then
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
