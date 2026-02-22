---
name: dev-cycle
description: |
  This skill runs the full development cycle: sprint, audit, ship, retrospective.
  It chains code:sprint-impl, code:audit-compliance, code:shipping-pr, code:retrospective autonomously.
  MANDATORY: When a user's plan or instructions explicitly reference "/code:dev-cycle" or "code:dev-cycle",
  you MUST invoke this skill via the Skill tool — do NOT manually implement the plan yourself.
  This skill should be used when the user says "full cycle", "implement and ship", "dev cycle",
  "全サイクル", "実装して出荷まで", "フルサイクル",
  "implement the plan", "プランを実装", "フェーズNを実装", "phase N implementation",
  "スプリントして", "実装してください" (when full cycle compliance is expected).
  Resilient to context loss — each phase is self-contained and can resume independently.
user-invocable: true
argument-hint: <plan-source>
---

# Dev Cycle

Run the full development cycle: **implement, audit, ship, retrospective**.

Chains four skills in sequence, handling transitions automatically.
Each phase is self-contained, making it resilient to context window exhaustion.

## Input

`$ARGUMENTS` is passed directly to `code:sprint-impl`. Can be:

- A GitHub Issue URL
- A plan file path
- Inline description
- Empty (auto-detect next phase from `docs/plans/`)

## Execution Flow

### Stage 0: State Initialization (auto-chain enforcement)

Create the state file to enable the Stop hook auto-chain mechanism:

```bash
if [ ! -f .claude/dev-cycle.state.json ]; then
  mkdir -p .claude && echo '{"stage": "sprint", "metrics": {}}' > .claude/dev-cycle.state.json
fi
```

> **Compaction Resilience**: The UserPromptSubmit hook (`dev-cycle-guard.sh`)
> pre-creates this file when `/code:dev-cycle` is detected. If compaction occurs
> before this step executes, the file already exists. The `if` guard ensures
> idempotency — existing state is never overwritten.

This file drives the Stop hook (`dev-cycle-stop.sh`) which blocks
Claude from stopping until all 4 stages complete. If Claude tries to stop mid-cycle,
the hook reads this file and instructs Claude to invoke the next skill.

