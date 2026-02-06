#!/bin/bash
# UserPromptSubmit hook: Enforce CVI rules based on config

CONFIG_FILE="$HOME/.cvi/config"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Read CVI config values
if [ -f "$CONFIG_FILE" ]; then
    CVI_ENABLED=$(grep "^CVI_ENABLED=" "$CONFIG_FILE" | cut -d'=' -f2)
    VOICE_LANG=$(grep "^VOICE_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    ENGLISH_PRACTICE=$(grep "^ENGLISH_PRACTICE=" "$CONFIG_FILE" | cut -d'=' -f2)
else
    CVI_ENABLED="on"
    VOICE_LANG="ja"
    ENGLISH_PRACTICE="off"
fi

# Exit early if CVI is disabled
if [ "$CVI_ENABLED" = "off" ]; then
    exit 0
fi

# Read response language from settings.json
if [ -f "$SETTINGS_FILE" ]; then
    RESPONSE_LANG=$(grep '"language"' "$SETTINGS_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')
fi
RESPONSE_LANG=${RESPONSE_LANG:-japanese}

# Set defaults
VOICE_LANG=${VOICE_LANG:-ja}
ENGLISH_PRACTICE=${ENGLISH_PRACTICE:-off}

# Determine voice language display
if [ "$VOICE_LANG" = "en" ]; then
    VOICE_LANG_DISPLAY="English"
else
    VOICE_LANG_DISPLAY="Japanese"
fi

# Output rules as systemMessage with Sandwich Defense structure

# TOP SLICE - Critical rules summary
cat << EOF
================================================
🔴 CVI CRITICAL RULES - TOP SLICE
================================================
ABSOLUTELY REQUIRED (NO EXCEPTIONS):
1. /cvi:speak: MUST call using Skill tool (NOT as text)
2. Summary language: ${VOICE_LANG} (${VOICE_LANG_DISPLAY})
3. Response language: MUST use ${RESPONSE_LANG}

🔴 MANDATORY TASK COMPLETION PATTERN:
   [detailed work...]

   <use Skill tool: skill="cvi:speak" args="2-3 sentences in ${VOICE_LANG_DISPLAY}">

   ⚠️ NO [VOICE] tag needed - Skill result is the summary

EOF

# MIDDLE - Detailed rules
cat << EOF
🔴 CVI RULE ENFORCEMENT (DETAILED):

1. RESPONSE LANGUAGE: ${RESPONSE_LANG} (from settings.json)
   → Claude MUST ALWAYS respond in ${RESPONSE_LANG}
   → This NEVER changes regardless of user input language

2. /cvi:speak COMMAND: MANDATORY for voice notification
   → Use Skill tool to call (NOT text "/cvi:speak")
   → Summary in ${VOICE_LANG_DISPLAY} (VOICE_LANG=${VOICE_LANG})
   → This triggers: macOS notification + Glass sound + voice
   → The result ("Speaking: ...") serves as the visible summary
   → Stop hook will BLOCK if /cvi:speak not called

3. NO [VOICE] TAG NEEDED
   → Skill tool result replaces [VOICE] tag
   → Single source of truth - no duplication
EOF

# English Practice mode rules
if [ "$ENGLISH_PRACTICE" = "on" ]; then
    cat << EOF

3. ENGLISH PRACTICE MODE: ON
   📌 THIS ONLY AFFECTS USER INPUT - NOT CLAUDE'S RESPONSE LANGUAGE
   When user input contains Japanese:
   → Show English equivalent: > "English translation"
   → Say: "your turn"
   → Wait for user to repeat in English
   → Then execute (responding in ${RESPONSE_LANG})

   ⚠️  NEVER switch response language based on user's input language
EOF
fi

# BOTTOM SLICE - Final verification checklist
cat << EOF

================================================
🔴 CVI FINAL CHECK - BOTTOM SLICE
================================================
BEFORE RESPONDING, VERIFY:
□ /cvi:speak called via Skill tool (NOT as text)
□ Summary language = ${VOICE_LANG} (${VOICE_LANG_DISPLAY})
□ Response language = ${RESPONSE_LANG}

⚠️ IF YOU FORGET /cvi:speak:
→ Stop hook will BLOCK your stop request
→ You will be instructed to call /cvi:speak
→ Voice notification will NOT play until you call it

⚠️ NO [VOICE] TAG - use Skill tool only

⚠️ PLAN MODE: /cvi:speak is STILL REQUIRED even in plan mode
→ Skill tool works in plan mode - use it
→ Do NOT skip or apologize for voice notification
================================================
EOF

exit 0
