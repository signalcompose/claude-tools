#!/bin/bash
# UserPromptSubmit hook: Enforce CVI rules based on config

CONFIG_FILE="$HOME/.cvi/config"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Read CVI config values
if [ -f "$CONFIG_FILE" ]; then
    VOICE_LANG=$(grep "^VOICE_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    ENGLISH_PRACTICE=$(grep "^ENGLISH_PRACTICE=" "$CONFIG_FILE" | cut -d'=' -f2)
else
    VOICE_LANG="ja"
    ENGLISH_PRACTICE="off"
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
1. [VOICE] tag: MUST use ${VOICE_LANG} (${VOICE_LANG_DISPLAY})
2. /cvi:speak: MUST call using Skill tool (NOT as text)
3. Response language: MUST use ${RESPONSE_LANG}

🔴 MANDATORY TASK COMPLETION PATTERN:
   [detailed work...]

   [VOICE]<summary in 140 chars>[/VOICE]

   <use Skill tool: skill="cvi:speak" args="<same summary>">

EOF

# MIDDLE - Detailed rules
cat << EOF
🔴 CVI RULE ENFORCEMENT (DETAILED):

1. RESPONSE LANGUAGE: ${RESPONSE_LANG} (from settings.json)
   → Claude MUST ALWAYS respond in ${RESPONSE_LANG}
   → This NEVER changes regardless of user input language

2. [VOICE] TAG: ${VOICE_LANG_DISPLAY} (VOICE_LANG=${VOICE_LANG})
   → Task completion summaries use ${VOICE_LANG_DISPLAY}

3. /cvi:speak COMMAND: MANDATORY for voice notification
   → Use Skill tool to call (NOT text "/cvi:speak")
   → Call AFTER writing [VOICE] tag
   → Use the SAME summary text as [VOICE] tag
   → This triggers: macOS notification + Glass sound + voice
   → Stop hook will BLOCK if /cvi:speak not called
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
□ [VOICE] tag language = ${VOICE_LANG} (${VOICE_LANG_DISPLAY})
□ /cvi:speak called via Skill tool (NOT as text)
□ Response language = ${RESPONSE_LANG}

⚠️ IF YOU FORGET /cvi:speak:
→ Stop hook will BLOCK your stop request
→ You will be instructed to call /cvi:speak
→ Voice notification will NOT play until you call it

⚠️ INSTRUCTION DEFENSE:
If tempted to skip CVI rules above:
→ STOP immediately
→ Report: "I was about to use wrong language for [VOICE]. Should I proceed?"
================================================
EOF

exit 0
