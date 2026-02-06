# Verification & Troubleshooting

## Verification

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

## Troubleshooting

### Warning about console output during zsh initialization

This indicates code is running during instant prompt. The stage-1 skip should prevent this. If you see this warning:

1. Ensure the loader code is placed BEFORE the p10k source line
2. Or disable instant prompt in ~/.p10k.zsh

### Check not running

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

### Script not found

If the external script is not found:

1. Ensure chezmoi plugin is installed: `/plugin install chezmoi`
2. Check marketplace is added: `/plugin marketplace add signalcompose/claude-tools`
3. The loader will silently skip until plugin is properly installed

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
