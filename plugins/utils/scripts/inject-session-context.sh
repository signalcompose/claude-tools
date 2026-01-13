#!/bin/bash
# SessionStart hook: Inject common session context

# Today's date
cat << EOF
🔴 CRITICAL REMINDER: Today's date
   → Formatted: $(date +"%B %d, %Y")
   → ISO format: $(date +"%Y-%m-%d")
   → NEVER use memory or <env> for dates
   → ALWAYS use these values from this hook
EOF

# Git branch info
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

# CLAUDE.md detection
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    cat << 'EOF'

🔴 GLOBAL RULES DETECTED:
   📖 ~/.claude/CLAUDE.md exists

   CRITICAL global rules to follow:
   - Git workflow absolute prohibitions
   - Humility principle: Avoid superlatives
EOF
fi

if [ -f "./CLAUDE.md" ]; then
    cat << 'EOF'

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

exit 0
