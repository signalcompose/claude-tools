# Phase 4A: New Setup Guide (First Machine)

Guide user through these steps interactively:

## Step 1: Create age key

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

## Step 2: Create chezmoi.toml

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

## Step 3: Initialize chezmoi

```bash
chezmoi init
cd ~/.local/share/chezmoi
git init
```

## Step 4: Add initial files

Guide user to add their first dotfiles:

```bash
# Non-sensitive files
chezmoi add ~/.zshrc
chezmoi add ~/.gitconfig

# Sensitive files (encrypted)
chezmoi add --encrypt ~/.ssh/config
chezmoi add --encrypt ~/.ssh/id_rsa
```

## Step 5: Create GitHub repository

```bash
cd ~/.local/share/chezmoi
git add .
git commit -m "Initial commit: Add dotfiles managed by chezmoi"

# Create private repository
gh repo create USERNAME/dotfiles --private --source=. --remote=origin --push
```
