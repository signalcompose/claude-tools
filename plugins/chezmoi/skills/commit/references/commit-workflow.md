# Commit Workflow Details

## Step 1: Detect Changes

```bash
chezmoi status
```

**If no changes**: Report "No changes to commit" and exit.

## Step 2: Show Diff

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

## Step 3: Confirm with User

```
🔍 Detected changes:
  - .zshrc (local content will be added to source)
  - .gitconfig (source will be updated with local version)

Commit these changes? [Y/n]:
```

## Step 4: Add Files to Chezmoi

```bash
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig
```

## Step 5: Commit and Push

```bash
cd ~/.local/share/chezmoi
git add .
git commit -m "chore: update dotfiles

[Description of changes]

Co-Authored-By: Claude <noreply@anthropic.com>"
git push
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
