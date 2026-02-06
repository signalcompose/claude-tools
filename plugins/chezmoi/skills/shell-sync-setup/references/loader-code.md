# Loader Code & Installation

## Loader Code to Insert

```zsh
# >>> chezmoi shell sync checker start >>>
# Loader for chezmoi shell sync checker
# Source: https://github.com/signalcompose/claude-tools
if [[ -f ~/.claude/plugins/marketplaces/claude-tools/plugins/chezmoi/scripts/shell-check.zsh ]]; then
  source ~/.claude/plugins/marketplaces/claude-tools/plugins/chezmoi/scripts/shell-check.zsh
fi
# <<< chezmoi shell sync checker end <<<
```

## Migration Steps

If migrating from old embedded code:

1. Use Read tool to find the old code block between markers:
   - Start: `# >>> chezmoi shell sync checker start >>>`
   - End: `# <<< chezmoi shell sync checker end <<<`

2. Use Edit tool to replace the entire old block with the new loader (above)

## New Installation Steps

1. Use Read tool to examine the zshrc and find insertion point
2. **Powerlevel10k users**: Insert BEFORE the `source ~/.p10k.zsh` line
3. **Others**: Append to end of zshrc
4. Use Edit tool to insert the loader code

## Chezmoi Management

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
