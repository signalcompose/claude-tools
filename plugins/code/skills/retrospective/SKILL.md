---
name: retrospective
description: |
  This skill runs a post-sprint retrospective with Auditor and Researcher agents.
  It verifies process compliance, analyzes code quality, and records metrics.
  This skill should be used when the user says "振り返り", "retrospective", "retro".
user-invocable: true
argument-hint: [branch-name]
---

# Retrospective

Run a structured retrospective after shipping.

## Purpose

Objectively verify the entire phase process. Check both output quality AND process compliance.

## Input

`$ARGUMENTS` (optional): Branch name to audit. If empty, uses current branch.

## Execution Flow

### Step 1: Determine Scope

```bash
git branch --show-current
git log --oneline $(git merge-base HEAD <base>)..HEAD
git diff --stat $(git merge-base HEAD <base>)...HEAD
```

Identify the base branch (from PR target or parent feature branch).

### Step 2: Spawn 2 Agents in Parallel

Spawn 2 agents using the Task tool (`subagent_type: "general-purpose"`, `model: "<choose per task>"`) in parallel.

**MANDATORY**: Always specify an explicit `model` parameter. Choose the appropriate model based on task complexity (`haiku` for lightweight, `sonnet` for standard, `opus` for complex reasoning). Never omit `model` (default `inherit` may fail in parallel spawning).

**MANDATORY** (Issue #245): Auditor and Researcher both invoke `git log` / `gh pr view` during analysis. Include in each agent prompt the sandbox tooling note defined in `${CLAUDE_PLUGIN_ROOT}/skills/pr-review-team/SKILL.md` Step 2 (the `Tooling note: Do NOT set dangerouslyDisableSandbox: true ...` block). Agent-spawned subagents do not see the orchestrator's SKILL body; omitting the note causes defensive sandbox-bypass approval prompts to the user.

Auditor and Researcher are independent — no inter-agent communication needed.

#### Agent 1: Auditor

5-principle compliance verification. For detailed prompt, read `${CLAUDE_PLUGIN_ROOT}/skills/retrospective/references/auditor-prompt.md`.

Output: PASS/PARTIAL/FAIL per principle with evidence.

#### Agent 2: Researcher

Code quality and architecture analysis. For detailed prompt, read `${CLAUDE_PLUGIN_ROOT}/skills/retrospective/references/researcher-prompt.md`.

Output: Strengths, Weaknesses, Recommendations, Metrics.

### Step 2.5: Autopilot phase reconciliation (Issue #248)

Runs only when `.claude/autopilot.state.json` exists (autopilot-driven runs). Fail open: any error here logs and continues — never blocks retrospective.

Goal: detect silent phase skips by comparing the session transcript against expected skill invocations and the declared `skip_log[]`.

```bash
STATE=.claude/autopilot.state.json
[ -f "$STATE" ] || skip_step
# Claude Code project slug: replace `/` and `_` with `-`, keep leading `-`.
PROJECT_SLUG=$(pwd | sed 's|[/_]|-|g')
TRANSCRIPT=$(ls -t "$HOME/.claude/projects/${PROJECT_SLUG}"/*.jsonl 2>/dev/null | head -1)
VIOLATIONS="$HOME/.claude/projects/${PROJECT_SLUG}/memory/feedback_autopilot_violations.md"
# Fail-open guard: if no transcript exists (first run / sandbox), skip reconciliation.
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || skip_step
```

For each phase in the pipeline (`sprint | audit | simplify | ship | post-pr-review | retrospective`):

| Expected Skill | Detection patterns in transcript (`"name":"Skill"` + `"skill":"<x>"`) |
|----------------|----|
| sprint | `code:sprint-impl` |
| audit | `code:audit-compliance` |
| simplify | `simplify` |
| ship | `code:shipping-pr` |
| post-pr-review | `code:pr-review-team` |

Decision table per phase:

| Transcript has skill invocation | `skip_log` has entry | Verdict |
|---|---|---|
| yes | — | OK (skill was invoked) |
| no | yes | Declared skip — note for curation |
| no | no | **SILENT_SKIP violation** — append entry to `$VIOLATIONS` |

When a SILENT_SKIP is detected:
1. Append an entry to `$VIOLATIONS` using the template format (date, phase, outcome, detection, rationalization unknown unless recoverable from transcript, remediation hint).
2. Call `acm_record_signal` if the ACM MCP is available, tagging `autopilot_phase_bypass`, `phase:<name>`, strength high. Skip silently if the tool isn't registered.
3. Do NOT fix the violation in this run (ship has already happened). The goal is to record for the next run's Step 0.5 commitment device.

Transcript grep caveats (documented so false positives are understood):
- The transcript jsonl format is not a stable Claude Code API. Future schema drift may require adjusting the patterns.
- "Skill invocation present" is a lower bound — partial or wrong-arity invocations may still pass this check. Reviewer analysis in Step 2 is the complementary signal for quality.

### Step 3: Integrate Reports

Integrate both agent reports:

1. **Audit result fixes**: If PARTIAL/FAIL found, apply fixes as Fixer
2. **workflow-recording.md update**: Add phase metrics
3. **Learnings optimization**: Read and optimize `docs/dev-cycle-learnings.md` (see Learnings PDCA below)
4. **MEMORY.md update**: Record process lessons
5. **Violations memory curation**: If `$VIOLATIONS` now exceeds ~30 entries or contains near-duplicates, consolidate older entries by pattern. Newest entries remain verbatim.

### Step 4: Fix (if needed)

Based on Auditor/Researcher findings:
- Code issues: fix + test + commit
- Skill-level issues: Output a GitHub Issue suggestion (see Learnings PDCA below) — do NOT modify cached SKILL.md files
- Process issues: Record lessons in MEMORY.md / CLAUDE.md

After fixes: `code:review-commit` via Skill tool + `set-review-flag.sh` + commit.

### Step 5: Commit Retrospective Artifacts

```
docs(retro): Phase N retrospective findings and improvements
```

### Step 6: Push Updated Branch

```bash
git push origin <branch>
```

## Output Report

```markdown
## Retrospective Complete

### Audit Summary
| Principle | Status | Notes |
|-----------|--------|-------|
| DDD/TDD/DRY/ISSUE/PROCESS | pass/partial/fail | ... |

Score: X/5

### Code Quality
- Strengths / Weaknesses / Recommendations

### Metrics
- New files, tests, coverage, review iterations

### Improvements Applied
- Learnings updated (N new, N merged, N resolved), memory updated, code fixes
```

## Output Rules

For shared output language rules, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/output-rules.md`.

## Important Notes

- This skill runs **autonomously** — no user confirmation between steps
- Agents must be **brutally honest** — no flattery, no sugar-coating
- Both technical issues AND process compliance must be verified
- Metrics recorded in `docs/research/workflow-recording.md`
- Process lessons go in project MEMORY.md
- Auditor + Researcher agents run via Task tool in parallel (TeamCreate is unnecessary — agents are independent)
- All user-facing output MUST follow the user's configured language setting — SKILL.md being in English does not change this

## Learnings PDCA

For detailed Learnings PDCA procedures (Project-Side optimization + Plugin-Side GitHub Issue suggestion), read `${CLAUDE_PLUGIN_ROOT}/skills/retrospective/references/learnings-pdca.md`.
