---
name: shipping-pr
description: |
  This skill runs an autonomous commit, code review, fix loop, push, and PR creation workflow.
  It loops until all critical/important review issues reach zero, then creates a PR.
  This skill should be used when the user says "ship it", "create PR", "commit and review", "出荷して", "PRお願い".
user-invocable: true
argument-hint: [--skip-review] [commit-message-hint]
---

# Shipping PR

Autonomously commit, review, fix, and create a PR. Loops until review passes.

## Input

`$ARGUMENTS` (optional): Can include flags and/or commit message hint.

### Flags

- `--skip-review`: Skip Step 3 (Code Review) and Step 4 (Fix Loop). Use only when review has already been performed upstream (e.g., called from `/code:autopilot` after `simplify` has converged).
  - Still runs Step 5 (set approval flag) because the PR creation gate requires it.
  - Default: `false` (review is run).

### Commit message hint

Any non-flag argument is treated as a hint for the commit message scope or description.
If empty, analyzes staged/unstaged changes to determine the commit message.

### Argument parsing

Parse `$ARGUMENTS` by splitting on whitespace. Extract `--skip-review` (case-sensitive) if present; treat the remainder as the commit message hint.

## Phase 0: Serena Context (recommended, ~10 sec)

For full Serena setup steps, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/serena-integration.md`.

## Pre-flight Checks

1. Verify current branch is NOT `main` (abort if so)
2. Run verification commands:

```bash
npx tsc --noEmit    # Type check
npx vitest run      # Tests
npx eslint src/ tests/  # Lint
```

If any fail: attempt automatic fix (max 2 attempts), then abort.

## Execution Flow

### Step 1: Analyze Changes (~10 sec)

Run in parallel:

```bash
git status                    # Untracked + modified files
git diff                      # Unstaged changes
git diff --cached             # Staged changes
git log --oneline -5          # Recent commit style
```

**Case A: Unstaged/staged changes exist** (normal flow)

Determine files to stage, commit type, English summary, Japanese description.
Proceed to Step 2.

**Case B: No unstaged/staged changes** (already committed)

Detect committed-but-not-pushed changes:

```bash
git merge-base HEAD main
git diff $(git merge-base HEAD main)...HEAD
git log --oneline main..HEAD
```

If committed changes exist: skip Step 2, proceed to Step 3 using committed diff.
If NO changes at all: report "No changes to ship" and STOP.

### Step 2: Stage Files

```bash
git add <specific-files>
```

Never use `git add -A` or `git add .`.
Exclude: `.env*`, `credentials*`, `secrets*`, `*.key`, `*.pem`

### Step 3: Code Review (automated)

**Skipped when `--skip-review` is set.** In that case, jump to Step 5.

Launch 2 reviewers **in parallel** via Task tool:
- `pr-review-toolkit:code-reviewer` — code quality, bugs, security
- `pr-review-toolkit:silent-failure-hunter` — silent failures, error handling

Report only issues with confidence >= 80.

If silent-failure-hunter fails to launch: continue with code-reviewer only (WARNING, not blocking).
Include in Step 9 Summary Report: "silent-failure-hunter failed to launch — error handling review was NOT performed."

### Step 4: Fix Loop (max 3 iterations)

**Skipped when `--skip-review` is set.**

```
max_iterations = 3

while review has critical or important issues AND iteration < max_iterations:
    1. Fix each issue (use Serena find_referencing_symbols if available)
    2. Re-run tests + lint
    3. Re-stage fixed files
    4. Re-review with code-reviewer agent
    5. iteration++
```

If iteration >= max_iterations AND still has issues: report and STOP.

### Step 5: Approve Review

Set the review approval flag. Required for Step 8 (PR creation gate).

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/set-review-flag.sh
```

- Normal flow: runs after review passes (0 critical, 0 important).
- `--skip-review` flow: runs unconditionally; the caller (e.g., `/code:autopilot`) is responsible for ensuring an equivalent review was already performed.

### Step 6: Commit

For Conventional Commits format and Co-Authored-By pattern, read `${CLAUDE_PLUGIN_ROOT}/skills/shipping-pr/templates/commit-format.md`.

### Step 7: Push

```bash
git push -u origin <current-branch>
```

The `.git/config` write error can be ignored — push succeeds.

### Step 8: Create PR

Use `mcp__github__create_pull_request`. For PR body format, read `${CLAUDE_PLUGIN_ROOT}/skills/shipping-pr/templates/pr-body.md`.

### Step 8.5: Documentation Sync Check

After PR creation:

1. Check if `docs/specs/` contains relevant spec files
2. If specs exist and implementation diverged: update spec, create `docs:` follow-up commit
3. If no specs exist: add warning in summary report

### Step 9: Summary Report

Output: commit hash, PR URL, review stats (iterations, issues found/fixed), verification results, documentation status, agent launch warnings (if any).

### Step 10: Serena Memory Save (recommended)

For post-sprint memory save, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/serena-integration.md`.

## Error Handling

- **Pre-commit hook blocks**: Re-run `bash ${CLAUDE_PLUGIN_ROOT}/scripts/set-review-flag.sh`, then retry commit once
- **Push fails**: Check remote URL, try again
- **PR creation fails**: Fall back to providing manual PR URL
- **Fix loop exhausted (max_iterations reached)**: Report remaining issues, let user decide

## Important Notes

- This skill runs **autonomously** — no user confirmation needed between steps
- Always use `mcp__github__create_pull_request` for PR creation (not `gh` CLI)
- Never force push or amend commits
- Never commit `.env` files or secrets
- **Create approval flag using `set-review-flag.sh` in Step 5** — do NOT hardcode the hash
- **NEVER skip Step 3 (Code Review)** unless `--skip-review` is explicitly set by an upstream orchestrator that has already run an equivalent review (e.g., `/code:autopilot` after `simplify`).
- **`--skip-review` is for autopilot integration only** — do not set it manually unless you can justify that review has been completed elsewhere.
- **This skill is the ONLY authorized path for shipping code** — ad-hoc commits are prohibited
- Update `docs/research/workflow-recording.md` with Ship metrics after completion
