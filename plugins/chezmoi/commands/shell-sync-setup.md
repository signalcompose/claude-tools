---
description: "Install shell startup sync checker for chezmoi dotfiles"
---

# Chezmoi Shell Sync Checker Setup

## Overview

Installs an interactive dotfiles sync checker that runs on shell startup.

**Capabilities**:
- Detects remote updates and local changes at shell startup
- Compatible with all zsh environments (plain zsh, oh-my-zsh, Powerlevel10k)
- Non-intrusive: Only shows status on empty Enter press
- Auto-updates via `/plugin update`

**Use when**: "set up shell sync", "install chezmoi checker", "enable startup check", "シェル同期チェッカー設定", "起動時チェック設定", "自動同期チェック"

**Don't use for**: Syncing dotfiles, committing changes, checking status

## Features & Architecture

### Features

- Checks for remote updates and local changes at shell startup
- Compatible with all zsh environments (plain zsh, oh-my-zsh, Powerlevel10k)
- Non-intrusive: Only shows status on empty Enter press
- Auto-updates via `/plugin update` (external script approach)

### Architecture

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

Follow the 3 steps sequentially. Read the Reference sections for detailed instructions.

### Step 1: Environment Detection & Migration Check

Detect environment and check for existing installation (see Reference below).

### Step 2: Installation

Install the loader code into zshrc (see Reference below).

### Step 3: Verification

Verify installation and troubleshoot if needed (see Reference below).

## Reference: Environment Detection & Migration Check

### Phase 1: Environment Detection

```bash
echo "🔍 Detecting environment..."
echo ""

SETUP_READY=true

# Check if zsh
if [[ -n "$ZSH_VERSION" ]]; then
  echo "✅ Shell: zsh $ZSH_VERSION"
else
  echo "❌ Shell: Not zsh (this setup requires zsh)"
  SETUP_READY=false
fi

# Check chezmoi
if command -v chezmoi &>/dev/null; then
  echo "✅ chezmoi: $(chezmoi --version 2>&1 | head -1)"
else
  echo "❌ chezmoi: Not installed"
  echo "   Install with: brew install chezmoi"
  SETUP_READY=false
fi

# Detect zshrc location
ZSHRC_SOURCE=""
if [[ -f ~/.local/share/chezmoi/dot_zshrc ]]; then
  ZSHRC_SOURCE="$HOME/.local/share/chezmoi/dot_zshrc"
  echo "✅ zshrc source: chezmoi managed (dot_zshrc)"
elif [[ -f ~/.zshrc ]]; then
  ZSHRC_SOURCE="$HOME/.zshrc"
  echo "⚠️ zshrc source: ~/.zshrc (not chezmoi managed)"
else
  echo "❌ No zshrc found"
  SETUP_READY=false
fi

# Check external script availability
SCRIPT_PATH="$HOME/.claude/plugins/marketplaces/claude-tools/plugins/chezmoi/scripts/shell-check.zsh"
if [[ -f "$SCRIPT_PATH" ]]; then
  echo "✅ External script: Found"
else
  echo "⚠️ External script: Not found at expected path"
  echo "   Make sure chezmoi plugin is installed from claude-tools marketplace"
fi

echo ""
echo "📋 Summary:"
echo "   Source file: $ZSHRC_SOURCE"
echo "   Ready:       $SETUP_READY"
```

If `SETUP_READY=false`, inform user of missing requirements and stop.

### Phase 2: Migration Check

```bash
echo ""
echo "🔍 Checking existing installation..."

INSTALL_TYPE="new"  # new, migrate, skip

if [[ -n "$ZSHRC_SOURCE" ]]; then
  # Check for new loader style
  if grep -q "shell-check.zsh" "$ZSHRC_SOURCE" 2>/dev/null; then
    echo "✅ Loader already installed (external script style)"
    INSTALL_TYPE="skip"
  # Check for old embedded style
  elif grep -q "_chezmoi_check_sync" "$ZSHRC_SOURCE" 2>/dev/null; then
    echo "⚠️ Found OLD embedded code (~150 lines in zshrc)"
    echo "   Recommend migrating to new loader style (7 lines)"
    INSTALL_TYPE="migrate"
  else
    echo "ℹ️  No existing installation found"
    INSTALL_TYPE="new"
  fi
fi

echo ""
echo "   Install type: $INSTALL_TYPE"
```

#### For New Installation

```
The following loader will be added to your zshrc (7 lines):

┌─────────────────────────────────────────────────────────────────┐
│ # >>> chezmoi shell sync checker start >>>                      │
│ # Loader for chezmoi shell sync checker                         │
│ # Source: https://github.com/signalcompose/claude-tools         │
│ if [[ -f ~/.claude/plugins/.../shell-check.zsh ]]; then         │
│   source ~/.claude/plugins/.../shell-check.zsh                  │
│ fi                                                              │
│ # <<< chezmoi shell sync checker end <<<                        │
└─────────────────────────────────────────────────────────────────┘

Features:
- Checks for remote updates on GitHub
- Detects local uncommitted changes
- Shows status only when pressing empty Enter
- Auto-updates via /plugin update

Proceed with installation?
1. Yes, install
2. No, cancel
```

