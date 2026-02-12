---
description: "Check dotfiles status and sync state with remote repository"
---

# Chezmoi Status Check

## Overview

Check dotfiles status including local changes, remote sync state, and shell sync checker status.

**Capabilities**:
- Detects local changes in managed dotfiles
- Checks remote repository sync state (ahead/behind)
- Verifies shell sync checker status
- Provides actionable next steps

**Use when**: "check dotfiles", "dotfiles status", "chezmoi status", "verify sync", "dotfiles確認", "同期状態チェック", "ステータス確認"

**Don't use for**: Project code status, general git status checks

## Execution

Run the status check script:

Check: !`bash ${CLAUDE_PLUGIN_ROOT}/scripts/chezmoi-check.sh`

After execution, report the results to the user.

## Reference: Script Behavior

The check script performs three steps:

### Step 1: Local Changes Detection
- Runs `chezmoi status` to detect modified files
- Reports files that differ between source state and target state

### Step 2: Git Sync Status
- Fetches latest from origin/main
- Shows branch status (ahead/behind)
- Provides actionable next steps:
  - If local changes + behind: sync first, then commit
  - If local changes only: commit and push
  - If behind only: sync to pull latest
  - If ahead only: push commits
  - If up-to-date: no action needed

### Step 3: Shell Sync Checker Migration
- Checks for old embedded sync checker code in .zshrc
- Warns if outdated version detected (has macOS timeout bug)
- Suggests running `/chezmoi:shell-sync-setup` to migrate

### Error Handling
- Exits with error if chezmoi is not installed
- Provides installation instructions (`brew install chezmoi`)
- Detects if chezmoi source directory is not a git repository
- Suggests running `/chezmoi:setup` for initial configuration
