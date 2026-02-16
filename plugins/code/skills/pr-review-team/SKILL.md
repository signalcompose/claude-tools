---
name: pr-review-team
description: |
  Team-based PR review with specialized parallel agents, CI integration, and iterative fix loop.
  Use when: "review this PR", "PR review", "PRレビュー",
  "PRをレビューして", "チームでPRレビュー".
user-invocable: false
---

# PR Review Team

## Step 1: Identify Target PR & Detect Project Context

Resolve the PR number:
- If user specified: use that number
- Otherwise: !`gh pr view --json number --jq '.number' 2>/dev/null`

Gather context:
- File overview: `gh pr diff <PR番号> --name-only` (fallback: `git diff <base>...HEAD --name-only`)
- Base branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'` (fallback: `main`)
- Test command: detect from `package.json`, `Makefile`, `pytest.ini`, etc.
- Project rules: read project's CLAUDE.md if present

**Note**: `gh` commands may require `dangerouslyDisableSandbox: true` for TLS issues.

## Step 2: Create Review Team

**MANDATORY**: Use TeamCreate to create the team, then spawn agents with Task tool.

Team structure:
```
Team Lead (yourself)
├─ Reviewer 1: pr-review-toolkit:code-reviewer
├─ Reviewer 2: pr-review-toolkit:silent-failure-hunter
├─ Reviewer 3: pr-review-toolkit:pr-test-analyzer
├─ Reviewer 4: pr-review-toolkit:comment-analyzer
└─ Fixer: general-purpose (code-fixer)
```

Launch all 4 reviewers **in parallel** via Task tool.

Review criteria: read `${CLAUDE_PLUGIN_ROOT}/skills/review-commit/references/review-criteria.md`.
Security checklist: read `${CLAUDE_PLUGIN_ROOT}/skills/pr-review-team/references/security-checklist.md`.

## Step 3: Collect CI Results

Leader collects CI data (do NOT delegate):
- `gh pr checks <PR番号>` — check status
- On FAILURE: `gh run view <run-id> --log-failed` — failure details
- Claude review comments: `gh pr view <PR番号> --json comments`

For HEAD filtering logic, read `${CLAUDE_PLUGIN_ROOT}/skills/pr-review-team/references/ci-integration.md`.

## Step 4: Integrate & Send to Fixer

**MANDATORY**: Combine reviewer results + CI results into **one single message** to fixer.
Split messages are prohibited (message loss risk).

Priority order:
1. Critical issues
2. Important issues
3. Security checklist failures

## Step 5: Iterative Fix Loop

```
FOR iteration = 1 TO 5:
  1. Fixer applies fixes
  2. Run test command (detected in Step 1)
  3. IF tests fail → Fixer retries
  4. Re-review with code-reviewer
  5. IF critical = 0 AND important = 0 AND security = all pass:
       → BREAK
END FOR
```

If iteration limit reached with remaining issues: report to user, do NOT merge.

## Step 6: Report & Shutdown

Report summary:
- Issues found / fixed / remaining
- Iterations performed
- Security checklist status

**Do NOT merge** — wait for user's explicit instruction.

Send `shutdown_request` to all agents via SendMessage, then TeamDelete.
