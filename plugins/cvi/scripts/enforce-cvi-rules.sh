#!/bin/bash
# UserPromptSubmit hook: Enforce CVI rules based on config

CONFIG_FILE="$HOME/.cvi/config"

# Read config values
if [ -f "$CONFIG_FILE" ]; then
    VOICE_LANG=$(grep "^VOICE_LANG=" "$CONFIG_FILE" | cut -d'=' -f2)
    ENGLISH_PRACTICE=$(grep "^ENGLISH_PRACTICE=" "$CONFIG_FILE" | cut -d'=' -f2)
else
    # Config file not found - use defaults silently
    VOICE_LANG="ja"
    ENGLISH_PRACTICE="off"
fi

# Set defaults for empty values
VOICE_LANG=${VOICE_LANG:-ja}
ENGLISH_PRACTICE=${ENGLISH_PRACTICE:-off}

# Determine language display
if [ "$VOICE_LANG" = "en" ]; then
    VOICE_LANG_DISPLAY="English"
else
    VOICE_LANG_DISPLAY="Japanese"
fi

# Output rules as systemMessage
cat << EOF
CVI Rule Enforcement (from ~/.cvi/config):

1. [VOICE] TAG: Use ${VOICE_LANG_DISPLAY} (VOICE_LANG=${VOICE_LANG})
EOF

# English Practice mode rules
if [ "$ENGLISH_PRACTICE" = "on" ]; then
    cat << 'EOF'

2. ENGLISH PRACTICE MODE: ON
   When user input contains Japanese:
   → Show English equivalent: > "English translation"
   → Say: "your turn"
   → Wait for user to repeat in English
   → Do NOT execute until user provides English input
EOF
fi

exit 0
