---
description: "Self-review a PR before requesting reviewers. Use when user asks to review a PR, check PR quality, or validate PR changes before merge."
---

# Review PR

Self-review a pull request using pr-review-toolkit agents.

## Execution

### Step 1: Get PR Number

If argument provided: Use that PR number
If no argument: Detect from current branch

```bash
gh pr view --json number -q '.number'
```

If no PR found: Report error and exit.

### Step 2: Run PR Review

Launch Task tool:

```
subagent_type: "pr-review-toolkit:review-pr"
prompt: "Review PR #<number>. Run comprehensive review including code quality, errors, and test coverage."
description: "PR review"
```

### Step 3: Report Results

**If issues found**:
- Present all issues
- Suggest fixes

**If no issues**:
- Report: "PR #<number> passed review. Ready for merge."

## Notes

- This skill only reviews, does NOT merge
- User decides next action (merge, request reviewers, etc.)
