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

Spawn 2 agents using the Task tool (`subagent_type: "general-purpose"`) in parallel.
Auditor and Researcher are independent — no inter-agent communication needed.

#### Agent 1: Auditor

5-principle compliance verification. For detailed prompt, read `${CLAUDE_PLUGIN_ROOT}/skills/retrospective/references/auditor-prompt.md`.

Output: PASS/PARTIAL/FAIL per principle with evidence.

#### Agent 2: Researcher

Code quality and architecture analysis. For detailed prompt, read `${CLAUDE_PLUGIN_ROOT}/skills/retrospective/references/researcher-prompt.md`.

Output: Strengths, Weaknesses, Recommendations, Metrics.

### Step 3: Integrate Reports

Integrate both agent reports:

1. **Audit result fixes**: If PARTIAL/FAIL found, apply fixes as Fixer
2. **workflow-recording.md update**: Add phase metrics
3. **Learnings optimization**: Read and optimize `docs/dev-cycle-learnings.md` (see Learnings PDCA below)
4. **MEMORY.md update**: Record process lessons

### Step 4: Fix (if needed)

Based on Auditor/Researcher findings:
- Code issues: fix + test + commit
- Skill-level issues: Output a GitHub Issue suggestion (see Learnings PDCA below) — do NOT modify cached SKILL.md files
- Process issues: Record lessons in MEMORY.md / CLAUDE.md

After fixes: `code:review-commit` via Skill tool + `approve-review.sh` + commit.

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
