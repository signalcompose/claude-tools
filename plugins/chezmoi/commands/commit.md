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

### Step 2: Show Diff and Confirm with User

**Important: Understanding chezmoi status output**

The `chezmoi status` output uses two columns (each single character):
- **1st column**: Changes since last `chezmoi apply` (your local modifications)
- **2nd column**: What `chezmoi apply` would change

Common patterns:
- ` M` = No local changes, but chezmoi has updates to apply
- `M ` = You modified the file locally (this is what we want to commit)
- `MM` = Local modifications AND chezmoi has different changes (potential conflict)

Characters: (space)=unchanged, A=added, D=deleted, M=modified, R=run (scripts)

**Understanding diff direction**

To show what will be committed, use:

```bash
# Show diff for each changed file
# Note: chezmoi diff shows "repo → local" direction
# For commit, we need to show "local → repo" (what user changed locally)
chezmoi diff --reverse
```

**Diff interpretation for commit**:
- `+` lines = Content YOU ADDED locally (will be added to repo)
- `-` lines = Content YOU REMOVED locally (will be removed from repo)

Show the user:

```
🔍 Your local changes to commit:

📄 .zshrc:
  + alias ll='ls -la'    # You added this line
  - alias l='ls'         # You removed this line

📄 .gitconfig:
  + [user]
  +   name = Your Name   # You added this section

Do you want to commit these changes? [Y/n]:
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
