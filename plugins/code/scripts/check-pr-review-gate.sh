#!/bin/bash
# PreToolUse hook: Block PR creation unless code review is approved
# Exit 0: Allow, Exit 2: Block

SEPARATOR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --- Helper functions ---

extract_command() {
    local input="$1"
    if command -v jq &> /dev/null; then
        echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null
    else
        echo "$input" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/'
    fi
}

print_diagnostics() {
    local expected_flag="$1"

    if [[ ! -d /tmp/claude ]]; then
        echo "⚠️  Diagnostic: /tmp/claude directory does not exist" >&2
        return
    fi

    if [[ ! -r /tmp/claude ]]; then
        echo "⚠️  Diagnostic: /tmp/claude is not readable" >&2
        echo "   Check permissions: ls -ld /tmp/claude" >&2
        return
    fi

    shopt -s nullglob
    local existing_flags=(/tmp/claude/review-approved-*)
    shopt -u nullglob

    if [[ ${#existing_flags[@]} -gt 0 ]]; then
        echo "⚠️  Diagnostic: found ${#existing_flags[@]} review flag(s) for other repositories:" >&2
        for flag in "${existing_flags[@]}"; do
            echo "   $(basename "$flag")" >&2
        done
        echo "   Expected: $(basename "$expected_flag")" >&2
        echo "   Hash algorithm: shasum -a 256 | cut -c1-16" >&2
    fi
}

# --- Main ---

INPUT=$(cat)
COMMAND=$(extract_command "$INPUT")

# Only process gh pr create commands
if [[ ! "$COMMAND" =~ gh[[:space:]]+pr[[:space:]]+create ]]; then
    exit 0
fi

# Shell comment bypass: gh pr create ... # skip-review
if [[ "$COMMAND" =~ \#[[:space:]]*skip-review[[:space:]]*$ ]]; then
    echo "⚠️  Code review skipped (# skip-review detected)" >&2
    exit 0
fi

# Repository-specific flag file path
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "unknown")
REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
REVIEW_FLAG="/tmp/claude/review-approved-${REPO_HASH}"

# Approved: consume flag and allow PR creation
if [[ -f "$REVIEW_FLAG" ]]; then
    rm -f "$REVIEW_FLAG"
    cat >&2 <<EOF

${SEPARATOR}
✅ Code review approved. PR creation allowed.

💡 After PR is created, consider running:
   /pr-review-toolkit:review-pr
${SEPARATOR}
EOF
    exit 0
fi

# Not approved: block PR creation
cat >&2 <<EOF
${SEPARATOR}
⛔ Code Review Required Before PR Creation
${SEPARATOR}

Run code review before creating a PR:
  /code:review-commit

The review team will:
  1. Analyze your changes for issues
  2. Automatically fix critical/important problems
  3. Iterate until code quality meets standards
  4. Create approval flag when ready

EOF

print_diagnostics "$REVIEW_FLAG"

cat >&2 <<EOF

${SEPARATOR}
EOF
exit 2
