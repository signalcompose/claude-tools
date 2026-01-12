---
description: "Run code review and approve for commit (integrates with check-code-review.sh hook)"
---

# Code Review Skill

Review staged changes and approve them for commit.

## Overview

This skill performs code review on staged git changes and, if approved, saves a hash that allows the pre-commit hook to verify the review was completed.

## Execution Steps

### Step 1: Check Staged Changes

First, verify there are staged changes to review:

```bash
git diff --cached --stat
```

**If no staged changes**: Report "No staged changes to review" and exit.

### Step 2: Get Diff for Review

Get the full diff of staged changes:

```bash
git diff --cached
```

### Step 3: Perform Code Review

Review the staged changes for:

1. **Code Quality**
   - Readability and maintainability
   - Proper error handling
   - No hardcoded values that should be configurable

2. **Security**
   - No exposed secrets or credentials
   - No SQL injection vulnerabilities
   - No XSS vulnerabilities
   - Input validation where needed

3. **Best Practices**
   - Follows project conventions (check CLAUDE.md if exists)
   - Appropriate naming conventions
   - No unnecessary code duplication

4. **Logic**
   - No obvious bugs
   - Edge cases handled
   - Correct algorithm usage

### Step 4: Report Findings

Present review findings to the user:

**If issues found**:
```
## Code Review Results

### Issues Found

1. **[Severity: High/Medium/Low]** Description of issue
   - File: path/to/file.ts:line
   - Suggestion: How to fix

### Summary
- Total issues: N
- High: N, Medium: N, Low: N

Please address the issues before committing.
```

**If no issues**:
```
## Code Review Results

No issues found. Code looks good!

Approving for commit...
```

### Step 5: Approve (if passed)

If review passes with no blocking issues, run the approval script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/approve-review.sh
```

This saves a hash of the staged changes that the pre-commit hook can verify.

## Integration with Pre-commit Hook

This skill works with `check-code-review.sh` as a pre-commit hook:

1. Hook blocks `git commit` if no review approval exists
2. This skill performs review and creates approval hash
3. Subsequent `git commit` proceeds if hash matches

### Setting Up the Hook (Optional)

Add to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-code-review.sh"
          }
        ]
      }
    ]
  }
}
```

## Notes

- Review is based on staged changes only
- Unstaged changes are ignored
- Hash changes if staged content changes (requires re-review)
- Approval file is automatically deleted after successful commit
