---
description: "Commit and push changed dotfiles to remote repository"
---

# Chezmoi Commit

Detect changed dotfiles, commit and push to remote.

## Diff Interpretation

Use `chezmoi diff --reverse` to get git-like diff output. Read it exactly like a normal `git diff`.

For detailed examples, read `${CLAUDE_PLUGIN_ROOT}/skills/commit/references/diff-interpretation.md` for diff interpretation guidance.

## Execution

### Step 1: Detect & Show Changes

Run `chezmoi status` and `chezmoi diff --reverse`. If no changes, report and exit.

### Step 2: Confirm with User

Present detected changes and ask for confirmation before proceeding.

### Step 3: Add, Commit & Push

Add files with `chezmoi add`, then commit and push from `~/.local/share/chezmoi`.

For detailed execution steps and error handling, read `${CLAUDE_PLUGIN_ROOT}/skills/commit/references/commit-workflow.md` for commit workflow instructions.

## Flow

```
status → diff → confirm → chezmoi add → git add → commit → push
```
