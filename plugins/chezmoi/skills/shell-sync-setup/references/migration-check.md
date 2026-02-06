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

### For Migration

```
Found old embedded code in your zshrc (~140 lines).
Recommend migrating to new loader style (7 lines).

Benefits of migration:
- zshrc stays clean (7 lines vs 140 lines)
- Auto-updates via /plugin update
- Same functionality

Migration will:
1. Remove old embedded code
2. Add new loader (7 lines)

Proceed with migration?
1. Yes, migrate to new style
2. No, keep old style
```
