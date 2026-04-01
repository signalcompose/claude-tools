#!/bin/bash
# SessionStart hook: Inject CVI-specific context and English Practice mode
set -o pipefail

# Load shared config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/config.sh" && load_cvi_config

# English Practice mode (independent of CVI_ENABLED)
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

# Exit early if CVI is disabled (English Practice output above is independent)
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

# Mandatory response format
cat << EOF

🔴 MANDATORY TASK COMPLETION FORMAT:
   Every response completing a task MUST follow this pattern:

   [detailed work...]

   <use Skill tool: skill="cvi:speak" args="${VOICE_LANG_UPPER} summary: 2-3 sentences">

   ⚠️ Use Skill tool ONLY - no [VOICE] tag needed
   ⚠️ The Skill result ("Speaking: ...") serves as the visible summary
   ⚠️ Do NOT write "/cvi:speak" as text - use Skill tool
   ⚠️ Stop hook will BLOCK if /cvi:speak not called via Skill

   Exception: Questions to user (then no notification needed)
   ⚠️ Plan mode is NOT an exception - /cvi:speak is STILL required
EOF

exit 0