#### For Migration

```
Found old embedded code in your zshrc (~150 lines).
Recommend migrating to new loader style (7 lines).

Benefits of migration:
- zshrc stays clean (7 lines vs ~150 lines)
- Auto-updates via /plugin update
- Same functionality

Migration will:
1. Remove old embedded code
2. Add new loader (7 lines)

Proceed with migration?
1. Yes, migrate to new style
2. No, keep old style
```

## Reference: Loader Code & Installation

### Loader Code to Insert

```zsh
# >>> chezmoi shell sync checker start >>>
# Loader for chezmoi shell sync checker
# Source: https://github.com/signalcompose/claude-tools
if [[ -f ~/.claude/plugins/marketplaces/claude-tools/plugins/chezmoi/scripts/shell-check.zsh ]]; then
  source ~/.claude/plugins/marketplaces/claude-tools/plugins/chezmoi/scripts/shell-check.zsh
fi
# <<< chezmoi shell sync checker end <<<
```

### Migration Steps

If migrating from old embedded code:

1. Use Read tool to find the old code block between markers:
   - Start: `# >>> chezmoi shell sync checker start >>>`
   - End: `# <<< chezmoi shell sync checker end <<<`

2. Use Edit tool to replace the entire old block with the new loader (above)

### New Installation Steps

1. Use Read tool to examine the zshrc and find insertion point
2. **Powerlevel10k users**: Insert BEFORE the `source ~/.p10k.zsh` line
3. **Others**: Append to end of zshrc
4. Use Edit tool to insert the loader code

### Chezmoi Management

If the zshrc is managed by chezmoi (source is `dot_zshrc`), apply changes:

```bash
echo "📦 Applying changes via chezmoi..."

local apply_output
if apply_output=$(chezmoi apply ~/.zshrc 2>&1); then
  echo "✅ Changes applied to ~/.zshrc"
else
  echo "❌ chezmoi apply failed"
  [[ -n "$apply_output" ]] && echo "   Output: $apply_output"
  echo "   Your source file was modified but ~/.zshrc may not be updated"
  echo "   Run 'chezmoi doctor' and 'chezmoi verify' to diagnose"
fi
```

## Reference: Verification & Troubleshooting

### Verification

```bash
echo "🔍 Verifying installation..."

if grep -q "shell-check.zsh" "$ZSHRC_SOURCE" 2>/dev/null; then
  echo "✅ Loader successfully installed"

  # Verify external script exists
  SCRIPT_PATH="$HOME/.claude/plugins/marketplaces/claude-tools/plugins/chezmoi/scripts/shell-check.zsh"
  if [[ -f "$SCRIPT_PATH" ]]; then
    echo "✅ External script found"
  else
    echo "⚠️ External script not found"
    echo "   The loader will silently skip until plugin is installed"
  fi
else
  echo "❌ Installation failed"
fi
```

Report results to user with next steps:

```
📋 Next steps:
   1. Open a new terminal to test
   2. Wait for prompt, then press Enter (empty)
   3. You should see dotfiles sync status

   To uninstall: Remove code between the markers:
   >>> chezmoi shell sync checker start >>>
   ...
   <<< chezmoi shell sync checker end <<<

   To update: Run `/plugin update` - script updates automatically!
```

### Troubleshooting

#### Warning about console output during zsh initialization

This indicates code is running during instant prompt. The stage-1 skip should prevent this. If you see this warning:

1. Ensure the loader code is placed BEFORE the p10k source line
2. Or disable instant prompt in ~/.p10k.zsh

#### Check not running

The sync checker uses a stage-based approach:

| Stage | Event | Action |
|-------|-------|--------|
| 1 | First precmd | Skip (avoids instant prompt issues) |
| 2+ | precmd + no command | Run sync check, cleanup hooks |
| 2+ | precmd + command entered | Skip check, cleanup hooks |

Compatible with: Plain zsh, Oh My Zsh, Powerlevel10k (with instant prompt).

Verify hooks are registered:

```bash
# In new terminal
echo $precmd_functions
echo $preexec_functions
```

Should include `_chezmoi_check_sync` and `_chezmoi_preexec`.

#### Script not found

If the external script is not found:

1. Ensure chezmoi plugin is installed: `/plugin install chezmoi`
2. Check marketplace is added: `/plugin marketplace add signalcompose/claude-tools`
3. The loader will silently skip until plugin is properly installed

#### Network check skipped

If you see "Remote check failed", it could be:
- Network offline
- GitHub unreachable
- Git authentication issue (check SSH keys or tokens)

#### chezmoi status failed

If you see "chezmoi status check skipped":
- Check `chezmoi doctor` for configuration issues
- Verify encryption keys are accessible
- Check file permissions on source/target directories
