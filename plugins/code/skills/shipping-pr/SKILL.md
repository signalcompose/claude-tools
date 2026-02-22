---
name: shipping-pr
description: |
  This skill runs an autonomous commit, code review, fix loop, push, and PR creation workflow.
  It loops until all critical/important review issues reach zero, then creates a PR.
  This skill should be used when the user says "ship it", "create PR", "commit and review", "出荷して", "PRお願い".
user-invocable: true
argument-hint: [commit-message-hint]
---

# Shipping PR

Autonomously commit, review, fix, and create a PR. Loops until review passes.

## Input

`$ARGUMENTS` (optional): Hint for the commit message scope or description.
If empty, analyzes staged/unstaged changes to determine the commit message.

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

Use Task tool with `pr-review-toolkit:code-reviewer` agent.
Report only issues with confidence >= 80.

### Step 4: Fix Loop (max 3 iterations)

```
max_iterations = 3  # default
if .claude/dev-cycle.state.json exists:
    max_iterations = 2  # retrospective 用のコンテキストを確保

while review has critical or important issues AND iteration < max_iterations:
    1. Fix each issue (use Serena find_referencing_symbols if available)
    2. Re-run tests + lint
    3. Re-stage fixed files
    4. Re-review with code-reviewer agent
    5. iteration++
```

If iteration >= max_iterations AND still has issues: report and STOP.

### Step 5: Approve Review

After review passes (0 critical, 0 important), create the approval flag:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
FLAG_FILE="/tmp/claude/review-approved-${REPO_HASH}"
mkdir -p /tmp/claude
touch "$FLAG_FILE"
echo "Review approved. Flag created: $FLAG_FILE"
```

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

Output: commit hash, PR URL, review stats (iterations, issues found/fixed), verification results, documentation status.

### Step 10: Serena Memory Save (recommended)

For post-sprint memory save, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/serena-integration.md`.

## Error Handling

- **Pre-commit hook blocks**: Re-create flag file (Step 5 bash commands), retry commit once
- **Push fails**: Check remote URL, try again
- **PR creation fails**: Fall back to providing manual PR URL
- **Fix loop exhausted (max_iterations reached)**: Report remaining issues, let user decide

## Important Notes

- This skill runs **autonomously** — no user confirmation needed between steps
- Always use `mcp__github__create_pull_request` for PR creation (not `gh` CLI)
- Never force push or amend commits
- Never commit `.env` files or secrets
- **Create approval flag using the bash commands in Step 5** — do NOT hardcode the hash
- **NEVER skip Step 3 (Code Review)** — it must use `pr-review-toolkit:code-reviewer` Agent
- **This skill is the ONLY authorized path for shipping code** — ad-hoc commits are prohibited
- Update `docs/research/workflow-recording.md` with Ship metrics after completion
