---
description: "Commit and push changed dotfiles to remote repository"
---

# Chezmoi Commit

## Overview

Detect changed dotfiles, commit and push to remote.

**Capabilities**:
- Detects changed dotfiles
- Creates commit with user confirmation
- Pushes to remote repository

**Use when**: "commit dotfiles", "push dotfiles", "save dotfile changes", "backup dotfiles", "dotfilesコミット", "dotfiles反映", "dotfiles保存"

**Don't use for**: Project code commits, general git operations, non-dotfile changes

**Flow**:
```
status → diff → confirm → chezmoi add → git add → commit → push
```

## Execution

### Step 1: Detect & Show Changes

Run `chezmoi status` and `chezmoi diff --reverse`. If no changes, report and exit.

### Step 2: Confirm with User

Present detected changes and ask for confirmation before proceeding.

### Step 3: Add, Commit & Push

Add files with `chezmoi add`, then commit and push from `~/.local/share/chezmoi`.

## Reference: Diff Interpretation

### Recommended: Use `--reverse` Flag

For `/chezmoi:commit`, always use:

```bash
chezmoi diff --reverse
```

This produces **git-like output** that shows what commit will do:
- `-` lines will be **removed** from source
- `+` lines will be **added** to source

**No special interpretation rules needed.** Read it like a normal `git diff`.

### Why `--reverse`?

#### Normal `chezmoi diff` (without flag)

Shows what `chezmoi apply` would do (making local match source):
- `-` = current content in LOCAL (destination)
- `+` = desired content from SOURCE (target state)

This is counterintuitive when committing (local → source).

#### `chezmoi diff --reverse`

Shows what commit will do (local → source):
- `-` = will be **removed** from source
- `+` = will be **added** to source

This matches git diff semantics exactly.

### Example Comparison

Local has `hookify`, source has `sigcomintra`:

**Without `--reverse`**:
```diff
-    "hookify@...": true,      ← Local has this
+    "sigcomintra@...": true,  ← Source has this
```
Confusing: `-` means "will be added to source" (counterintuitive)

**With `--reverse`**:
```diff
-    "sigcomintra@...": true,  ← Will be removed from source
+    "hookify@...": true,      ← Will be added to source
```
Clear: Standard git diff semantics

### Reference: Normal Diff (Legacy)

**Warning:** This section is for reference only. Always use `--reverse` for the commit workflow.

If you must use `chezmoi diff` without `--reverse`:

| Symbol | Meaning | For commit |
|--------|---------|------------|
| `-` | Content in LOCAL | Will be **ADDED** to source |
| `+` | Content in SOURCE | Will be **REMOVED** from source |

**Note:** This is the opposite of git diff conventions.

## Reference: Commit Workflow Details

### Step 1: Detect Changes

```bash
chezmoi status
```

**If no changes**: Report "No changes to commit" and exit.

### Step 2: Show Diff

```bash
chezmoi diff --reverse
```

Report changes using standard git diff language:
- `-` lines: "Will **remove** X from source"
- `+` lines: "Will **add** X to source"

**Example:**
```diff
-    "sigcomintra@sigcomintra": true,
+    "hookify@claude-plugins-official": true,
```
→ `sigcomintra` will be removed, `hookify` will be added to source

### Step 3: Confirm with User

```
🔍 Detected changes:
  - .zshrc (local content will be added to source)
  - .gitconfig (source will be updated with local version)

Commit these changes? [Y/n]:
```

### Step 4: Add Files to Chezmoi

```bash
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig
```

### Step 5: Commit and Push

```bash
cd ~/.local/share/chezmoi
git add .
git commit -m "chore: update dotfiles

[Description of changes]

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

### Error Handling

#### Push Error (non-fast-forward)

```
❌ Failed to push: rejected (non-fast-forward)

Run /chezmoi:sync first to pull remote changes.
```

#### Chezmoi Add Error

```
❌ Failed to add file

Check if file contains binary data or is in .chezmoiignore.
```
