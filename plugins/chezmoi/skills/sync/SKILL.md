---
name: sync
description: |
  Sync dotfiles from remote repository and apply changes.
  Use when: "sync dotfiles", "pull dotfiles", "update dotfiles",
  "dotfiles同期", "リモートから取得".
user-invocable: true
---

# Chezmoi Sync

Sync dotfiles from remote repository and apply changes.

## Execution

### Step 1: Fetch and Apply

chezmoi update で git pull + apply を自動実行:

Run: !`chezmoi update -v`

### Step 2: Report Results

適用されたファイルをユーザーに報告。

## References

- Diff の読み方: [references/diff-interpretation-guide.md](references/diff-interpretation-guide.md)
- エラー対処: [references/error-handling.md](references/error-handling.md)