**Output to user** (in user's configured language):
```
Context Budget Management: Active
- PostToolUse hook がコンテキスト残量を追跡します
- ステージ間遷移時に予算チェックを実施します
- 予算不足の場合、状態を保存して安全に停止します
- 次セッションで再開コマンドが案内されます
```

### Context Budget Management

ステージ間遷移の前にコンテキスト予算を確認する。
詳細は `${CLAUDE_PLUGIN_ROOT}/skills/dev-cycle/references/context-budget.md` を参照。

```bash
cat .claude/.context-budget.json 2>/dev/null || echo '{"remaining":100}'
```

| 遷移先 | 必要残量 | 不足時のアクション |
|-------|---------|-----------------|
| audit | >= 50% | 停止。再開: `/code:audit-compliance` |
| ship | >= 30% | 停止。再開: `/code:shipping-pr` |
| retrospective | >= 15% | 停止。再開: `/code:retrospective` |

予算データなしの場合は続行（後方互換）。

### Stage 0.5: Package Security Audit (conditional)

Run after sprint completes. Check if dependency files were modified:

```bash
git diff $(git merge-base HEAD main)...HEAD --name-only | \
  grep -qE '(package\.json|package-lock\.json|Cargo\.toml|requirements\.txt|go\.mod|Gemfile|pyproject\.toml)$'
```

If the command exits 0 (dependency changes detected), run the audit per `${CLAUDE_PLUGIN_ROOT}/skills/dev-cycle/references/package-security-audit.md`.
If no dependency changes detected, skip this stage.

### Stage 1: Sprint Implementation

Invoke `code:sprint-impl $ARGUMENTS` via Skill tool.

**Exit condition**: Phase 9 summary report generated.
**If sprint fails**: Report failure details and STOP. Clean up first:
```bash
rm -f .claude/dev-cycle.state.json .claude/.context-budget.json
```

**On success — IMMEDIATELY (no intermediate text output):**

1. Context budget check:
   ```bash
   cat .claude/.context-budget.json 2>/dev/null
   ```
   If remaining < 50%: update state file with stopped info, output resumption guide, STOP.

2. Save sprint metrics and advance stage:
   ```bash
   jq '.stage = "audit" | .metrics.sprint = {files_changed: N, tests: "X passed", coverage: "Y%"}' \
     .claude/dev-cycle.state.json > .claude/dev-cycle.state.json.tmp && \
     mv .claude/dev-cycle.state.json.tmp .claude/dev-cycle.state.json
   ```
   Replace N, X, Y% with actual values from Phase 9 summary report.
   Then invoke via Skill tool: `code:audit-compliance` — do NOT write a status summary first.
   (Stage summaries are included in the final combined report only.)

### Stage 2: Compliance Audit

After sprint completes, invoke `code:audit-compliance` via Skill tool.

**Exit conditions**:

- **All pass / partial**: Proceed to Stage 3
- **Any HIGH-impact fail**: Attempt 1 recovery per audit recommendations. Re-audit if recovery succeeds. STOP if still failing. Clean up first:
  ```bash
  rm -f .claude/dev-cycle.state.json .claude/.context-budget.json
  ```

**On success — IMMEDIATELY (no intermediate text output):**

1. Context budget check:
   ```bash
   cat .claude/.context-budget.json 2>/dev/null
   ```
   If remaining < 30%: update state file with stopped info, output resumption guide, STOP.

2. Save audit metrics and advance stage:
   ```bash
   jq '.stage = "ship" | .metrics.audit = {score: "X/5"}' \
     .claude/dev-cycle.state.json > .claude/dev-cycle.state.json.tmp && \
     mv .claude/dev-cycle.state.json.tmp .claude/dev-cycle.state.json
   ```
   Replace X with actual audit score.
   Then invoke via Skill tool: `code:shipping-pr` — do NOT write a status summary first.
   (Stage summaries are included in the final combined report only.)

### Stage 3: Ship PR

After audit passes, invoke `code:shipping-pr` via Skill tool.

**Exit condition**: PR URL returned in summary report.
**If shipping fails after max iterations**: Clean up and STOP:
```bash
rm -f .claude/dev-cycle.state.json .claude/.context-budget.json
```

**On success — IMMEDIATELY (no intermediate text output):**

1. Context budget check:
   ```bash
   cat .claude/.context-budget.json 2>/dev/null
   ```
   If remaining < 15%: update state file with stopped info, output resumption guide, STOP.

2. Save ship metrics and advance stage:
   ```bash
   jq '.stage = "retrospective" | .metrics.ship = {commit: "HASH MESSAGE", pr_url: "URL"}' \
     .claude/dev-cycle.state.json > .claude/dev-cycle.state.json.tmp && \
     mv .claude/dev-cycle.state.json.tmp .claude/dev-cycle.state.json
   ```
   Replace HASH, MESSAGE, URL with actual values from shipping report.
   Then invoke via Skill tool: `code:retrospective` — do NOT write a status summary first.
   (Stage summaries are included in the final combined report only.)

### Stage 4: Retrospective

After shipping completes, invoke `code:retrospective` via Skill tool.

**Exit condition**: Retrospective report generated and artifacts committed.
**If issues found**: Apply fixes, re-review, commit, push to existing PR branch.
**If retrospective fails after repeated attempts**: Clean up and STOP:
```bash
rm -f .claude/dev-cycle.state.json .claude/.context-budget.json
```

**On success**:

1. Save retrospective metrics to state file:
   ```bash
   jq '.metrics.retrospective = {fixes_applied: N, learnings: "X new, Y merged, Z resolved"}' \
     .claude/dev-cycle.state.json > .claude/dev-cycle.state.json.tmp && \
     mv .claude/dev-cycle.state.json.tmp .claude/dev-cycle.state.json
   ```
   Replace N, X, Y, Z with actual values from retrospective report.

2. Read metrics for final report, then clean up:
   ```bash
   cat .claude/dev-cycle.state.json
   rm -f .claude/dev-cycle.state.json .claude/.context-budget.json
   ```

## Resumption Guide

### Budget-Stopped Resumption

If `.claude/dev-cycle.state.json` contains `"status": "stopped"`:

```bash
cat .claude/dev-cycle.state.json
```

`skipped_stages` の最初の要素から再開:
- `["audit", ...]` → `/code:audit-compliance`
- `["ship", ...]` → `/code:shipping-pr`
- `["retrospective"]` → `/code:retrospective`

再開前に state ファイルをリセット:
```bash
echo '{"stage": "<resume_stage>"}' > .claude/dev-cycle.state.json
```

### Manual Resumption

If context is exhausted mid-cycle, resume using the appropriate individual skill:

| State                     | How to detect                         | Resume command                  |
| ------------------------- | ------------------------------------- | ------------------------------- |
| Sprint incomplete         | No new source files / tests failing   | `code:sprint-impl $ARGUMENTS`   |
| Sprint done, not audited  | Source + tests exist, no audit report | `code:audit-compliance`         |
| Audited, not shipped      | Audit passed, no PR exists            | `code:shipping-pr`              |
| Shipped, no retrospective | PR exists, no retro commit            | `code:retrospective`            |
| Retrospective done        | Retro commit in git log               | Done                            |

Detection logic (run at start if resuming):

```bash
# Check PR existence: use GitHub MCP tool mcp__github__list_pull_requests (head="<current-branch>")
git diff --stat $(git merge-base HEAD main)...HEAD
git log --oneline -5
```

## Summary Report

After all 4 stages complete, read metrics from the state file (compaction-safe source):

```bash
cat .claude/dev-cycle.state.json 2>/dev/null
```

Use the `metrics` field to populate the report. If metrics are also available in context memory, prefer those (more detailed). Output:

```
## Dev Cycle Complete

### Sprint
- Files created/modified: N
- Tests: X passed, coverage: Y%

### Audit
- Score: X/5

### Ship
- Commit: <hash> <message>
- PR: <url>

### Retrospective
- Fixes applied: N
- Learnings updated: N new, N merged, N resolved

### Metrics
- Total: ~Xm
```

**Cleanup**: Ensure `.claude/dev-cycle.state.json` and `.claude/.context-budget.json` have been deleted. If they still exist, delete them now.

## Absolute Prohibitions

The following actions are **absolutely prohibited**. Violations result in HIGH FAIL in PROCESS audit:

1. **Manual review-approval hash creation** — NEVER directly write to `/tmp/claude/review-approved-*` files. The flag file is created by the `shipping-pr` / `review-commit` workflow after the code-reviewer Agent reports 0 critical and 0 important issues. Manual creation (`echo "$HASH" > /tmp/claude/review-approved-*`) is a violation.
2. **Manual code review** — The main agent must NOT read diff and judge "no issues" itself. Always delegate to `pr-review-toolkit:code-reviewer` Agent.
3. **Skipping `/code:shipping-pr` skill** — Ad-hoc `git push` + PR creation is prohibited. Final shipping must go through `/code:shipping-pr`. Mid-sprint intermediate commits are exempt.
4. **Pre-commit hook circumvention** — `--no-verify` flag usage is prohibited. If a hook blocks, resolve the root cause and retry.
5. **Responding in non-configured language** — All user-facing output MUST follow the language configured in user settings. SKILL.md being in English does NOT change the output language. Technical terms and code identifiers may remain in English.
6. **Deleting state file during active cycle** — NEVER delete `.claude/dev-cycle.state.json` while a dev-cycle is in progress. The state file drives all hook enforcement (Stop, PostToolUse, UserPromptSubmit). Only the Stop hook or explicit cycle-end cleanup may remove this file.

## Main Agent Guide

**Read only during Stage 1 (sprint)**: `${CLAUDE_PLUGIN_ROOT}/skills/dev-cycle/references/main-agent-guide.md`

## Output Rules

- User-facing output: follow user's configured language setting
- SKILL.md is English → output language is still determined by user settings
- Technical terms, code identifiers: English OK
- Commit titles: English (project convention), commit bodies: user's configured language
- Violations are flagged as PROCESS audit findings

## Serena Integration

**Read only if Serena MCP tools (`mcp__plugin_serena_serena__*`) are available**: `${CLAUDE_PLUGIN_ROOT}/skills/_shared/serena-integration.md`

If Serena is unavailable, skip all Serena phases. Essential information is also in `CLAUDE.md` and `docs/`.

## Error Handling

- **Sprint failure**: Report and STOP (most common: type errors, test failures)
- **Audit HIGH fail**: Attempt 1 recovery, then STOP if still failing
- **Ship failure**: Follows `code:shipping-pr` error handling (3 review iterations max)
- **Context approaching limit**: Save state to Serena memory, output resumption guide

## Important Notes

- This skill runs **autonomously** — no user confirmation between stages
- Each sub-skill is invoked via the Skill tool (not inlined)
- Timing metrics recorded in `docs/research/workflow-recording.md`
- Use GitHub MCP for all GitHub operations (not `gh` CLI)
- All user-facing output MUST follow the user's configured language setting — SKILL.md being in English does not change this
