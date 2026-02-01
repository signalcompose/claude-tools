---
description: "Commit and push changed dotfiles"
---

# Chezmoi Commit

Detect changed dotfiles, commit and push to remote.

## 🚨 CRITICAL: Diff Interpretation Rules (MUST READ FIRST)

**chezmoi diff symbols have OPPOSITE meaning from git diff.**

### Symbol Definition (Memorize This)

| Symbol | Meaning | Mental Model |
|--------|---------|--------------|
| `-` | **LOCAL (home directory)** has this | "LOCAL HAS THIS" |
| `+` | **SOURCE (chezmoi repo)** has this | "SOURCE HAS THIS" |

### What Commit Will Do

| Diff Pattern | Meaning | Commit Result |
|--------------|---------|---------------|
| `-` only | Local has, source lacks | **ADD** to source |
| `+` only | Source has, local lacks | **REMOVE** from source |
| `-`/`+` pair | Content differs | **UPDATE** source with local |

### 🚫 FORBIDDEN Expressions (NEVER USE)

- ❌ Describing `-` lines as "deleted" or "removed"
- ❌ Saying "commit will delete" for `-` only lines
- ❌ Following git diff conventions

### ✅ CORRECT Expressions (USE THESE)

- ✅ "Local has `X`, source lacks it → Will be **added** to source"
- ✅ "Source has `X`, local lacks it → Will be **removed** from source"
- ✅ "Content differs → Source will be **updated** with local version"

### Pre-Interpretation Checklist

Before reporting diff results, verify:
1. Am I treating `-` as "LOCAL HAS THIS"?
2. Am I treating `+` as "SOURCE HAS THIS"?
3. Am I NOT using git diff mental model?

---

## Execution Steps

### Step 1: Detect Changes

```bash
chezmoi status
```

**If no changes**: Report "No changes to commit" and exit.

### Step 2: Interpret Diff Output

```bash
chezmoi diff
```

Apply the rules above. Report changes using CORRECT expressions only.

**Example interpretation:**
```diff
-    "hookify@claude-plugins-official": true,
```
→ Local has this, source lacks it → Commit will **ADD** to source

```diff
+    "sigcomintra@sigcomintra": true,
```
→ Source has this, local lacks it → Commit will **REMOVE** from source

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

For detailed examples and troubleshooting, see `references/diff-interpretation.md`.
