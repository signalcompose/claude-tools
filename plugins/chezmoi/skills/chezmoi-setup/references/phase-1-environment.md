# Phase 1: Environment Check

Check if required tools are installed:

```bash
echo "🔍 Checking required tools..."
echo ""

# Check chezmoi
if command -v chezmoi &> /dev/null; then
  echo "✅ chezmoi: $(chezmoi --version)"
else
  echo "❌ chezmoi: Not installed"
  echo "   Install with: brew install chezmoi"
fi

# Check age
if command -v age &> /dev/null; then
  echo "✅ age: $(age --version 2>&1 | head -1)"
else
  echo "❌ age: Not installed"
  echo "   Install with: brew install age"
fi

# Check 1Password CLI
if command -v op &> /dev/null; then
  echo "✅ op: $(op --version)"
else
  echo "⚠️ op: Not installed (optional)"
  echo "   Install with: brew install --cask 1password-cli"
fi

# Check GitHub CLI
if command -v gh &> /dev/null; then
  echo "✅ gh: $(gh --version | head -1)"
else
  echo "⚠️ gh: Not installed (optional)"
  echo "   Install with: brew install gh"
fi

echo ""
```

If any required tools (chezmoi, age) are missing, ask the user to install them first.
