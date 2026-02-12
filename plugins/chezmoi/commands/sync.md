---
description: "Sync dotfiles from remote repository and apply changes"
---

# Chezmoi Sync

## Overview

Sync dotfiles from remote repository and apply changes.

**Capabilities**:
- Fetches latest dotfiles from remote repository
- Applies changes to local system
- Handles merge conflicts and errors

**Use when**: "sync dotfiles", "pull dotfiles", "update dotfiles", "fetch dotfiles", "apply changes", "dotfiles同期", "リモートから取得", "変更を適用"

**Don't use for**: Committing local changes, initial setup, checking status

## Execution

### Step 1: Fetch and Apply

chezmoi update で git pull + apply を自動実行:

Run: !`chezmoi update -v`

### Step 2: Report Results

適用されたファイルをユーザーに報告。

## Reference: Diff Interpretation

**Important**: `chezmoi diff` shows "what would happen if you run `chezmoi apply`".

- `-` lines = Current **local** file content (destination)
- `+` lines = **Chezmoi source** content (what would be applied)

### Example

```diff
-    "plugin-x": true,
-    "plugin-y": true
+    "plugin-x": true
```

**Interpretation**: Local has `plugin-y`, but chezmoi source does not.

| Situation | Action |
|-----------|--------|
| Local has changes you want to keep | Run `/chezmoi:commit` to push to source |
| Source has updates you want | Run `chezmoi apply` to apply to local |

## Reference: Error Handling

### Network Error

```
Cannot reach github.com
```

Please check your internet connection and try again.

### Git Conflict

```
Git conflict detected!
```

You have local changes that conflict with remote changes.
Resolve conflicts manually:

1. `cd ~/.local/share/chezmoi`
2. `git status`
3. Resolve conflicts
4. `git add .`
5. `git commit`
6. `chezmoi apply`

### Notes

- `chezmoi update` automatically runs git pull and chezmoi apply
- If there are uncommitted local changes, an error may occur
- In that case, run `/chezmoi:commit` first
