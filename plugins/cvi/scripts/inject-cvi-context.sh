#!/bin/bash
# SessionStart hook: Inject CVI context for language handling

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

# Determine example based on language
if [ "$VOICE_LANG" = "en" ]; then
    VOICE_EXAMPLE="Task completed successfully."
    VOICE_LANG_UPPER="English"
else
    VOICE_EXAMPLE="タスクが完了しました。"
    VOICE_LANG_UPPER="Japanese"
fi

# Output context injection
cat << EOF
================================================
🔴 MANDATORY CONTEXT INJECTION - READ CAREFULLY
================================================
🔴 CRITICAL REMINDER: [VOICE] tag MUST use language: ${VOICE_LANG}
   → Use ${VOICE_LANG_UPPER} in [VOICE] tag
   → Example: [VOICE]${VOICE_EXAMPLE}[/VOICE]

🔴 CRITICAL REMINDER: Today's date
   → Formatted: $(date +"%B %d, %Y")
   → ISO format: $(date +"%Y-%m-%d")
   → NEVER use memory or <env> for dates
   → ALWAYS use these values from this hook
EOF

# Add current branch info if in git repo
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$CURRENT_BRANCH" ]; then
        echo ""
        echo "🔴 CRITICAL REMINDER: Current Git branch: ${CURRENT_BRANCH}"
        if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "develop" ]; then
            echo "   ⚠️  WARNING: You are on a PROTECTED branch!"
            echo "   → NEVER commit directly to ${CURRENT_BRANCH}"
            echo "   → Create a feature branch first"
        fi
    fi
fi

# Add English Practice info if enabled
if [ "$ENGLISH_PRACTICE" = "on" ]; then
    cat << EOF

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
EOF
fi

# Add mandatory response format
cat << EOF

🔴 MANDATORY RESPONSE FORMAT:
   Every response completing a task MUST end with:

   [VOICE]<${VOICE_LANG_UPPER} summary in 140 chars>[/VOICE]

   Exception: Questions to user (then no VOICE tag needed)
EOF

# Add CLAUDE.md reminder
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    cat << EOF

🔴 GLOBAL RULES DETECTED:
   📖 ~/.claude/CLAUDE.md exists

   CRITICAL global rules to follow:
   - [VOICE] tag (TTS summary): Follow VOICE_LANG in ~/.cvi/config
   - Git workflow absolute prohibitions
   - Humility principle: Avoid superlatives
EOF
fi

# Check for project CLAUDE.md
if [ -f "./CLAUDE.md" ]; then
    cat << EOF

🔴 PROJECT-SPECIFIC RULES DETECTED:
   📖 ./CLAUDE.md exists in this project

   Read CLAUDE.md for:
   - Git workflow requirements
   - Documentation structure
   - Session start checklist
   - Project-specific conventions

   ⚠️  DO NOT proceed without reading CLAUDE.md first!
EOF
fi

echo ""
echo "================================================"

exit 0
