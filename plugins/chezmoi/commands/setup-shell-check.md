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
ALREADY_INSTALLED=false
if [[ -n "$ZSHRC_SOURCE" ]] && grep -q "_chezmoi_check_sync" "$ZSHRC_SOURCE" 2>/dev/null; then
  echo ""
  echo "⚠️ Shell sync checker already installed in $ZSHRC_SOURCE"
  echo "   To reinstall, first remove the existing code."
  ALREADY_INSTALLED=true
fi

echo ""
echo "📋 Summary:"
echo "   Source file: $ZSHRC_SOURCE"
echo "   Prompt env:  $PROMPT_ENV"
echo "   Installed:   $ALREADY_INSTALLED"
echo "   Ready:       $SETUP_READY"
```

If `SETUP_READY=false`, inform user of missing requirements and stop.
If already installed, ask user if they want to view current configuration or exit.

## Phase 2: User Confirmation

If not already installed, show what will be added:

```
The following code will be added to your zshrc:

- Shell startup sync checker (~80 lines)
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
# >>> chezmoi shell sync checker start >>>
# chezmoi dotfiles update checker (interactive, empty-Enter triggered)
# Compatible with: plain zsh, oh-my-zsh, Powerlevel10k
# To uninstall: Remove everything between the >>> and <<< markers
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
    (( $+functions[add-zsh-hook] )) && {
      add-zsh-hook -d precmd _chezmoi_check_sync
      add-zsh-hook -d preexec _chezmoi_preexec
    }
    unset _chezmoi_stage _chezmoi_cmd_run
    return 0
  fi

  # Empty Enter: run chezmoi check and cleanup
  (( $+functions[add-zsh-hook] )) && {
    add-zsh-hook -d precmd _chezmoi_check_sync
    add-zsh-hook -d preexec _chezmoi_preexec
  }
  unset _chezmoi_stage _chezmoi_cmd_run

  local CHEZMOI_DIR="$HOME/.local/share/chezmoi"
  [[ -d "$CHEZMOI_DIR/.git" ]] || return 0

  local has_remote_updates=false
  local has_local_changes=false
  local fetch_failed=false

  # Network check and git fetch with timeout (portable: uses curl)
  if curl -s --connect-timeout 2 --max-time 3 https://github.com >/dev/null 2>&1; then
    # Git fetch with timeout (use gtimeout on macOS if available)
    local timeout_cmd=""
    if command -v timeout &>/dev/null; then
      timeout_cmd="timeout 10"
    elif command -v gtimeout &>/dev/null; then
      timeout_cmd="gtimeout 10"
    fi

    if [[ -n "$timeout_cmd" ]]; then
      $timeout_cmd git -C "$CHEZMOI_DIR" fetch origin main --quiet 2>&1 || fetch_failed=true
    else
      # No timeout available, run with risk of hanging (but curl check passed)
      git -C "$CHEZMOI_DIR" fetch origin main --quiet 2>&1 || fetch_failed=true
    fi

    if ! $fetch_failed; then
      local LOCAL=$(git -C "$CHEZMOI_DIR" rev-parse @ 2>/dev/null)
      local REMOTE=$(git -C "$CHEZMOI_DIR" rev-parse @{u} 2>/dev/null)

      if [[ -z "$LOCAL" ]]; then
        print -P "%F{yellow}⚠%f Could not determine local HEAD"
      elif [[ -z "$REMOTE" ]]; then
        # No upstream configured - not an error, just skip remote check
        :
      elif [[ "$LOCAL" != "$REMOTE" ]]; then
        has_remote_updates=true
      fi
    fi
  fi

  # Check local changes with timeout
  local chezmoi_output
  local chezmoi_status_cmd="chezmoi status"
  if command -v timeout &>/dev/null; then
    chezmoi_status_cmd="timeout 5 chezmoi status"
  elif command -v gtimeout &>/dev/null; then
    chezmoi_status_cmd="gtimeout 5 chezmoi status"
  fi

  if chezmoi_output=$($chezmoi_status_cmd 2>&1); then
    [[ -n "$chezmoi_output" ]] && has_local_changes=true
  else
    print -P "%F{yellow}⚠%f chezmoi status check skipped (timed out or failed)"
  fi

  # Display status
  if $has_remote_updates || $has_local_changes || $fetch_failed; then
    print ""
    print -P "%F{yellow}━━━ [chezmoi] Dotfiles Status ━━━%f"
    $fetch_failed && {
      print -P "  %F{yellow}⚠%f Remote check failed (git fetch error)"
    }
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
# <<< chezmoi shell sync checker end <<<
```

### Insertion Point

- **Powerlevel10k users**: Insert BEFORE the `source ~/.p10k.zsh` line
- **Others**: Append to end of zshrc

Use the Read tool to find the correct insertion point, then Edit tool to insert.

## Phase 4: Chezmoi Management

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

## Phase 5: Verification

Verify the installation:

```bash
echo "🔍 Verifying installation..."

if grep -q "_chezmoi_check_sync" "$ZSHRC_SOURCE" 2>/dev/null; then
  echo "✅ Code successfully installed"
else
  echo "❌ Installation failed"
  echo ""
  echo "   Diagnostics:"
  if [[ -f "$ZSHRC_SOURCE" ]]; then
    echo "   - File exists: yes"
    if [[ -w "$ZSHRC_SOURCE" ]]; then
      echo "   - File writable: yes"
    else
      echo "   - File writable: NO (permission issue)"
    fi
    echo "   - File size: $(wc -c < "$ZSHRC_SOURCE" 2>/dev/null || echo 'cannot read') bytes"
  else
    echo "   - File exists: NO"
  fi
  echo ""
  echo "   Try manually checking $ZSHRC_SOURCE for the code block"
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

### Network check skipped

If you see "Remote check failed", it could be:
- Network offline
- GitHub unreachable
- Git authentication issue (check SSH keys or tokens)

### chezmoi status failed

If you see "chezmoi status check skipped":
- Check `chezmoi doctor` for configuration issues
- Verify encryption keys are accessible
- Check file permissions on source/target directories
