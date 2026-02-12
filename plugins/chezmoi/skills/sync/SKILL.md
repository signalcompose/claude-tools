---
name: sync
description: |
  Sync dotfiles from remote repository and apply changes.
  Use when: "sync dotfiles", "pull dotfiles", "update dotfiles",
  "dotfiles同期", "リモートから取得".
user-invocable: false
---

# Chezmoi Sync

Sync dotfiles from remote repository and apply changes.

## Execution

### Step 1: Fetch and Apply

chezmoi update で git pull + apply を自動実行:

Run: !`chezmoi update -v`

### Step 2: Report Results

適用されたファイルをユーザーに報告。

## Reference Files (read as needed)

If you need guidance:

- **Diff interpretation**: Read `${CLAUDE_PLUGIN_ROOT}/skills/sync/references/diff-interpretation-guide.md`
- **Error handling**: Read `${CLAUDE_PLUGIN_ROOT}/skills/sync/references/error-handling.md`
