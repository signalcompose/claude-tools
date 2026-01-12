---
description: "Interactive setup wizard for chezmoi + age + 1Password"
---

# Chezmoi Setup Wizard

Interactive setup guide for chezmoi dotfiles management with age encryption and 1Password integration.

## Phase 1: Environment Check

First, check if required tools are installed:

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

If any required tools are missing, ask the user to install them first.

## Phase 2: Detect Existing Setup

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

## Phase 3: Setup Mode Selection

Based on existing setup, ask user which mode to proceed with:

**If existing setup found:**
```
Your chezmoi is already configured.
What would you like to do?

1. Check current status (/chezmoi:check)
2. Reconfigure from scratch (will backup existing config)
3. Cancel
```

**If no existing setup:**
```
No existing chezmoi setup found.
What would you like to do?

1. New setup (first machine) - Create new dotfiles repository
2. Clone existing (second+ machine) - Clone from existing repository
3. Cancel
```

## Phase 4A: New Setup Guide (First Machine)

Guide user through these steps interactively:

### Step 1: Create age key

```bash
mkdir -p ~/.config/chezmoi
age-keygen -o ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt

# Show public key
echo ""
echo "📋 Your age public key (save this!):"
grep "public key:" ~/.config/chezmoi/key.txt
```

**Important**: Tell user to save the public key for the next step.

### Step 2: Create chezmoi.toml

Ask user for their macOS username, then:

```bash
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
encryption = "age"

[onepassword]
    command = "op"

[age]
    identity = "/Users/USERNAME/.config/chezmoi/key.txt"
    recipient = "AGE_PUBLIC_KEY"
EOF
```

Replace `USERNAME` and `AGE_PUBLIC_KEY` with actual values.

### Step 3: Initialize chezmoi

```bash
chezmoi init
cd ~/.local/share/chezmoi
git init
```

### Step 4: Add initial files

Guide user to add their first dotfiles:

```bash
# Non-sensitive files
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig

# Sensitive files (encrypted)
chezmoi add --encrypt ~/.ssh/config
chezmoi add --encrypt ~/.ssh/id_rsa
```

### Step 5: Create GitHub repository

```bash
cd ~/.local/share/chezmoi
git add .
git commit -m "Initial commit: Add dotfiles managed by chezmoi"

# Create private repository
gh repo create USERNAME/dotfiles --private --source=. --remote=origin --push
```

## Phase 4B: Clone Existing Guide (Second+ Machine)

### Step 1: Get age key from secure location

Tell user: "You need the age key (key.txt) from your first machine.
Retrieve it from 1Password Secure Notes or AirDrop."

```bash
mkdir -p ~/.config/chezmoi
# User manually places key.txt here
chmod 600 ~/.config/chezmoi/key.txt
```

### Step 2: Create chezmoi.toml

Same as Phase 4A Step 2.

### Step 3: Initialize and apply

```bash
chezmoi init --apply git@github.com:USERNAME/dotfiles.git
```

This will:
- Clone the repository
- Decrypt encrypted files
- Apply dotfiles

## Phase 5: Verification

After setup, verify everything works:

```bash
# Check status
chezmoi status

# Verify files
ls -la ~/.zshrc ~/.gitconfig ~/.ssh/

# Test SSH (if applicable)
ssh -T git@github.com
```

## Notes

- This wizard guides you through setup but cannot fully automate it
- Age key must be manually transferred between machines
- 1Password integration requires desktop app connected to CLI
- Always backup existing dotfiles before starting
