---
name: sprint-impl
description: |
  This skill runs an implementation sprint: plan, issue creation, parallel team agent implementation, verification.
  It takes a plan (issue URL, file path, or inline description) and executes it end-to-end.
  This skill should be used when the user says "sprint", "implement the plan", "run the implementation", "実装して", "走って".
user-invocable: true
argument-hint: <plan-source>
---

# Sprint Implementation

Run through an implementation plan as far as possible without stopping.

## Input

`$ARGUMENTS` can be:
- A GitHub Issue URL (e.g. `https://github.com/owner/repo/issues/123`)
- A plan file path (e.g. `docs/plans/phase-2-plan.md`)
- Inline description of what to implement
- Empty — will look for the next unfinished phase in `docs/plans/`

## Execution Flow

### Phase 0: Serena Context (recommended, ~15 sec)

For full Serena setup steps, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/serena-integration.md`.

### Phase 1: Context Gathering (~1 min)

Collect project context in parallel:

1. Read `CLAUDE.md` (project rules, conventions, tech stack)
2. Read `docs/INDEX.md` + load relevant plan documents
3. Read `package.json`, `tsconfig.json` (project settings)
4. Check existing file structure with Glob
5. Run `git branch --show-current` to confirm branch

If `$ARGUMENTS` is a GitHub Issue URL, fetch the issue body via GitHub MCP.
If it's a file path, read the file.

### Phase 2: Dependency Check (~10 sec)

```bash
npm install --cache /tmp/claude/npm-cache
```

Only run if `node_modules/` is missing or `package.json` has changed.

### Phase 3: Issue Tracking Setup (~30 sec)

If GitHub Issues don't already exist for this work:

1. Create a parent tracking Issue via `mcp__github__issue_write`
2. Create sub-issues for each implementation step
3. Update parent Issue body with sub-issue links

Skip if issues are already referenced in the plan.

### Phase 4: Analyze Task Dependencies

Parse the plan into discrete tasks. For each task, determine:
- **Inputs/Outputs**: File dependencies
- **Dependencies**: Which other tasks must complete first

Categorize into **Sequential** (must run in order) vs **Parallel** (can run simultaneously).

### Phase 4.5: DDD — Spec Document (mandatory, enforced)

Before any implementation, create or update spec documentation.

**Enforcement gate** — verify BEFORE proceeding to Phase 5:
```bash
ls docs/specs/phase-N-<scope>.md
```
If the spec does not exist, **STOP and create it**. Do NOT proceed.

1. Create `docs/specs/phase-N-<scope>.md` with overview, types, modules, dependencies
2. Update `docs/INDEX.md` to reference the new spec
3. **Commit immediately**: `docs(<scope>): add <phase> specification`

### Phase 5: Sequential Foundation (~3 min)

Execute sequential/foundational tasks directly (no Team Agent overhead):
- Directory structure, shared type definitions, core interfaces

Run `npx tsc --noEmit` after each foundational step.
**Commit foundational work immediately** before spawning parallel agents.

### Phase 6: Parallel Implementation (Team Agent)

For parallel tasks:

1. **TeamCreate** with descriptive team name
2. **Spawn agents** in parallel via Task tool (`subagent_type: "general-purpose"`, `mode: "acceptEdits"`)
3. **Wait for all agents** to report completion
4. **Shutdown agents** promptly + **TeamDelete**

For agent prompt template constraints, read `${CLAUDE_PLUGIN_ROOT}/skills/sprint-impl/references/agent-prompt-template.md`.

### Phase 6.1: Incremental Commits (per-agent)

After each agent completes and passes verification:

1. Stage only that agent's files
2. Run `npx vitest run <agent-test-files>` to verify
3. Commit with granular scope: `feat(<module>): add <module-name> with TDD tests`

Do NOT batch all agents into a single commit. The lead (not agents) performs all commits.

### Phase 6.5: Serena Symbol Verification (recommended)

For Serena symbol verification steps, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/serena-integration.md`.
Use `get_symbols_overview` and `find_referencing_symbols` on newly created files.

### Phase 7: Integration Verification (~10 sec)

Run all checks in parallel:

```bash
npx tsc --noEmit        # Type check
npx tsc                  # Build
npx vitest run           # All tests
npx eslint src/ tests/   # Lint
```

If any check fails: analyze, fix, re-run. If architectural change needed, stop and report.

### Phase 7.5: Compliance Gate (enforced)

Before coverage check, verify principle compliance:

1. **DDD**: Does `docs/specs/<phase-name>.md` exist and was it committed?
2. **TDD**: Were there separate test-first commits?
3. **DRY**: Were there any lint warnings about duplicate code?
4. **ISSUE**: Do GitHub Issues exist for this work?

**If any check fails** — recovery procedure:
- **DDD fail**: Go back to Phase 4.5, create the spec, commit it
- **TDD fail**: Add missing tests, commit separately
- **DRY fail**: Refactor, re-run Phase 7 verification
- **ISSUE fail**: Create issues now, amend commit messages with `Refs: #N`

Do NOT defer to post-sprint. Fix violations NOW.

### Phase 8: Coverage Check

```bash
npx vitest run --coverage
```

Verify coverage meets threshold (check `vitest.config.ts`, default 80%).

### Phase 9: Summary Report

Output: files created/modified, test results, verification status, next steps.

### Phase 10: Serena Memory Save (recommended)

For post-sprint memory save, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/serena-integration.md`.

### Phase 11: Auto-Ship (conditional)

**Note**: If `.claude/dev-cycle.state.json` exists, skip Phase 11 — the orchestrator handles stage transitions.

**Conditions (ALL must be true):**
1. All verification checks in Phase 7 passed
2. The **original** input plan or user instructions mention shipping, commit, or PR
3. There are uncommitted changes

**If conditions met:** Invoke `code:shipping-pr` via Skill tool automatically.
**If conditions NOT met:** Output "Next Steps" suggestion and stop.

## Error Handling

- **npm install fails**: Try `--cache /tmp/claude/npm-cache` workaround
- **Agent fails**: Report which agent failed and why, continue with others
- **Type errors after parallel work**: Fix conflicts (barrel exports, shared types)
- **Test failures**: Attempt fix (max 2 retries per test file), then report
- **Max fix attempts**: 3 rounds of fix-and-verify before escalating to user

## Important Notes

- This skill runs **autonomously** — minimize user confirmations
- Use GitHub MCP Server for issue operations (not `gh` CLI)
- Always update `docs/research/workflow-recording.md` with timing metrics after completion
