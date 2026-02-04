---
description: "Run code review and approve for commit"
allowed-tools: Bash(git:*), Bash(bash:*), Task
---

# Code Review for Commit

Review staged changes and approve them for commit.

## Step 1: Check Staged Changes

Staged files: !`git diff --cached --stat`

If no staged changes, report "No staged changes to review" and exit.

## Step 2: Launch Code Reviewer Agent

**MANDATORY**: Use Task tool with `pr-review-toolkit:code-reviewer` agent.

Prompt: "Review the staged changes (git diff --cached) for this commit. Check for CLAUDE.md compliance, bugs, and code quality issues. Report only issues with confidence >= 80."

## Step 3: Handle Review Results

- If issues found (confidence >= 80): Present issues, suggest fixes, do NOT approve
- If no issues: Proceed to Step 4

## Step 4: Approve for Commit

**MANDATORY**: Run the approval script.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/approve-review.sh
```

This saves a hash of the staged changes that the pre-commit hook verifies.
