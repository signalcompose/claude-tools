---
name: review-commit
description: |
  Review working directory changes for code quality, security, and best practices before creating a PR.
  Use when: "review my code", "check before PR", "code review",
  "コードレビュー", "PR作成前チェック".
user-invocable: false
---

# Code Review

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

**MANDATORY**: Always specify an explicit `model` parameter when spawning each agent. Choose the appropriate model based on task complexity (`haiku` for lightweight, `sonnet` for standard, `opus` for complex reasoning). Never omit `model` (default `inherit` may fail in parallel spawning).

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
- Commits fixes freely (no markers needed)
- Reports completion to Team Lead

For detailed review criteria, read `${CLAUDE_PLUGIN_ROOT}/skills/review-commit/references/review-criteria.md`.

## Step 3: Iterative Review Loop

**MANDATORY**: Run up to 5 review iterations.

**WARNING: The Fixer's "completion" report is NOT a review result. It does not update critical_count or important_count. Counts are ONLY valid when produced by the Reviewer in step 1-2 of the current iteration. Never carry counts forward across iterations.**

**Loop logic**:
```
FOR iteration = 1 TO 5:
  SET fresh_critical_count = UNSET
  SET fresh_important_count = UNSET

  1. Invoke Reviewer agent to analyze current working directory changes (re-invoke even if Reviewer ran in a prior iteration; do NOT reuse prior analysis)
  2. Reviewer reports and ASSIGNS: fresh_critical_count, fresh_important_count, minor_count
  3. MUST VERIFY: fresh_critical_count and fresh_important_count are SET (not UNSET).
     If either is UNSET, step 1 was skipped — go back to step 1.
     IF fresh_critical_count = 0 AND fresh_important_count = 0:
       → BREAK (quality target achieved)
  4. Fixer receives issue list from Reviewer
  5. Fixer fixes critical and important issues
  6. Fixer reports completion to Team Lead (this is a work-done signal only; Team Lead MUST NOT use this report to evaluate exit condition — proceed to next iteration's step 1 instead)
  7. CONTINUE to next iteration
END FOR

IF iteration limit reached AND (fresh_critical_count is UNSET OR fresh_critical_count > 0 OR fresh_important_count is UNSET OR fresh_important_count > 0):
  → Report failure to user
  → Do NOT create flag
  → Exit
```

**Success condition**: `fresh_critical_count = 0` AND `fresh_important_count = 0` as reported by Reviewer in the current iteration

## Step 4: Create Approval Flag

**Only execute if Step 3 succeeds** (critical = 0, important = 0).

Set the review approval flag:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/set-review-flag.sh
```

Report to user (substitute the actual iteration count):

```
Code review completed in N iteration(s).
All critical/important issues resolved.
Ready to create PR: gh pr create --title '...' --body '...'
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

- **Flag file**: Automatically removed when PR creation gate passes (by PreToolUse hook)
- **Max iterations**: 5 (prevents infinite loops)
- **Minor issues**: Reported but not blocking (user can fix manually)
- **Failure**: If 5 iterations exhausted with remaining critical/important issues, review fails
- **Commits are free**: No review gate on individual commits, only on PR creation
