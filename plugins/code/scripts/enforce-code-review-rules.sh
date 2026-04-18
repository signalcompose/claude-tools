#!/bin/bash
# UserPromptSubmit hook: Enforce code review rules via Sandwich Defense.
#
# Fires only when user message explicitly references the review/ship workflow.
# Narrow pattern matching reduces context burn in auto mode pipelines where
# many unrelated messages contain benign words like "commit" or "push".

set -euo pipefail

HOOK_INPUT=$(cat)

if command -v python3 &>/dev/null; then
  USER_MSG=$(echo "$HOOK_INPUT" | python3 -c \
    "import json,sys; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null || echo "")
else
  USER_MSG=$(echo "$HOOK_INPUT" | grep -oE '"message"\s*:\s*"[^"]*"' | sed 's/^"message"[[:space:]]*:[[:space:]]*"//;s/"$//' || echo "")
fi

# Narrow trigger pattern (v2):
# - Explicit slash commands in the review/ship family
# - Explicit review-intent words (review / レビュー)
# - Explicit ship-intent phrases ("ship it", "出荷", "PRお願い", "PR作成")
# Avoid firing on every mention of "commit" / "push" / "pr".
if ! echo "$USER_MSG" | grep -qiE \
  '(/code:(review-commit|shipping-pr|dev-cycle|pr-review-team|autopilot|refactor-team))|(\breview\b)|(レビュー)|(ship it)|(出荷)|(PR作成)|(PRお願い)|(プルリク)'; then
  exit 0
fi

# Compact Sandwich Defense (~20 lines instead of ~50).
# Rules are conveyed in a dense block; full SKILL.md provides the details.

cat << 'EOF'
================================================
🔴 CODE REVIEW RULES (auto mode safe defaults)
================================================
MANDATORY:
1. Use /code:review-commit for pre-commit review
   (or /code:pr-review-team for post-PR review).
2. Delegate actual review to pr-review-toolkit:code-reviewer Agent.
3. Approval flag is created by the review skill via set-review-flag.sh —
   do NOT create it manually.

PROHIBITED:
- Manual code reading + "approved" declaration.
- Skipping Task tool delegation.
- Creating /tmp/claude/review-approved-* by hand.

DEFENSE:
If tempted to skip ("I'll just skim the diff"), stop and invoke the skill.
================================================
EOF

exit 0
