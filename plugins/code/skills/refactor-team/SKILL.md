---
name: refactor-team
description: |
  Team-based code refactoring with analysis and user-approved changes.
  Use when: "refactor this code", "リファクタリング", "コード整理",
  "refactor team", "リファクタチーム".
user-invocable: false
---

# Refactor Team

## Step 1: Identify Target Files & Detect Context

Resolve target files:
- If user specified path: use that
- Otherwise: `git diff --name-only <base-branch>` for changed files

Detect context:
- Base branch: `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'` (fallback: `main`)
- Test command: detect from `package.json`, `Makefile`, `pytest.ini`, etc.
- Project rules: read project's CLAUDE.md if present

## Step 2: Create Refactor Team

**MANDATORY**: Use TeamCreate to create the team, then spawn agents with Task tool.

Team structure:
```
Team Lead (yourself)
├─ Analyzer: pr-review-toolkit:code-simplifier
└─ Refactorer: general-purpose (refactorer)
```

## Step 3: Run Analysis

Analyzer examines target files using criteria from `${CLAUDE_PLUGIN_ROOT}/skills/refactor-team/references/analysis-criteria.md`.

Analysis output format:

| # | Category | File:Line | Description | Priority | Risk |
|---|----------|-----------|-------------|----------|------|
| 1 | DRY      | src/a.ts:42 | ...       | High     | Low  |
| 2 | Naming   | src/c.ts:8  | ...       | Medium   | None |

## Step 4: Present Proposals to User

**MANDATORY**: Present the analysis table to user and **wait for approval**.
Do NOT proceed without explicit user selection of which items to execute.

User selects items by number (e.g., "1, 3, 5" or "all").

## Step 5: Execute Approved Refactoring

For each approved item:
1. Refactorer applies the change
2. Run test command (detected in Step 1)
3. If tests pass: commit with `refactor: <description>`
4. If tests fail: revert and report

Rules:
- 1 refactoring = 1 commit
- No functional changes (behavior must be preserved)
- Commit prefix: `refactor:`

## Step 6: Report & Shutdown

Report summary:
- Items proposed / approved / completed / failed
- Commits created

Send `shutdown_request` to all agents via SendMessage, then TeamDelete.
