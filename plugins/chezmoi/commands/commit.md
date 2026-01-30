---
description: "Commit and push changed dotfiles"
---

# Chezmoi Commit

Detect changed dotfiles, commit and push to remote.

## Execution Steps

### Step 1: Detect Changes

First, check which files have been modified:

```bash
chezmoi status
```

**If no changes**: Report "No changes to commit" and exit.

### Understanding chezmoi diff

`chezmoi diff` shows what `chezmoi apply` would change (target state vs current local files):

| Symbol | Represents | `apply` would... |
|--------|------------|------------------|
| `-` | Current **local** state | Remove this |
| `+` | Current **source** state | Add this |

**For `/chezmoi:commit`**: We do the **opposite** of apply—copy local → source.

- `-` lines = Local content to **preserve** (will be added to source)
- `+` lines = Source content to **update** (will be replaced by local)

**Example**: You added a plugin locally that source doesn't have:
```diff
-    "claude-md-management": true,  ← Local has this
+                                   ← Source doesn't
```
→ Commit will add `claude-md-management` to source.

### Step 2: Confirm with User

Show the user which files will be committed:

```
🔍 Detected changes:
  - .zshrc (new alias added)
  - .gitconfig (updated)

Do you want to commit these files? [Y/n]:
```

Proceed only if user approves.

### Step 3: Add Files to Chezmoi

Add modified files to chezmoi source directory:

```bash
# For each detected file:
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig
# etc.
```

### Step 4: Git Staging

Stage changes in chezmoi source directory:

```bash
cd ~/.local/share/chezmoi
git add .
```

### Step 5: Commit and Push

After staging, commit and push:

```bash
cd ~/.local/share/chezmoi
git commit -m "chore: update dotfiles

[Description of changes]

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
```

**Commit Message Format**:
- **type**: `chore` (dotfiles update)
- **summary**: English (e.g., "update dotfiles")
- **body**: Description of changes

## Flow Diagram

```
Detect changes → User confirm → chezmoi add → git add → commit → push
      ↓              ↓              ↓            ↓          ↓        ↓
   status        [Y/n]         each file      all       message   GitHub
```

## Error Handling

### Chezmoi Add Error

```
❌ Failed to add .zshrc to chezmoi

Error: file contains binary data

Please check the file and try again.
```

### Push Error

```
❌ Failed to push to remote

Error: rejected (non-fast-forward)

Please run /chezmoi:sync first to pull remote changes.
```

## Notes

- Always shows diff before committing
- Commit messages are auto-generated but can be customized
- Run local tests before pushing if applicable
