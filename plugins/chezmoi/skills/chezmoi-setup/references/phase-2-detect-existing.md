# Phase 2: Detect Existing Setup

Check if chezmoi is already configured:

```bash
echo "🔍 Checking existing setup..."
echo ""

# Check chezmoi source directory
if [ -d ~/.local/share/chezmoi/.git ]; then
  echo "✅ Chezmoi source directory exists: ~/.local/share/chezmoi"
  cd ~/.local/share/chezmoi
  echo "   Remote: $(git remote get-url origin 2>/dev/null || echo 'No remote')"
  echo "   Branch: $(git branch --show-current)"
else
  echo "⚠️ Chezmoi source directory not found"
fi

# Check age key
if [ -f ~/.config/chezmoi/key.txt ]; then
  echo "✅ Age key exists: ~/.config/chezmoi/key.txt"
else
  echo "⚠️ Age key not found"
fi

# Check chezmoi.toml
if [ -f ~/.config/chezmoi/chezmoi.toml ]; then
  echo "✅ Chezmoi config exists: ~/.config/chezmoi/chezmoi.toml"
else
  echo "⚠️ Chezmoi config not found"
fi

echo ""
```
