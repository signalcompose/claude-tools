---
name: check
description: |
  Check dotfiles status and sync state with remote repository.
  Use when: "check dotfiles", "dotfiles status", "chezmoi status",
  "dotfiles確認", "同期状態チェック".
user-invocable: true
---

# Chezmoi Status Check

Check dotfiles status including local changes, remote sync state, and shell sync checker status.

## Execution

Run the status check script:

Check: !`bash ${CLAUDE_PLUGIN_ROOT}/scripts/chezmoi-check.sh`

After execution, report the results to the user.
