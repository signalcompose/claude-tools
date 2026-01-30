---
description: "Commit and push changed dotfiles"
---

# Chezmoi Commit

Detect changed dotfiles, commit and push to remote.

## Prerequisites

**Before interpreting any `chezmoi diff` output, read `references/diff-interpretation.md`.**

Key point: In `chezmoi diff`, `-` means "LOCAL has this" (not "deleted").

## Execution Steps

### Step 1: Detect Changes

```bash
chezmoi status
```

**If no changes**: Report "No changes to commit" and exit.

### Step 2: Interpret Diff Output

Run `chezmoi diff` and interpret according to `references/diff-interpretation.md`.

**Quick Reference**:
| Symbol | Meaning | Commit will... |
|--------|---------|----------------|
| `-` only | Local has, source lacks | **ADD** to source |
| `+` only | Source has, local lacks | **REMOVE** from source |
| `-`/`+` pair | Content differs | **UPDATE** source |

**Report to user using correct expressions**:
- ✅ "ローカルの `X` をソースに追加します"
- ❌ ~~"`X` が削除されました"~~ (WRONG - `-` ≠ deleted)

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

## Flow Diagram

```
status → diff → confirm → chezmoi add → git add → commit → push
```

## Error Handling

### Push Error (non-fast-forward)

```
❌ Failed to push: rejected (non-fast-forward)

Run /chezmoi:sync first to pull remote changes.
```

### Chezmoi Add Error

```
❌ Failed to add file

Check if file contains binary data or is in .chezmoiignore.
```

## Reference

For detailed diff interpretation guide, see `references/diff-interpretation.md`.
