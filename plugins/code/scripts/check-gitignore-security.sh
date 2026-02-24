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

GITIGNORE="${REPO_ROOT}/.gitignore"

# Check for security patterns marker in .gitignore
if ! grep -q "code:security-patterns" "$GITIGNORE" 2>/dev/null; then
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
fi

# Check hash version (warn only, do not block)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REF_FILE="${SCRIPT_DIR}/../skills/setup-dev-env/references/gitignore-security-patterns.md"

CURRENT_HASH=$(grep -o 'code:security-patterns:[a-f0-9]*' "$GITIGNORE" 2>/dev/null | head -1 | cut -d: -f3)
EXPECTED_HASH=$(grep -o 'code:security-patterns:[a-f0-9]*' "$REF_FILE" 2>/dev/null | head -1 | cut -d: -f3)

if [[ -n "$EXPECTED_HASH" && -n "$CURRENT_HASH" && "$CURRENT_HASH" != "$EXPECTED_HASH" ]]; then
    cat >&2 <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WARNING: .gitignore security patterns outdated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current: ${CURRENT_HASH}  Expected: ${EXPECTED_HASH}

Run: /code:setup-dev-env --fix

to update .gitignore with the latest security patterns.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi

exit 0
