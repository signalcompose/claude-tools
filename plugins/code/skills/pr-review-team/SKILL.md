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

Review criteria: agents read `${CLAUDE_PLUGIN_ROOT}/skills/review-commit/references/review-criteria.md` — leader does NOT read this file (agents handle criteria, leader handles integration).

### Agent Launch Failure Handling

If any reviewer agent fails to launch:

| Agent | Failure Severity | Action |
|-------|-----------------|--------|
| code-reviewer | **CRITICAL** | Abort review. Report failure and STOP. |
| silent-failure-hunter | WARNING | Continue with remaining reviewers. Note in report. |
| pr-test-analyzer | WARNING | Continue with remaining reviewers. Note in report. |
| comment-analyzer | WARNING | Continue with remaining reviewers. Note in report. |

If ALL agents fail: report error and STOP.

## Step 3: Collect CI Results

Leader collects CI data (do NOT delegate):

### Check Status

```bash
gh pr checks <PR番号>
```

Parse output for FAIL/PASS/PENDING status per check.

### CI Pending Strategy

If any checks are PENDING:

```
FOR attempt = 1 TO 3:
  1. Wait 30 seconds
  2. Re-check: gh pr checks <PR番号>
  3. IF all checks resolved → BREAK
END FOR
```

If still PENDING after 3 attempts (90 seconds total):
- Continue review **without CI results**
- Add to final report: "CI: PENDING (timed out — manual verification recommended)"

### Get Failure Details

For each failed check:
```bash
# Get failed checks
gh pr checks <PR番号> --json name,bucket,link --jq '.[] | select(.bucket == "fail")'

# Get failed log
gh run view <run-id> --log-failed
```

### Collect Review Comments

```bash
gh pr view <PR番号> --json comments --jq '.comments[].body'
```

Also check for Claude Code review comments (automated review feedback).

### HEAD Filtering

Avoid sending already-fixed issues to the fixer.

```
FOR each CI issue or review comment:
  1. Extract the file path and line number from the issue
  2. Get current diff: gh pr diff <PR番号>
  3. Check if the referenced line still exists in the current HEAD
  4. IF the line has been modified or removed since the issue was reported:
       → Mark as "already addressed" — do NOT send to fixer
  5. ELSE:
       → Include in the fixer's issue list
END FOR
```

### Sandbox Notes

`gh` commands may fail in sandboxed environments due to TLS certificate restrictions.
Use `dangerouslyDisableSandbox: true` when calling `gh` via Bash tool.
This is safe for read-only operations like `gh pr view`, `gh pr checks`, and `gh run view`.

## Step 4: Integrate & Send to Fixer

**MANDATORY**: Combine reviewer results + CI results into **one single message** to fixer.
Split messages are prohibited (message loss risk).

Security checklist: read `${CLAUDE_PLUGIN_ROOT}/skills/pr-review-team/references/security-checklist.md` now (deferred from Step 2 to save context).

### Fixer Message Template

Structure the message to fixer using this template:

```
## Critical Issues
[List critical issues from all reviewers + CI failures]
- Source: <reviewer-name>
- File: <path>:<line>
- Issue: <description>

## Important Issues
[List important issues]
- Source: <reviewer-name>
- File: <path>:<line>
- Issue: <description>

## Security Checklist Failures
[List security checklist items that failed]
- Check: <checklist-item>
- File: <path>:<line>
- Issue: <description>

## Already Addressed (informational — do NOT fix)
[List issues filtered out by HEAD filtering logic]
- Source: <reviewer-name or CI>
- Reason: Line modified/removed in current HEAD
```

## Step 5: Iterative Fix Loop

Determine max iterations:

```bash
# Check if running inside dev-cycle
if [ -f .claude/dev-cycle.state.json ]; then
  MAX_ITERATIONS=2   # Preserve context for retrospective
else
  MAX_ITERATIONS=5   # Standalone mode
fi
```

```
FOR iteration = 1 TO $MAX_ITERATIONS:
  1. Fixer applies fixes
  2. Run test command (detected in Step 1)
  3. IF tests fail → Fixer retries
  4. Re-review with code-reviewer
  5. IF critical = 0 AND important = 0 AND security = all pass:
       → BREAK
END FOR
```

If iteration limit reached with remaining issues: report to user, do NOT merge.

In dev-cycle mode (MAX_ITERATIONS=2): if issues remain after 2 iterations, report remaining issues and STOP. User decides whether to continue manually.

## Step 6: Report & Shutdown

Report summary:
- Issues found / fixed / remaining
- Iterations performed
- Security checklist status
- CI status (including any PENDING timeouts)
- Agents that failed to launch (if any)

**Do NOT merge** — wait for user's explicit instruction.

### Shutdown Procedure

Send `shutdown_request` to all agents individually via SendMessage (one message per agent):
- code-reviewer, silent-failure-hunter, pr-test-analyzer, comment-analyzer, code-fixer

Wait up to 30 seconds for `shutdown_response` from each agent.

Then call TeamDelete.

**If TeamDelete fails** (agents did not respond to shutdown):
1. Note the team name used in the TeamCreate step (store as `TEAM_NAME`)
2. Force-delete team directories using Bash with `dangerouslyDisableSandbox: true`:
   ```bash
   rm -rf ~/.claude/teams/"${TEAM_NAME:?}"/ ~/.claude/tasks/"${TEAM_NAME:?}"/
   ```
   The `${TEAM_NAME:?}` guard prevents `rm -rf` from running with an empty path.
3. Inform user: "Team force-deleted. If agent polling continues, restart Claude Code."
