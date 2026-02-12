---
description: "Interactive setup wizard for chezmoi dotfiles management with age encryption and 1Password integration"
---

# Chezmoi Setup Wizard

## Overview

Interactive setup guide for chezmoi dotfiles management with age encryption and 1Password integration.

**Capabilities**:
- Guides through 5-phase setup
- Supports age encryption and 1Password integration
- Handles both new setup and clone existing scenarios

**Use when**: "set up chezmoi", "configure dotfiles", "initialize chezmoi", "first time setup", "new machine setup", "chezmoi初期設定", "dotfiles設定", "1Password連携", "初回セットアップ"

**Don't use for**: Updating existing dotfiles, syncing changes, checking status

**5 Phases**:
1. Environment check (tools availability)
2. Detect existing setup
3. Setup mode selection (new vs clone)
4. Guided setup (new machine or clone existing)
5. Verification

## Execution

Follow the 5 phases sequentially. Read the Reference sections for detailed instructions.

### Phase 1: Environment Check

Check if required tools are installed (see Reference: Phase 1 below).

### Phase 2: Detect Existing Setup

Check if chezmoi is already configured (see Reference: Phase 2 below).

### Phase 3: Mode Selection

Based on existing setup, ask user which mode to proceed with (see Reference: Phase 3 below).

### Phase 4: Setup Guide

Based on selection:
- **New setup (first machine)**: See Reference: Phase 4A below
- **Clone existing (second+ machine)**: See Reference: Phase 4B below

### Phase 5: Verification

After setup, verify everything works (see Reference: Phase 5 below).

## Reference: Phase 1 - Environment Check

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

## Reference: Phase 2 - Detect Existing Setup

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

## Reference: Phase 3 - Setup Mode Selection

Based on existing setup, ask user which mode to proceed with:

### If Existing Setup Found

```
Your chezmoi is already configured.
What would you like to do?

1. Check current status (/chezmoi:check)
2. Reconfigure from scratch (will backup existing config)
3. Cancel
```

### If No Existing Setup

```
No existing chezmoi setup found.
What would you like to do?

1. New setup (first machine) - Create new dotfiles repository
2. Clone existing (second+ machine) - Clone from existing repository
3. Cancel
```

## Reference: Phase 4A - New Setup (First Machine)

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

## Reference: Phase 4B - Clone Existing (Second+ Machine)

### Step 1: Get age key from secure location

Tell user: "You need the age key (key.txt) from your first machine.
Retrieve it from 1Password Secure Notes or AirDrop."

```bash
mkdir -p ~/.config/chezmoi
# User manually places key.txt here
chmod 600 ~/.config/chezmoi/key.txt
```

### Step 2: Create chezmoi.toml

Same as Phase 4A Step 2. Ask user for username and age public key.

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

### Step 3: Initialize and apply

```bash
chezmoi init --apply git@github.com:USERNAME/dotfiles.git
```

This will:
- Clone the repository
- Decrypt encrypted files
- Apply dotfiles

## Reference: Phase 5 - Verification

After setup, verify everything works:

```bash
# Check status
chezmoi status

# Verify files
ls -la ~/.zshrc ~/.gitconfig ~/.ssh/

# Test SSH (if applicable)
ssh -T git@github.com
```

Report results to user with next steps.
