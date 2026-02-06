# Environment Detection & Migration Check

## Phase 1: Environment Detection

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

## Phase 2: Migration Check

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
    echo "⚠️ Found OLD embedded code (~140 lines in zshrc)"
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

### For New Installation

Present the loader features and ask for confirmation.

### For Migration

Present migration benefits (7 lines vs 140 lines) and ask for confirmation.
