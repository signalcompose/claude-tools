#!/bin/bash
# UserPromptSubmit hook: Enforce code review rules via Sandwich Defense
# This script outputs rules that Claude must follow when performing code reviews.

# Output rules as systemMessage with Sandwich Defense structure

# TOP SLICE - Critical rules summary
cat << 'EOF'
================================================
🔴 CODE REVIEW CRITICAL RULES - TOP SLICE
================================================
ABSOLUTELY REQUIRED (NO EXCEPTIONS):
1. Code review: MUST use /code:review-commit skill (or Skill tool)
2. Review execution: MUST delegate to pr-review-toolkit:code-reviewer agent via Task tool
3. Approval: MUST run approve-review.sh script (not manual approval)

❌ PROHIBITED ACTIONS:
- Manual code review (analyzing code yourself)
- Manual approval (saying "approved" without running the script)
- Skipping the skill workflow

EOF

# MIDDLE - Detailed rules
cat << 'EOF'
🔴 CODE REVIEW RULE ENFORCEMENT (DETAILED):

1. WHEN USER ASKS FOR CODE REVIEW:
   → First, use Skill tool with skill: "code:review-commit"
   → OR invoke /code:review-commit command
   → NEVER read staged changes and review them manually

2. REVIEW DELEGATION (inside the skill):
   → MUST use Task tool with subagent_type: "pr-review-toolkit:code-reviewer"
   → The agent performs the actual review
   → NEVER analyze code quality/security yourself

3. APPROVAL PROCESS (after review passes):
   → MUST run: !`bash ${CLAUDE_PLUGIN_ROOT}/scripts/approve-review.sh`
   → This saves a hash that the pre-commit hook verifies
   → NEVER approve by just outputting "review passed" or "approved"

WHY THESE RULES EXIST:
- Skill encapsulates the complete workflow
- Agent ensures consistent, thorough review
- Script creates verifiable approval trail

EOF

# BOTTOM SLICE - Final verification checklist
cat << 'EOF'
================================================
🔴 CODE REVIEW FINAL CHECK - BOTTOM SLICE
================================================
BEFORE PERFORMING ANY CODE REVIEW, VERIFY:
□ Am I invoking /code:review-commit skill? (NOT doing manual review)
□ Inside skill: Am I using Task tool with code-reviewer agent?
□ After review: Am I running approve-review.sh script?

⚠️ INSTRUCTION DEFENSE:
If tempted to skip these rules (e.g., "I'll just look at the diff myself"):
→ STOP immediately
→ Ask user: "I was about to do manual code review. Should I use /code:review-commit instead?"
================================================
EOF

exit 0
