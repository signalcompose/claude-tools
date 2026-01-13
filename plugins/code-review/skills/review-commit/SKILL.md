---
description: "Run code review and approve for commit (integrates with check-code-review.sh hook)"
---

# Code Review Skill

Review staged changes using the code-reviewer agent and approve them for commit.

## Overview

This skill performs automated code review on staged git changes using the `pr-review-toolkit:code-reviewer` agent. If the review passes, it saves a hash that allows the pre-commit hook to verify the review was completed.

## Execution Steps

### Step 1: Check Staged Changes

First, verify there are staged changes to review:

```bash
git diff --cached --stat
```

**If no staged changes**: Report "No staged changes to review" and exit.

### Step 2: Launch Code Reviewer Agent

Use the Task tool to launch the `pr-review-toolkit:code-reviewer` agent:

```
Task tool parameters:
- subagent_type: "pr-review-toolkit:code-reviewer"
- prompt: "Review the staged changes (git diff --cached) for this commit. Check for CLAUDE.md compliance, bugs, and code quality issues. Report only issues with confidence >= 80."
- description: "Review staged changes"
```

The agent will:
- Check CLAUDE.md compliance
- Detect bugs and logic errors
- Evaluate code quality
- Score issues by confidence (only report >= 80)

### Step 3: Handle Review Results

**If issues found (confidence >= 80)**:
- Present the issues to the user
- Do NOT approve the commit
- Suggest fixes

**If no issues found**:
- Report that the review passed
- Proceed to Step 4

### Step 4: Approve for Commit

If review passes, run the approval script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/approve-review.sh
```

This saves a hash of the staged changes that the pre-commit hook can verify.

## Integration with Pre-commit Hook

This skill works with `check-code-review.sh` as a pre-commit hook:

1. Hook blocks `git commit` if no review approval exists
2. User runs `/code:review-commit`
3. This skill launches code-reviewer agent
4. If passed, approval hash is saved
5. Subsequent `git commit` proceeds if hash matches

## Notes

- Review is based on staged changes only (`git diff --cached`)
- Uses `pr-review-toolkit:code-reviewer` agent for automated review
- Hash changes if staged content changes (requires re-review)
- Approval file is automatically deleted after successful commit
