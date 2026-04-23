---
name: pr-review-team
description: |
  Team-based PR review with specialized parallel agents, CI integration, and iterative fix loop.
  Use when: "review this PR", "PR review", "PRレビュー",
  "PRをレビューして", "チームでPRレビュー".
user-invocable: false
---

# PR Review Team

**MANDATORY**: This skill runs a complete review-fix-re-review loop using Subagents (NOT Agent Teams).

The leader MUST:
1. Initialize state and gather PR context (Step 1)
2. Launch 4 parallel reviewer subagents (Step 2)
3. Run CI checks via script (Step 3)
4. Integrate results + security checklist (Step 4)
5. If critical > 0 OR important > 0 OR security != "all_pass": enter fix loop (Step 5)
6. Report results and cleanup (Step 6)

🔴 Stop hooks verify workflow completion. Skipping steps will block the stop request.

## Step 1: Initialize & Identify Target PR

### Initialize State

Run immediately (creates the active-review flag file for Stop hook detection):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh init <PR番号>
```

### Resolve PR

- If user specified: use that number
- Otherwise: `gh pr view --json number --jq '.number' 2>/dev/null`

### Gather Context

- File overview: `gh pr diff <PR番号> --name-only`
- Base branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'` (fallback: `main`)
- Test command: detect from `package.json`, `Makefile`, `pytest.ini`, etc.
- Project rules: read project's CLAUDE.md if present

