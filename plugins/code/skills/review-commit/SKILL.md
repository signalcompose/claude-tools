---
name: review-commit
description: |
  Review working directory changes for code quality, security, and best practices before committing.
  Use when: "review my code", "check before commit", "code review",
  "コードレビュー", "コミット前チェック".
user-invocable: false
---

# Code Review for Commit

Iterative team-based code review with quality assurance loop.

## Step 1: Check Working Directory Changes

Changed files: !`git diff HEAD --stat`

If no changes, report "No changes to review" and exit.

## Step 2: Create Review Team

**MANDATORY**: Spawn a review team with the Task tool.

Team structure:
```
Team Lead (yourself)
├─ Reviewer (code-reviewer agent)
└─ Fixer (code-fixer agent)
```

**Reviewer Agent**:
- Analyzes `git diff HEAD`
- Categorizes issues by severity:
  - **Critical**: Security vulnerabilities, data loss, breaking changes
  - **Important**: Bugs, CLAUDE.md violations, performance issues
  - **Minor**: Style, formatting, documentation
- Reports findings with confidence >= 80%
- Sends issue list to Fixer

**Fixer Agent**:
- Receives issue list from Reviewer
- Fixes **only** critical and important issues
- Does NOT fix minor issues
- Reports completion to Team Lead

For detailed review criteria, see [references/review-criteria.md](references/review-criteria.md).

## Step 3: Iterative Review Loop

**MANDATORY**: Run up to 5 review iterations.

**Loop logic**:
```
FOR iteration = 1 TO 5:
  1. Reviewer analyzes current working directory changes
  2. Reviewer reports: critical_count, important_count, minor_count
  3. IF critical_count = 0 AND important_count = 0:
       → BREAK (quality target achieved)
  4. Fixer receives issue list from Reviewer
  5. Fixer fixes critical and important issues
  6. Fixer reports completion
  7. CONTINUE to next iteration
END FOR

IF iteration = 5 AND (critical_count > 0 OR important_count > 0):
  → Report failure to user
  → Do NOT create flag
  → Exit
```

**Success condition**: `critical_count = 0` AND `important_count = 0`

## Step 4: Create Approval Flag

**Only execute if Step 3 succeeds** (critical = 0, important = 0).

Create flag:
```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
FLAG_FILE="/tmp/claude/review-approved-${REPO_HASH}"

mkdir -p /tmp/claude
touch "$FLAG_FILE"

echo "✅ Code review completed in ${iteration} iteration(s)."
echo "All critical/important issues resolved."
echo "Ready to commit: git add -A && git commit -m 'your message'"
```

## Step 5: Shutdown Review Team

**MANDATORY**: Send shutdown request to both agents.

Use SendMessage tool:
```
type: "shutdown_request"
recipient: "reviewer"
content: "Review complete, shutting down team"
```

```
type: "shutdown_request"
recipient: "fixer"
content: "Review complete, shutting down team"
```

Wait for both agents to approve shutdown before exiting.

## Notes

- **Flag file**: Automatically removed after commit (by pre-commit hook)
- **Max iterations**: 5 (prevents infinite loops)
- **Minor issues**: Reported but not blocking (user can fix manually)
- **Failure**: If 5 iterations exhausted with remaining critical/important issues, review fails
