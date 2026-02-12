---
description: "Install shell startup sync checker for chezmoi dotfiles"
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
+-------------------+    +--------------------------------------------+
| Loader snippet    | -> | ~/.claude/plugins/.../shell-check.zsh      |
| (source if        |    | (auto-updated via /plugin update)           |
|  file exists)     |    +--------------------------------------------+
+-------------------+
```

## Execution

### Step 1: Environment Detection & Migration Check

Read `${CLAUDE_PLUGIN_ROOT}/skills/shell-sync-setup/references/migration-check.md` for environment detection and migration check instructions.

### Step 2: Installation

Read `${CLAUDE_PLUGIN_ROOT}/skills/shell-sync-setup/references/loader-code.md` for loader installation instructions.

### Step 3: Verification

Read `${CLAUDE_PLUGIN_ROOT}/skills/shell-sync-setup/references/troubleshooting.md` for verification and troubleshooting instructions.
