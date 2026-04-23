#!/bin/bash
# PreToolUse hook: Block git commit if .gitignore lacks security patterns
# Exit 0: Allow, Exit 2: Block

if ! command -v jq >/dev/null 2>&1; then
    cat >&2 <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCKED: jq not found (required for security hook)

Install jq and re-run:
  macOS:   brew install jq
  Linux:   apt-get install jq   # or your package manager

The .gitignore security-patterns check cannot run safely without jq.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 2
fi

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

# Only check git commit commands
[[ ! "$CMD" =~ git[[:space:]]+commit ]] && exit 0

# Resolve repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -z "$REPO_ROOT" ]]; then
    echo "check-gitignore-security: not in a git repo, security check skipped" >&2
    exit 0
fi

GITIGNORE="${REPO_ROOT}/.gitignore"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REF_FILE="${SCRIPT_DIR}/../references/gitignore-security-patterns.md"

if [[ ! -f "$REF_FILE" ]]; then
    cat >&2 <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCKED: code plugin reference file missing

Expected: ${REF_FILE}

The security-patterns reference that this hook validates against
is missing. This usually indicates a broken plugin install.

Recovery:
  /plugin update
  /utils:clear-plugin-cache code
  Restart Claude Code

Then re-run the commit.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 2
fi

# Check for security patterns marker in .gitignore
if ! grep -q "code:security-patterns" "$GITIGNORE" 2>/dev/null; then
    cat >&2 <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCKED: .gitignore missing security patterns
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Append the patterns from this reference to .gitignore:

  ${REF_FILE}

Quick install (run at repo root):

  cat "${REF_FILE}" >> .gitignore && git add .gitignore

These patterns (.env, *.key, *.pem, credentials*, etc.)
prevent accidental secret exposure.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    exit 2
fi

CURRENT_HASH=$(grep -o 'code:security-patterns:[a-f0-9]*' "$GITIGNORE" 2>/dev/null | head -1 | cut -d: -f3)
EXPECTED_HASH=$(grep -o 'code:security-patterns:[a-f0-9]*' "$REF_FILE" 2>/dev/null | head -1 | cut -d: -f3)

if [[ -n "$EXPECTED_HASH" && -n "$CURRENT_HASH" && "$CURRENT_HASH" != "$EXPECTED_HASH" ]]; then
    cat >&2 <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WARNING: .gitignore security patterns outdated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current: ${CURRENT_HASH}  Expected: ${EXPECTED_HASH}

Replace the patterns block in .gitignore with the reference:

  ${REF_FILE}

(Warn only — commit is not blocked.)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi

exit 0
