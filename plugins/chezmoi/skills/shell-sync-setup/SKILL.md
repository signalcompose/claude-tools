---
name: shell-sync-setup
description: |
  Install shell startup sync checker for chezmoi dotfiles.
  Use when: "set up shell sync", "install chezmoi checker",
  "シェル同期チェッカー設定", "起動時チェック設定".
user-invocable: false
---

# Chezmoi Shell Sync Checker Setup

Installs an interactive dotfiles sync checker that runs on shell startup.

## Features

- Checks for remote updates and local changes at shell startup
- Compatible with all zsh environments (plain zsh, oh-my-zsh, Powerlevel10k)
- Non-intrusive: Only shows status on empty Enter press
- Auto-updates via `/plugin update` (external script approach)

## Architecture

Uses a **minimal loader** approach:

```
zshrc (7 lines)          External script (~150 lines)
┌─────────────────┐      ┌────────────────────────────────────────────┐
│ Loader snippet  │ ───► │ ~/.claude/plugins/.../shell-check.zsh     │
│ (source if      │      │ (auto-updated via /plugin update)         │
│  file exists)   │      └────────────────────────────────────────────┘
└─────────────────┘
```

## Execution

### Step 1: Environment Detection & Migration Check

See [references/migration-check.md](references/migration-check.md) for environment detection, existing installation check, and user confirmation dialogues.

### Step 2: Installation

See [references/loader-code.md](references/loader-code.md) for the loader code and installation steps.

### Step 3: Verification

See [references/troubleshooting.md](references/troubleshooting.md) for verification and troubleshooting.
