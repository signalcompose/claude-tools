#!/bin/bash
# PreToolUse hook: Block PR creation unless code review is approved
# Exit 0: Allow, Exit 2: Block

# Read JSON from stdin
INPUT=$(cat)

# Extract the command from tool_input.command
if command -v jq &> /dev/null; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
    COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
fi

# Only process gh pr create commands
if [[ ! "$COMMAND" =~ gh[[:space:]]+pr[[:space:]]+create ]]; then
    exit 0
fi

# Shell comment bypass: gh pr create ... # skip-review
if [[ "$COMMAND" =~ \#[[:space:]]*skip-review ]]; then
    echo "⚠️  Code review skipped (# skip-review detected)" >&2
    exit 0
fi

# Calculate repository-specific flag file path
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "unknown")
REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
REVIEW_FLAG="/tmp/claude/review-approved-${REPO_HASH}"

# Check if review approval flag exists
if [[ -f "$REVIEW_FLAG" ]]; then
    rm -f "$REVIEW_FLAG"

    # Suggest PR review after creation (integrates check-pr-created.sh functionality)
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "✅ Code review approved. PR creation allowed." >&2
    echo "" >&2
    echo "💡 After PR is created, consider running:" >&2
    echo "   /pr-review-toolkit:review-pr" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    exit 0
fi

# No approval flag - block PR creation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "⛔ Code Review Required Before PR Creation" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "" >&2
echo "Run code review before creating a PR:" >&2
echo "  /code:review-commit" >&2
echo "" >&2
echo "The review team will:" >&2
echo "  1. Analyze your changes for issues" >&2
echo "  2. Automatically fix critical/important problems" >&2
echo "  3. Iterate until code quality meets standards" >&2
echo "  4. Create approval flag when ready" >&2

# Diagnostic: check for hash mismatch
if [[ ! -d /tmp/claude ]]; then
    echo "" >&2
    echo "⚠️  Diagnostic: /tmp/claude directory does not exist" >&2
elif [[ ! -r /tmp/claude ]]; then
    echo "" >&2
    echo "⚠️  Diagnostic: /tmp/claude is not readable" >&2
    echo "   Check permissions: ls -ld /tmp/claude" >&2
else
    shopt -s nullglob
    EXISTING_FLAGS=(/tmp/claude/review-approved-*)
    shopt -u nullglob

    if [[ ${#EXISTING_FLAGS[@]} -gt 0 ]]; then
        echo "" >&2
        echo "⚠️  Diagnostic: found ${#EXISTING_FLAGS[@]} review flag(s) with different hash:" >&2
        for flag in "${EXISTING_FLAGS[@]}"; do
            echo "   $(basename "$flag")" >&2
        done
        echo "   Expected: $(basename "$REVIEW_FLAG")" >&2
        echo "   Hash algorithm: shasum -a 256 | cut -c1-16" >&2
    fi
fi

echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
exit 2
