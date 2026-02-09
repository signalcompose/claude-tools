# Phase 4B: Clone Existing Guide (Second+ Machine)

## Step 1: Get age key from secure location

Tell user: "You need the age key (key.txt) from your first machine.
Retrieve it from 1Password Secure Notes or AirDrop."

```bash
mkdir -p ~/.config/chezmoi
# User manually places key.txt here
chmod 600 ~/.config/chezmoi/key.txt
```

## Step 2: Create chezmoi.toml

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

## Step 3: Initialize and apply

```bash
chezmoi init --apply git@github.com:USERNAME/dotfiles.git
```

This will:
- Clone the repository
- Decrypt encrypted files
- Apply dotfiles
