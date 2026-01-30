---
description: "Sync dotfiles from remote repository and apply changes"
---

# Chezmoi Sync

Sync dotfiles from remote repository and apply changes.

## Execution Steps

### Step 1: Fetch and Apply

Run `chezmoi update` to automatically:
1. Git pull in `~/.local/share/chezmoi`
2. Apply changed files

```bash
chezmoi update -v
```

### Step 2: Report Results

Report the applied files to the user:

```
✅ Dotfiles synced successfully!

Updated files:
  - .zshrc
  - .gitconfig
  - ...
```

## Understanding chezmoi diff Output

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

## Error Handling

### Network Error

```
❌ Network error: Cannot reach github.com

Please check your internet connection and try again.
```

### Git Conflict

```
❌ Git conflict detected!

You have local changes that conflict with remote changes.
Please resolve conflicts manually:

1. cd ~/.local/share/chezmoi
2. git status
3. Resolve conflicts
4. git add .
5. git commit
6. chezmoi apply
```

## Notes

- `chezmoi update` automatically runs git pull and chezmoi apply
- If there are uncommitted local changes, an error may occur
- In that case, run `/chezmoi:commit` first
