---
description: "Sync dotfiles from remote repository and apply changes"
---

# Chezmoi Sync

Sync dotfiles from remote repository and apply changes.

## Execution

### Step 1: Fetch and Apply

chezmoi update で git pull + apply を自動実行:

Run: !`chezmoi update -v`

### Step 2: Report Results

適用されたファイルをユーザーに報告。

## Reference Materials

If detailed diff interpretation or error handling guidance is needed:

Diff guide: !`cat ${CLAUDE_PLUGIN_ROOT}/skills/sync/references/diff-interpretation-guide.md`
Error handling: !`cat ${CLAUDE_PLUGIN_ROOT}/skills/sync/references/error-handling.md`
