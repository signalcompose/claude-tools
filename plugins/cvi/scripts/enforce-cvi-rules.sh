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

# Output rules as systemMessage
cat << EOF
🔴 CVI RULE ENFORCEMENT:

1. RESPONSE LANGUAGE: ${RESPONSE_LANG} (from settings.json)
   → Claude MUST ALWAYS respond in ${RESPONSE_LANG}
   → This NEVER changes regardless of user input language

2. [VOICE] TAG: ${VOICE_LANG_DISPLAY} (VOICE_LANG=${VOICE_LANG})
   → Task completion summaries use ${VOICE_LANG_DISPLAY}
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

exit 0
