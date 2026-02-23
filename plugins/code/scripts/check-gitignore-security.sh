#!/bin/bash
# PreToolUse hook: Block git commit if .gitignore lacks security patterns
# Exit 0: Allow, Exit 2: Block

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

# Only check git commit commands
[[ ! "$CMD" =~ git[[:space:]]+commit ]] && exit 0

# Resolve repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
[[ -z "$REPO_ROOT" ]] && exit 0

# Check for security patterns marker in .gitignore
grep -q "code:security-patterns" "${REPO_ROOT}/.gitignore" 2>/dev/null && exit 0

# Block: marker not found
cat >&2 <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCKED: .gitignore missing security patterns
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run: /code:setup-dev-env --fix

This adds .env, *.key, *.pem, credentials* patterns
to .gitignore to prevent accidental secret exposure.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
exit 2
