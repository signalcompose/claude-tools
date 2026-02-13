#!/usr/bin/env zsh
# chezmoi shell sync checker
# Source: https://github.com/signalcompose/claude-tools
# Auto-updated via: /plugin update
#
# This script provides dotfiles sync checking at shell startup.
# Compatible with: plain zsh, oh-my-zsh, Powerlevel10k
#
# Features:
# - Checks for remote updates on GitHub
# - Detects local uncommitted changes
# - Shows status only when pressing empty Enter
# - Auto-cleans hooks after first command
#
# To uninstall: Remove the loader from your zshrc

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
  if [[ ! -d "$CHEZMOI_DIR/.git" ]]; then
    print -P "%F{yellow}⚠%f chezmoi directory is not a git repository"
    return 0
  fi

  local has_remote_updates=false
  local has_local_changes=false
  local fetch_failed=false
  local network_offline=false
  local has_status_timeout=false

  # Network check and git fetch with timeout (portable: uses curl)
  if curl -s --connect-timeout 2 --max-time 3 https://github.com >/dev/null 2>&1; then
    # Git fetch with timeout (use gtimeout on macOS if available)
    local -a timeout_cmd=()
    if command -v timeout &>/dev/null; then
      timeout_cmd=(timeout 10)
    elif command -v gtimeout &>/dev/null; then
      timeout_cmd=(gtimeout 10)
    fi

    # Detect default branch (fallback to main)
    local default_branch=$(git -C "$CHEZMOI_DIR" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    [[ -z "$default_branch" ]] && default_branch="main"

    if [[ ${#timeout_cmd[@]} -gt 0 ]]; then
      "${timeout_cmd[@]}" git -C "$CHEZMOI_DIR" fetch origin "$default_branch" --quiet 2>&1 || fetch_failed=true
    else
      # No timeout available, run with risk of hanging (but curl check passed)
      git -C "$CHEZMOI_DIR" fetch origin "$default_branch" --quiet 2>&1 || fetch_failed=true
    fi

    if ! $fetch_failed; then
      local LOCAL=$(git -C "$CHEZMOI_DIR" rev-parse @ 2>/dev/null)
      local REMOTE_OUTPUT REMOTE_EXIT
      REMOTE_OUTPUT=$(git -C "$CHEZMOI_DIR" rev-parse @{u} 2>&1)
      REMOTE_EXIT=$?

      if [[ -z "$LOCAL" ]]; then
        print -P "%F{yellow}⚠%f Could not determine local HEAD"
      elif [[ $REMOTE_EXIT -ne 0 ]]; then
        # Check if it's "no upstream" (expected) or actual error
        if [[ "$REMOTE_OUTPUT" =~ "no upstream" ]]; then
          # No upstream configured - normal for some setups, skip quietly
          :
        else
          print -P "%F{yellow}⚠%f Could not check upstream: ${REMOTE_OUTPUT:0:50}"
        fi
      elif [[ "$LOCAL" != "$REMOTE_OUTPUT" ]]; then
        has_remote_updates=true
      fi
    fi
  else
    network_offline=true
  fi

  # Check local changes with timeout (configurable via CHEZMOI_STATUS_TIMEOUT)
  local timeout_seconds=${CHEZMOI_STATUS_TIMEOUT:-5}
  local chezmoi_output chezmoi_exit
  local -a chezmoi_status_cmd=(chezmoi status)
  if command -v timeout &>/dev/null; then
    chezmoi_status_cmd=(timeout $timeout_seconds chezmoi status)
  elif command -v gtimeout &>/dev/null; then
    chezmoi_status_cmd=(gtimeout $timeout_seconds chezmoi status)
  fi

  chezmoi_output=$("${chezmoi_status_cmd[@]}" 2>&1)
  chezmoi_exit=$?

  if [[ $chezmoi_exit -eq 0 ]]; then
    [[ -n "$chezmoi_output" ]] && has_local_changes=true
  elif [[ $chezmoi_exit -eq 124 ]]; then
    print -P "%F{yellow}⚠%f chezmoi status timed out (>${timeout_seconds}s)"
    print -P "   → Run: %F{green}/chezmoi:diagnose-timeout%f to investigate"
    has_status_timeout=true
  else
    print -P "%F{yellow}⚠%f chezmoi status failed (exit $chezmoi_exit)"
    [[ -n "$chezmoi_output" ]] && print "   ${chezmoi_output:0:80}"
  fi

  # Display status
  if $has_remote_updates || $has_local_changes || $fetch_failed || $network_offline || $has_status_timeout; then
    print ""
    print -P "%F{yellow}━━━ [chezmoi] Dotfiles Status ━━━%f"
    $network_offline && {
      print -P "  %F{yellow}⚠%f Network offline - remote check skipped"
    }
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
    $has_status_timeout && {
      print -P "  %F{yellow}⚠%f Sync status unknown (timeout)"
      print -P "    → Increase timeout: %F{green}export CHEZMOI_STATUS_TIMEOUT=10%f"
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
