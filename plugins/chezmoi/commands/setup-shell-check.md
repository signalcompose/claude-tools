---
description: "Setup shell startup sync checker for zshrc"
---

# Chezmoi Shell Sync Checker Setup

Installs an interactive dotfiles sync checker that runs on shell startup.

## Features

- Checks for remote updates and local changes at shell startup
- Compatible with all zsh environments (plain zsh, oh-my-zsh, Powerlevel10k)
- Non-intrusive: Only shows status on empty Enter press
- Automatic cleanup after first command

## Phase 1: Environment Detection

First, detect the current environment:

```bash
echo "🔍 Detecting environment..."
echo ""

# Check if zsh
if [[ -n "$ZSH_VERSION" ]]; then
  echo "✅ Shell: zsh $ZSH_VERSION"
else
  echo "❌ Shell: Not zsh (this setup requires zsh)"
  exit 1
fi

# Check chezmoi
if command -v chezmoi &>/dev/null; then
  echo "✅ chezmoi: $(chezmoi --version 2>&1 | head -1)"
else
  echo "❌ chezmoi: Not installed"
  echo "   Install with: brew install chezmoi"
  exit 1
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
  exit 1
fi

# Detect prompt environment
if [[ -n "$POWERLEVEL9K_VERSION" ]] || [[ -f ~/.p10k.zsh ]]; then
  echo "✅ Prompt: Powerlevel10k detected"
  PROMPT_ENV="p10k"
elif [[ -n "$ZSH" ]] && [[ -d "$ZSH" ]]; then
  echo "✅ Prompt: Oh My Zsh detected"
  PROMPT_ENV="omz"
else
  echo "✅ Prompt: Plain zsh"
  PROMPT_ENV="plain"
fi

# Check if already installed
if grep -q "_chezmoi_check_sync" "$ZSHRC_SOURCE" 2>/dev/null; then
  echo ""
  echo "⚠️ Shell sync checker already installed in $ZSHRC_SOURCE"
  echo "   To reinstall, first remove the existing code."
  ALREADY_INSTALLED=true
else
  ALREADY_INSTALLED=false
fi

echo ""
echo "📋 Summary:"
echo "   Source file: $ZSHRC_SOURCE"
echo "   Prompt env:  $PROMPT_ENV"
echo "   Installed:   $ALREADY_INSTALLED"
```

If already installed, ask user if they want to view current configuration or exit.

## Phase 2: User Confirmation

If not already installed, show what will be added:

```
The following code will be added to your zshrc:

- Shell startup sync checker (~70 lines)
- Checks for remote updates on GitHub
- Detects local uncommitted changes
- Shows status only when pressing empty Enter
- Compatible with Powerlevel10k instant prompt

This uses only zsh standard features (add-zsh-hook).

Proceed with installation?
1. Yes, install
2. No, cancel
```

## Phase 3: Code Installation

After user confirms, use the Edit tool to add the following code block to the user's zshrc.

### Code to Insert

```zsh
# chezmoi dotfiles update checker (interactive, empty-Enter triggered)
# Compatible with: plain zsh, oh-my-zsh, Powerlevel10k
typeset -g _chezmoi_stage=0
typeset -g _chezmoi_cmd_run=0

function _chezmoi_preexec() {
  _chezmoi_cmd_run=1
}

function _chezmoi_check_sync() {
  (( ++_chezmoi_stage ))

  # Stage 1: Skip (during instant prompt or initial load)
  (( _chezmoi_stage == 1 )) && return 0

  # Check if command was run
  if (( _chezmoi_cmd_run )); then
    # Command was entered, skip check and cleanup
    add-zsh-hook -d precmd _chezmoi_check_sync
    add-zsh-hook -d preexec _chezmoi_preexec
    unset _chezmoi_stage _chezmoi_cmd_run
    return 0
  fi

  # Empty Enter: run chezmoi check and cleanup
  add-zsh-hook -d precmd _chezmoi_check_sync
  add-zsh-hook -d preexec _chezmoi_preexec
  unset _chezmoi_stage _chezmoi_cmd_run

  local CHEZMOI_DIR="$HOME/.local/share/chezmoi"
  [[ -d "$CHEZMOI_DIR/.git" ]] || return 0

  local has_remote_updates=false
  local has_local_changes=false

  # Quick network check (2 sec timeout)
  if timeout 2 host github.com &>/dev/null; then
    git -C "$CHEZMOI_DIR" fetch origin main --quiet 2>/dev/null
    local LOCAL=$(git -C "$CHEZMOI_DIR" rev-parse @ 2>/dev/null)
    local REMOTE=$(git -C "$CHEZMOI_DIR" rev-parse @{u} 2>/dev/null)
    [[ -n "$REMOTE" && "$LOCAL" != "$REMOTE" ]] && has_remote_updates=true
  fi

  # Check local changes
  local LOCAL_STATUS=$(chezmoi status 2>/dev/null)
  [[ -n "$LOCAL_STATUS" ]] && has_local_changes=true

  # Display status
  if $has_remote_updates || $has_local_changes; then
    print ""
    print -P "%F{yellow}━━━ [chezmoi] Dotfiles Status ━━━%f"
    $has_remote_updates && {
      print -P "  %F{cyan}↓%f Remote updates available"
      print -P "    → Run: %F{green}chezmoi update%f"
    }
    $has_local_changes && {
      print -P "  %F{magenta}●%f Local changes detected"
      print -P "    → Run: %F{green}chezmoi add <file>%f then %F{green}git commit%f"
    }
    print -P "%F{yellow}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%f"
  else
    print -P "%F{green}✓%f Dotfiles synced"
  fi
}

# Register hooks (both needed from start to detect first command)
autoload -U add-zsh-hook
add-zsh-hook precmd _chezmoi_check_sync
add-zsh-hook preexec _chezmoi_preexec
```

### Insertion Point

- **Powerlevel10k users**: Insert BEFORE the `source ~/.p10k.zsh` line
- **Others**: Append to end of zshrc

Use the Read tool to find the correct insertion point, then Edit tool to insert.

## Phase 4: Chezmoi Management

If the zshrc is managed by chezmoi (source is `dot_zshrc`), apply changes:

```bash
chezmoi apply ~/.zshrc
```

## Phase 5: Verification

Verify the installation:

```bash
echo "🔍 Verifying installation..."

if grep -q "_chezmoi_check_sync" "$ZSHRC_SOURCE"; then
  echo "✅ Code successfully installed"
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

   To disable: Remove the chezmoi checker code block from your zshrc
```

## How It Works

The sync checker uses a stage-based approach:

| Stage | Event | Action |
|-------|-------|--------|
| 1 | First precmd | Skip (avoids instant prompt issues) |
| 2+ | precmd + no command | Run sync check, cleanup hooks |
| 2+ | precmd + command entered | Skip check, cleanup hooks |

This pattern is compatible with:
- **Plain zsh**: Works directly
- **Oh My Zsh**: Works with any theme
- **Powerlevel10k**: Works with instant prompt enabled

## Troubleshooting

### Warning about console output during zsh initialization

This indicates code is running during instant prompt. The stage-1 skip should prevent this. If you see this warning:

1. Ensure the checker code is placed BEFORE the p10k source line
2. Or disable instant prompt in ~/.p10k.zsh

### Check not running

Verify hooks are registered:

```bash
# In new terminal
echo $precmd_functions
echo $preexec_functions
```

Should include `_chezmoi_check_sync` and `_chezmoi_preexec`.