**Note**: `gh` commands rely on `sandbox.network.allowedDomains` (github.com, api.github.com) in `~/.claude/settings.json` to run inside the sandbox without prompts. Do NOT pass `dangerouslyDisableSandbox: true` defensively — the flag forces an auto-mode-refused approval prompt that breaks the review flow (see Issue #245).

## Step 2: Parallel Review (Subagents)

**MANDATORY**: Launch ALL 4 reviewers in a SINGLE message using parallel Agent tool calls.
Do NOT use TeamCreate or Task tool. Use the Agent tool directly.

🔴 **Subagent prompt requirement (Issue #245)** — Agent tool で spawn される subagent は orchestrator の SKILL 本文を見ない。以下のガード文をすべての subagent prompt に **必ず含める**（reviewers, fixer, re-reviewers 共通）:

```
Tooling note: Do NOT set dangerouslyDisableSandbox: true on any bash call.
gh / git commands work inside the default sandbox (see ~/.claude/settings.json
sandbox.network.allowedDomains). Setting the bypass flag forces a user
approval prompt that auto mode intentionally refuses to auto-approve, which
breaks the review flow.
```

省略すると subagent が `gh pr diff` 等で defensive に bypass を要求し、ユーザーに承認プロンプトが連発する。

Launch in parallel (one message, 4 Agent tool calls):

1. `Agent(subagent_type: "pr-review-toolkit:code-reviewer", model: "sonnet", prompt: "<criteria path> + <copy the Tooling note block above verbatim> + <task>")`
2. `Agent(subagent_type: "pr-review-toolkit:silent-failure-hunter", model: "sonnet", prompt: "<criteria path> + <copy the Tooling note block above verbatim> + <task>")`
3. `Agent(subagent_type: "pr-review-toolkit:pr-test-analyzer", model: "sonnet", prompt: "<criteria path> + <copy the Tooling note block above verbatim> + <task>")`
4. `Agent(subagent_type: "pr-review-toolkit:comment-analyzer", model: "haiku", prompt: "<criteria path> + <copy the Tooling note block above verbatim> + <task>")`

Results return automatically. No shutdown procedure needed.

Review criteria: include `${CLAUDE_PLUGIN_ROOT}/references/review-criteria.md` path in each agent prompt — agents read criteria, leader handles integration.

### Agent Launch Failure Handling

| Agent | Failure Severity | Action |
|-------|-----------------|--------|
| code-reviewer | **CRITICAL** | Abort review. Report failure and STOP. |
| silent-failure-hunter | WARNING | Continue with remaining reviewers. Note in report. |
| pr-test-analyzer | WARNING | Continue with remaining reviewers. Note in report. |
| comment-analyzer | WARNING | Continue with remaining reviewers. Note in report. |

### Update State

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> reviewers_done true
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> phase reviewed
```

## Step 3: CI Check

Run the CI wait script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/wait-ci-checks.sh <PR番号>
```

Parse the STATUS line from output:
- **PASS**: All checks passed
- **FAIL**: Get failure details with `gh run view <run-id> --log-failed`
- **TIMEOUT**: Continue review, note "CI: PENDING (timed out)" in report
- **ERROR**: Report the failure and stop — network / auth / PR-number issues won't be solved by sandbox bypass. Investigate the underlying cause (e.g. `gh auth status`, check PR number) rather than toggling `dangerouslyDisableSandbox`.

Also collect review comments:
```bash
gh pr view <PR番号> --json comments --jq '.comments[].body'
```

### HEAD Filtering

Avoid sending already-fixed issues to the fixer:
- For each CI issue or review comment, check if the referenced line still exists in current HEAD
- Mark modified/removed lines as "already addressed" — do NOT send to fixer

## Step 4: Integrate & Prepare Fixer Message

🔴 VIOLATION — Direct Editing Prohibited
ALL fixes MUST be delegated to the fixer subagent in Step 5.
Using Edit/Write tools directly to apply fixes is a workflow violation.
The Stop hook will block completion if the fixer agent was not used.

🔴 MANDATORY — Security Checklist
Read NOW (Stop hook verifies this was read):
`${CLAUDE_PLUGIN_ROOT}/skills/pr-review-team/references/security-checklist.md`

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> security_done true
```

### Fixer Message Template

Structure ALL findings into one single message (split messages prohibited):

```
## Critical Issues
- Source: <reviewer-name>
- File: <path>:<line>
- Issue: <description>

## Important Issues
- Source: <reviewer-name>
- File: <path>:<line>
- Issue: <description>

## Security Checklist Failures
- Check: <checklist-item>
- File: <path>:<line>
- Issue: <description>

## Already Addressed (informational — do NOT fix)
- Source: <reviewer-name or CI>
- Reason: Line modified/removed in current HEAD

Security Checklist: ALL PASS (N items checked) / HAS FAILURES (list)
```

If all pass: "Security Checklist: ALL PASS (N items checked)"

## Step 5: Fix Loop

🔴 MANDATORY: If Step 4 produced ANY critical or important issues, or security failures, this step MUST execute.

🔴 VIOLATION — Re-review Required After Fixes
After fixer applies fixes, ALL 4 reviewers MUST be re-invoked (same parallel pattern as Step 2).
Skipping re-review is a workflow violation.

```
MAX_ITERATIONS=3

FOR iteration = 1 TO MAX_ITERATIONS:
  1. Spawn fixer subagent:
     Agent(subagent_type: "general-purpose", model: "sonnet",
           prompt: "<all findings> + <Step 2 tooling note on dangerouslyDisableSandbox>")
     Send ALL findings in a single prompt (Critical + Important + Security failures).
     The fixer also runs gh/git — propagate the same sandbox guard (Issue #245).

  2. Fixer applies fixes and runs tests
     IF tests fail after 2 retries → report to user, do NOT merge, BREAK

  3. Re-review: Launch ALL 4 reviewers again (parallel Agent tool calls, same as Step 2,
     including the tooling note in each subagent prompt)

  4. Collect fresh counts: fresh_critical, fresh_important, fresh_security

  5. Read GitHub bot feedback (claude-review Check Run + PR review comments)
     before declaring convergence. The Stop hook enforces this via transcript
     inspection — the leader MUST invoke at least one of:

       gh pr view <PR> --json reviews,comments
       gh api repos/OWNER/REPO/pulls/<PR>/comments
       gh api repos/OWNER/REPO/check-runs/<id>/annotations

     Then record:
       bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR> bot_feedback_read true

     Bot findings (if any) are merged into the next iteration's fixer message.

  6. Update state. `rereview_done` MUST be set at the end of the iteration
     — i.e. after the fresh reviewer agent in step 3 of THIS iteration has
     returned. Setting it before re-running the reviewer is a violation
     (see the VIOLATION block below — the Stop hook will detect it via
     transcript launch count).
     bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> fixer_done true
     bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> rereview_done true
     bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> iterations <N>
     bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> final_critical <count>
     bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> final_important <count>

  7. IF fresh_critical = 0 AND fresh_important = 0 AND fresh_security = "all_pass" → BREAK
END FOR
```

If iteration limit reached with remaining issues: report to user, do NOT merge.

🔴 VIOLATION — Self-declaring Convergence Without Evidence
The Stop hook enforces (Issue #236 follow-up):
- `rereview_done=true` requires the transcript to show ≥2
  `pr-review-toolkit:code-reviewer` agent launches (initial + post-fix
  re-review). Manually setting `rereview_done=true` without spawning a fresh
  reviewer agent is a workflow violation — the leader would otherwise judge
  their own fix without independent verification.
- `bot_feedback_read=true` requires either the state flag to be set after
  actually consulting GitHub bot output, or the transcript to contain a
  matching `gh pr view --json reviews/comments`, `gh api .../pulls/N/comments`,
  or `gh api .../check-runs/.../annotations` call.

## Step 6: Report & Cleanup

Report summary:
- Issues found / fixed / remaining
- Iterations performed
- Security checklist status
- CI status (including any PENDING timeouts)
- Agents that failed to launch (if any)

**Do NOT merge** — wait for user's explicit instruction.

### Cleanup

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh cleanup <PR番号>
```

`cleanup` の挙動は state の状態によって分岐:

- **converged** (`final_critical=0` AND `final_important=0` AND `rereview_done=true`): `.state` → `.done` にリネーム。`verify-workflow.sh` (Stop hook) は `.done` を「完了済みレビュー」として認識し、後続 session で transcript に pr-review-team 起動痕跡があっても誤 block しない。`.done` は 24 時間後に TTL で自動削除
- **未 converged**: `.state` を `rm -f` (従来通り)。完了していない review の痕跡を残さない

No shutdown procedure needed — subagents complete automatically.
