---
name: pr-review-team
description: |
  Team-based PR review with specialized parallel agents, CI integration, and iterative fix loop.
  Use when: "review this PR", "PR review", "PRレビュー",
  "PRをレビューして", "チームでPRレビュー".
user-invocable: false
---

# PR Review Team

**MANDATORY first step — BEFORE any Agent / Read / bash work:**

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh init <PR番号>
```

State init gives the leader (and the user reading the transcript) a visible
audit trail of the review loop. Retroactively creating the state file after
agents have already spawned defeats that purpose — if you skipped init,
restart the loop rather than paper over it. Run init now.

---

**MANDATORY**: This skill runs a complete review-fix-re-review loop using Subagents (NOT Agent Teams).

The leader MUST:
1. Initialize state and gather PR context (Step 1)
2. Select and launch the parallel reviewer subagents (Step 2 — the selector decides which of the 4 run)
3. Run CI checks via script (Step 3)
4. Integrate results + security checklist (Step 4)
5. If critical > 0 OR important > 0 OR security != "all_pass": enter fix loop (Step 5)
6. Report results and cleanup (Step 6)

🔴 These steps are mandatory. The leader is accountable for completing every step — skipping is a workflow violation.

## Step 1: Initialize & Identify Target PR

### Initialize State

Run immediately (creates the active-review state file for audit visibility):

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

### Select reviewers (token discipline)

Run the deterministic selector FIRST and launch only the reviewers it returns:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/select-reviewers.sh <PR番号>
```

Parse the `REVIEWERS:` line. `code-reviewer` is ALWAYS included. Docs/config-only
PRs skip reviewers that have nothing to analyze in the changed files (e.g. a
Markdown-only PR skips `silent-failure-hunter` and `pr-test-analyzer`). The script
prints a `DECISION:` line per reviewer — do NOT drop any reviewer it did not skip,
and do NOT add one it skipped. On any failure it fails open (all 4).

**MANDATORY**: Launch ALL selected reviewers in a SINGLE message using parallel
Agent tool calls. Do NOT use TeamCreate or Task tool. Use the Agent tool directly.

