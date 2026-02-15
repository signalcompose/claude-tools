#!/bin/bash
# Chezmoi Status Check Script

# Check if chezmoi is installed
if ! command -v chezmoi &> /dev/null; then
  echo "❌ chezmoi is not installed"
  echo ""
  echo "Install with: brew install chezmoi"
  exit 1
fi

echo "📋 Chezmoi Status Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: chezmoi status
echo "🔄 Modified files:"
STATUS=$(chezmoi status 2>&1)
STATUS_EXIT=$?
if [ $STATUS_EXIT -ne 0 ]; then
  echo "  ⚠️ chezmoi status failed (exit code: $STATUS_EXIT)"
  echo "$STATUS" | sed 's/^/  /'
  STATUS_FAILED=true
elif [ -z "$STATUS" ]; then
  echo "  (no changes)"
else
  echo "$STATUS" | sed 's/^/  /'
fi
echo ""

# Step 2: Git sync status
echo "📊 Git status:"
CHEZMOI_DIR=~/.local/share/chezmoi
if [ -d "$CHEZMOI_DIR/.git" ]; then
  cd "$CHEZMOI_DIR"
  git fetch origin main --quiet 2>/dev/null
  git status -sb | head -1 | sed 's/^/  /'
  echo ""

  # Determine next steps
  LOCAL=$(git rev-parse @ 2>/dev/null)
  REMOTE=$(git rev-parse @{u} 2>/dev/null)
  AHEAD=$(git rev-list --count @{u}..@ 2>/dev/null || echo "0")
  BEHIND=$(git rev-list --count @..@{u} 2>/dev/null || echo "0")

  echo "💡 Next steps:"
  if [ "$STATUS_FAILED" = true ]; then
    echo "  - ⚠️ chezmoi status failed. Check if 1Password desktop app is running"
    echo "  - Or run: chezmoi status (manually to see full error)"
  elif [ -n "$STATUS" ] && [ "$BEHIND" -gt 0 ]; then
    echo "  - Run /chezmoi:sync to pull latest changes"
    echo "  - Then run /chezmoi:commit to push your changes"
  elif [ -n "$STATUS" ]; then
    echo "  - Run /chezmoi:commit to commit and push your changes"
  elif [ "$BEHIND" -gt 0 ]; then
    echo "  - Run /chezmoi:sync to pull latest changes from remote"
  elif [ "$AHEAD" -gt 0 ]; then
    echo "  - Run git push to push your commits"
  else
    echo "  - All up to date! No action needed."
  fi
else
  echo "  ⚠️ Chezmoi source directory not found or not a git repo"
  echo ""
  echo "💡 Next steps:"
  echo "  - Run /chezmoi:setup to configure chezmoi"
fi

# Step 3: Check for old embedded sync checker
ZSHRC_SOURCE="$HOME/.local/share/chezmoi/dot_zshrc"
if [ ! -f "$ZSHRC_SOURCE" ]; then
  ZSHRC_SOURCE="$HOME/.zshrc"
fi

if [ -f "$ZSHRC_SOURCE" ]; then
  HAS_OLD_EMBED=$(grep -c '_chezmoi_check_sync' "$ZSHRC_SOURCE" 2>/dev/null || true)
  HAS_LOADER=$(grep -c 'shell-check.zsh' "$ZSHRC_SOURCE" 2>/dev/null || true)

  if [ "$HAS_OLD_EMBED" -gt 0 ] && [ "$HAS_LOADER" -eq 0 ]; then
    echo ""
    echo "⚠️  Shell sync checker:"
    echo "  Old embedded code detected in your zshrc."
    echo "  This version has a known bug on macOS (timeout command missing)."
    echo "  Run /chezmoi:shell-sync-setup to migrate to the new loader style."
  fi
fi
