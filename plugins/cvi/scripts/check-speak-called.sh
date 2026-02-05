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

# Check if jq is available
if ! command -v jq &> /dev/null; then
    # jq not available, allow stop to avoid blocking user
    exit 0
fi

# Check if CVI is enabled
CONFIG_FILE="$HOME/.cvi/config"
if [ -f "$CONFIG_FILE" ]; then
    CVI_ENABLED=$(grep "^CVI_ENABLED=" "$CONFIG_FILE" | cut -d'=' -f2)
fi
CVI_ENABLED=${CVI_ENABLED:-on}

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

# Alternative check: Look for speak.sh execution in Bash tool_use
# This catches direct script execution
if grep -q '"type":"tool_use"' "$TRANSCRIPT_PATH" 2>/dev/null && \
   grep -q '"name":"Bash"' "$TRANSCRIPT_PATH" 2>/dev/null && \
   grep -q 'scripts/speak\.sh' "$TRANSCRIPT_PATH" 2>/dev/null; then
    # speak.sh was executed via Bash tool, allow stop
    exit 0
fi

# /cvi:speak was NOT called - block stop and instruct Claude
# Load language setting for the instruction message
VOICE_LANG=$(grep "^VOICE_LANG=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2)
VOICE_LANG=${VOICE_LANG:-ja}

if [ "$VOICE_LANG" = "en" ]; then
    EXAMPLE_MSG="Task completed successfully."
else
    EXAMPLE_MSG="タスクが完了しました。"
fi

cat << EOF
{"decision": "block", "reason": "MANDATORY: You must call /cvi:speak before stopping. This triggers voice notification for task completion. Call it now with your task summary. Example: /cvi:speak ${EXAMPLE_MSG}"}
EOF