🔴 **Subagent prompt requirement (Issue #245)** — Agent tool で spawn される subagent は orchestrator の SKILL 本文を見ない。以下のガード文をすべての subagent prompt に **必ず含める**（reviewers, fixer, re-reviewers 共通）:

```
Tooling note: Do NOT set dangerouslyDisableSandbox: true on any bash call.
gh / git commands work inside the default sandbox (see ~/.claude/settings.json
sandbox.network.allowedDomains). Setting the bypass flag forces a user
approval prompt that auto mode intentionally refuses to auto-approve, which
breaks the review flow.
```

省略すると subagent が `gh pr diff` 等で defensive に bypass を要求し、ユーザーに承認プロンプトが連発する。

🔴 **Review scope discipline (token cost)** — include this block VERBATIM in every
reviewer / re-reviewer prompt (in addition to the Tooling note above). It curbs the
largest hidden cost: reviewers freely exploring files outside the diff.

```
Scope: base your review ONLY on `gh pr diff <PR>` and the changed files it lists.
Do NOT explore or read files the diff does not touch or directly reference.
Output: return ONLY findings you hold at >=80% confidence, each as one line
`severity | file:line | issue`. No prose preamble, no summary, no restating the diff.
```

Do NOT add this scope block to the fixer prompt — the fixer needs to read
surrounding code to apply correct fixes.

Launch in parallel (one message, one Agent call per SELECTED reviewer):

1. `Agent(subagent_type: "pr-review-toolkit:code-reviewer", model: "sonnet", prompt: "<criteria path> + <copy the Tooling note block above verbatim> + <task>")`
2. `Agent(subagent_type: "pr-review-toolkit:silent-failure-hunter", model: "sonnet", prompt: "<criteria path> + <copy the Tooling note block above verbatim> + <task>")`
3. `Agent(subagent_type: "pr-review-toolkit:pr-test-analyzer", model: "sonnet", prompt: "<criteria path> + <copy the Tooling note block above verbatim> + <task>")`
4. `Agent(subagent_type: "pr-review-toolkit:comment-analyzer", model: "haiku", prompt: "<criteria path> + <copy the Tooling note block above verbatim> + <task>")`

Launch ONLY the reviewers in the selector's `REVIEWERS:` set — the four above are
templates, and `code-reviewer` is always present. Include BOTH the Tooling note and
the Review scope discipline block (verbatim) in every reviewer prompt.

Results return automatically. No shutdown procedure needed.

Review criteria: include `${CLAUDE_PLUGIN_ROOT}/references/review-criteria.md` path in each agent prompt — agents read criteria, leader handles integration.

### Agent Launch Failure Handling

| Agent | Failure Severity | Action |
|-------|-----------------|--------|
| code-reviewer | **CRITICAL** | Abort review. Report failure and STOP. |
| silent-failure-hunter | WARNING | Continue with remaining reviewers. Note in report. |
| pr-test-analyzer | WARNING | Continue with remaining reviewers. Note in report. |
| comment-analyzer | WARNING | Continue with remaining reviewers. Note in report. |

This table applies ONLY to reviewers the selector chose to launch. A reviewer the
selector **skipped** (its `DECISION: SKIP` line) is NOT a launch failure — track it
separately and report it as "skipped by selector (reason)", never as "failed to launch".

In round 2 and later, a reviewer omitted because it is neither in `reporters` nor
newly added by the selector is also NOT a launch failure. Report it separately as
"skipped due to round-2 selective re-review (no prior findings)", not as "skipped by
selector" or "failed to launch".

### Update State

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> reviewers_done true
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> phase reviewed
```

### Record Reporters (for round-2 selective re-review)

🔴 **MANDATORY** — skipping this step makes the restart set wrongly narrow and
silently degrades re-review coverage by dropping reviewers that reported real issues.

After aggregating Step 2 results, record which reviewers reported Critical or
Important findings (space-separated names; use the literal string "none" if
none did — the format and rationale are defined once, in Step 5.3):

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> reporters "<reviewer名 space区切り、または none>"
```

If this write fails in round 1, do NOT treat it as `reporters=none`. The Step 5.3
option to retain the previous round's reporters value is unavailable because no
previous round exists; retry writing the actual space-separated set of reviewers
that reported Critical or Important findings with `pr-review-state.sh set <PR番号>
reporters "..."`. If that write also fails, re-launch all reviewers chosen by the
selector and explicitly note in the Step 6 report: "reporters persistence failed,
so round 2 will re-launch the full REVIEWERS set from the selector as a safe fallback."

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
Applying fixes without the fixer agent is a workflow violation.

🔴 MANDATORY — Security Checklist
Read NOW (mandatory — record after reading):
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
After fixer applies fixes, re-invoke reviewers using the set defined in step 3
below (code-reviewer + reporters + reviewers never previously launched). Narrowing
the set without first recording `reporters` is a workflow violation. Excluding
`code-reviewer` is a workflow violation. Skipping re-review entirely is a workflow
violation.

```
MAX_ITERATIONS=3

FOR iteration = 1 TO MAX_ITERATIONS:
  1. Spawn fixer subagent. Prefer Codex when available:
     - If `codex:codex-rescue` appears among the agent types you have been told
       are available for this session, use it as the fixer:
       Agent(subagent_type: "codex:codex-rescue", model: "sonnet",
             prompt: "<all findings> + <Step 2 tooling note on dangerouslyDisableSandbox>")
       If the Codex fixer invocation or execution ends in an error (including a
       process crash, timeout, or auth error), fall back to the Sonnet path below
       and resend the same findings.
     - Otherwise, fall back to the existing path unchanged:
       Agent(subagent_type: "general-purpose", model: "sonnet",
             prompt: "<all findings> + <Step 2 tooling note on dangerouslyDisableSandbox>")
     Send ALL findings in a single prompt (Critical + Important + Security failures).
     The fixer also runs gh/git — propagate the same sandbox guard (Issue #245).
     (Availability is a prompt-level check — subagent types can't be probed from bash.)

  2. Fixer applies fixes and runs tests
     IF tests fail after 2 retries → report to user, do NOT merge, BREAK

  3. Re-review: RE-RUN `select-reviewers.sh <PR番号>` to obtain the recomputed
     REVIEWERS set. Maintain a cumulative launched set for this review, initialized
     with the successfully launched round-1 reviewers and updated with every subsequent
     successful launch. Reviewers whose launch was classified as a launch failure per
     the Agent Launch Failure Handling table are NOT added to this set, so they remain
     eligible to be treated as newly added and relaunched in a subsequent round. Read the
     immediately preceding round's `reporters` state and split its space-separated
     value into a set (`"none"` means the empty set — the sentinel exists because
     `pr-review-state.sh set` rejects an empty string value). If `reporters` is missing
     or null, treat it as the empty set (equivalent to `"none"`). Launch exactly:
       {code-reviewer}
       UNION {reviewers from the immediately preceding round's reporters state}
       UNION {reviewers in the recomputed REVIEWERS set that are not in the cumulative
              launched set from all prior rounds}
     If reporters persistence has failed repeatedly, do not narrow the launch set;
     launch the full REVIEWERS set instead of this selective subset.
     Use parallel Agent tool calls as in Step 2, including BOTH the Tooling note and
     the Review scope discipline block in each subagent prompt. After all return,
     overwrite `reporters` with the space-separated names of reviewers that reported
     Critical or Important findings in this round; write the literal `"none"` if there
     were no such findings. This value is the reporters set for the next round.
     bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR番号> reporters "<reviewer名 space区切り、または none>"
     If this write fails, fail safe: do NOT treat it as `reporters=none`; retain the
     previous round's reporters value or re-launch all reviewers, and include the
     chosen fallback in the Step 6 report to the user.

  4. Collect fresh counts: fresh_critical, fresh_important, fresh_security

  5. Read GitHub bot feedback (claude-review Check Run + PR review comments)
     before declaring convergence. The leader MUST invoke at least one of:

       gh pr view <PR> --json reviews,comments
       gh api repos/OWNER/REPO/pulls/<PR>/comments
       gh api repos/OWNER/REPO/check-runs/<id>/annotations

     Then record:
       bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh set <PR> bot_feedback_read true

     Bot findings (if any) are merged into the next iteration's fixer message.

  6. Update state. `rereview_done` MUST be set at the end of the iteration
     — i.e. after the fresh reviewer agent in step 3 of THIS iteration has
     returned. Setting it before re-running the reviewer is a violation
     (see the VIOLATION block below).
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
- `rereview_done=true` requires ≥2 `pr-review-toolkit:code-reviewer` agent
  launches (initial + post-fix re-review). Setting the flag without spawning
  a fresh reviewer is a workflow violation — the leader would otherwise
  judge their own fix without independent verification.
- `bot_feedback_read=true` requires actually consulting GitHub bot output via
  `gh pr view --json reviews/comments`, `gh api .../pulls/N/comments`, or
  `gh api .../check-runs/.../annotations`.

## Step 6: Report & Cleanup

Report summary:
- Issues found / fixed / remaining
- Iterations performed
- Security checklist status
- CI status (including any PENDING timeouts)
- Reviewers not launched, one line per reviewer with its reason — these are NOT failures:
  - selector skip (e.g. "pr-test-analyzer: no source-code files")
  - round-2+ selective re-review skip (no prior findings)
- Agents that failed to launch (if any) — distinct from the not-launched list above
- Whether the fixer fell back from Codex to Sonnet, and the reason (process crash,
  timeout, or auth error)
- Any reporters state-write failure and the fail-safe used (retained prior reporters
  or re-launched all reviewers)

**Do NOT merge** — wait for user's explicit instruction.

### Cleanup

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/pr-review-state.sh cleanup <PR番号>
```

`cleanup` の挙動は state の状態によって分岐:

- **converged** (`final_critical=0` AND `final_important=0` AND `rereview_done=true`): `.state` → `.done` にリネーム（監査用、24 時間 TTL で自動削除）
- **未 converged**: `.state` を `rm -f`。完了していない review の痕跡を残さない

No shutdown procedure needed — subagents complete automatically.
