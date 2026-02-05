#!/bin/bash
# SessionStart hook: Inject CVI-specific context (voice settings only)

CONFIG_FILE="$HOME/.cvi/config"

# Read config values
if [ -f "$CONFIG_FILE" ]; then
    CVI_ENABLED=$(grep "^CVI_ENABLED=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_LANG=$(grep "^VOICE_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    ENGLISH_PRACTICE=$(grep "^ENGLISH_PRACTICE=" "$CONFIG_FILE" | cut -d'=' -f2)
fi

# Set defaults
CVI_ENABLED=${CVI_ENABLED:-on}
VOICE_LANG=${VOICE_LANG:-ja}
ENGLISH_PRACTICE=${ENGLISH_PRACTICE:-off}

# Exit silently if CVI is disabled
if [ "$CVI_ENABLED" = "off" ]; then
    exit 0
fi

# Determine language display
if [ "$VOICE_LANG" = "en" ]; then
    VOICE_EXAMPLE="Task completed successfully."
    VOICE_LANG_UPPER="ENGLISH"
else
    VOICE_EXAMPLE="タスクが完了しました。"
    VOICE_LANG_UPPER="JAPANESE"
fi

# Output CVI context
echo "🔴 CRITICAL REMINDER: [VOICE] tag MUST use language: ${VOICE_LANG}"
echo "   → Use ${VOICE_LANG_UPPER} in [VOICE] tag"
echo "   → Example: [VOICE]${VOICE_EXAMPLE}[/VOICE]"

# English Practice mode
if [ "$ENGLISH_PRACTICE" = "on" ]; then
    cat << 'EOF'

🔴 ENGLISH PRACTICE MODE IS ON
   📌 IMPORTANT: This mode ONLY affects USER prompts
   → When user gives Japanese instruction:
     1. Show English equivalent: > "English instruction"
     2. Prompt: "your turn"
     3. Wait for user to repeat in English
     4. THEN execute the instruction

   ⚠️  THIS DOES NOT CHANGE CLAUDE'S RESPONSE LANGUAGE
   → You MUST respond in the language set by Claude Code's "language" setting
   → English Practice is for USER input only, not Claude output

   🔴 CLARIFICATION RULES (user is practicing English):
   → If user's English is unclear or ambiguous, ASK for clarification
   → Do NOT guess the meaning - confirm before acting
   → When user asks "How do you say X in English?", answer the question
EOF
fi

# Mandatory response format
cat << EOF

🔴 MANDATORY TASK COMPLETION FORMAT:
   Every response completing a task MUST follow this pattern:

   [detailed work...]

   [VOICE]<${VOICE_LANG_UPPER} summary: 2-3 sentences explaining what was done and outcome>[/VOICE]

   <use Skill tool: skill="cvi:speak" args="<same summary>">

   ⚠️ [VOICE] tag AND Skill tool call are REQUIRED
   ⚠️ Do NOT write "/cvi:speak" as text - use Skill tool
   ⚠️ Stop hook will BLOCK if /cvi:speak not called via Skill
   ⚠️ No character limit - focus on clarity and useful information

   Exception: Questions to user (then no VOICE tag needed)
EOF

exit 0
