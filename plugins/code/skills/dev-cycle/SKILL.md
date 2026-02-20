---
name: dev-cycle
description: |
  This skill runs the full development cycle: sprint, audit, ship, retrospective.
  It chains code:sprint-impl, code:audit-compliance, code:shipping-pr, code:retrospective autonomously.
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
mkdir -p .claude && echo '{"stage": "sprint"}' > .claude/dev-cycle.state.json
```

This file drives the Stop hook (`dev-cycle-stop.sh`) which blocks
Claude from stopping until all 4 stages complete. If Claude tries to stop mid-cycle,
the hook reads this file and instructs Claude to invoke the next skill.

### Stage 0.5: Package Security Audit (conditional)

Only when adding new dependency packages. See `${CLAUDE_PLUGIN_ROOT}/skills/dev-cycle/references/package-security-audit.md`.

### Stage 1: Sprint Implementation

Invoke `code:sprint-impl $ARGUMENTS` via Skill tool.

**Exit condition**: Phase 9 summary report generated.
**If sprint fails**: Report failure details and STOP (delete `.claude/dev-cycle.state.json` first).

**On success — IMMEDIATELY (no intermediate text output):**

```bash
echo '{"stage": "audit"}' > .claude/dev-cycle.state.json
```

Then invoke via Skill tool: `code:audit-compliance` — do NOT write a status summary first.
(Stage summaries are included in the final combined report only.)

### Stage 2: Compliance Audit

After sprint completes, invoke `code:audit-compliance` via Skill tool.

**Exit conditions**:

- **All pass / partial**: Proceed to Stage 3
- **Any HIGH-impact fail**: Attempt 1 recovery per audit recommendations. Re-audit if recovery succeeds. STOP if still failing (delete `.claude/dev-cycle.state.json` first).

**On success — IMMEDIATELY (no intermediate text output):**

```bash
echo '{"stage": "ship"}' > .claude/dev-cycle.state.json
```

Then invoke via Skill tool: `code:shipping-pr` — do NOT write a status summary first.
(Stage summaries are included in the final combined report only.)

### Stage 3: Ship PR

After audit passes, invoke `code:shipping-pr` via Skill tool.

**Exit condition**: PR URL returned in summary report.
**If shipping fails after max iterations**: Delete `.claude/dev-cycle.state.json` and STOP.

**On success — IMMEDIATELY (no intermediate text output):**

```bash
echo '{"stage": "retrospective"}' > .claude/dev-cycle.state.json
```

Then invoke via Skill tool: `code:retrospective` — do NOT write a status summary first.
(Stage summaries are included in the final combined report only.)

### Stage 4: Retrospective

After shipping completes, invoke `code:retrospective` via Skill tool.

**Exit condition**: Retrospective report generated and artifacts committed.
**If issues found**: Apply fixes, re-review, commit, push to existing PR branch.
**If retrospective fails after repeated attempts**: Delete `.claude/dev-cycle.state.json` and STOP.

**On success**, clean up state file:

```bash
rm -f .claude/dev-cycle.state.json
```

## Resumption Guide

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
gh pr list --head $(git branch --show-current) --json url
git diff --stat $(git merge-base HEAD main)...HEAD
git log --oneline -5
```

## Summary Report

After all 4 stages complete, output a combined report:

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
- Skills updated: list

### Metrics
- Total: ~Xm
```

**Cleanup**: Ensure `.claude/dev-cycle.state.json` has been deleted. If it still exists, delete it now.

## Absolute Prohibitions

For violations and their impact, read `${CLAUDE_PLUGIN_ROOT}/skills/dev-cycle/references/prohibitions.md`.

## Main Agent Guide

For responsibilities, agent prompt guidelines, and commit patterns, read `${CLAUDE_PLUGIN_ROOT}/skills/dev-cycle/references/main-agent-guide.md`.

## Output Rules

For shared output language rules, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/output-rules.md`.

## Serena Integration

For context load, mid-sprint save, and post-sprint memory save, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/serena-integration.md`.

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
