# chezmoi - Claude Code Plugin

Claude Code integration for [chezmoi](https://www.chezmoi.io/) dotfiles management.

## Features

- **Status Check**: View local changes and sync state with remote
- **Sync**: Pull latest dotfiles from remote repository
- **Commit**: Stage, commit, and push dotfile changes
- **Setup Wizard**: Interactive guide for initial configuration

## Requirements

- macOS or Linux
- [chezmoi](https://www.chezmoi.io/) installed (`brew install chezmoi`)
- Git configured with SSH access to your dotfiles repository
- (Optional) [age](https://github.com/FiloSottile/age) for encryption (`brew install age`)
- (Optional) [1Password CLI](https://developer.1password.com/docs/cli/) for secret management

## Installation

```
/plugin marketplace add signalcompose/claude-tools
/plugin install chezmoi
```

## Commands

| Command | Description |
|---------|-------------|
| `/chezmoi:check` | Check dotfiles status and sync state |
| `/chezmoi:sync` | Sync from remote repository |
| `/chezmoi:commit` | Commit and push dotfile changes |
| `/chezmoi:setup` | Interactive setup wizard |
| `/chezmoi:setup-shell-check` | Setup shell startup sync checker |

### Shell Startup Sync Checker

The `/chezmoi:setup-shell-check` command installs a shell sync checker that runs at startup.

**Architecture**: Uses a minimal loader approach (6 lines in zshrc) that sources an external script:

```
~/.zshrc (loader)
    ↓ source
~/.claude/plugins/.../shell-check.zsh (auto-updated via /plugin update)
```

**Benefits**:
- Keeps zshrc clean (6 lines vs 140+ embedded)
- Auto-updates when you run `/plugin update`
- Silently skips if plugin not installed

**Migration**: If you have the old embedded code (~140 lines), running the setup will offer to migrate to the new loader style.

## Usage

### Check Status

```
/chezmoi:check
```

Shows:
- Modified files (local changes)
- Git sync status (ahead/behind remote)
- Suggested next actions

### Sync from Remote

```
/chezmoi:sync
```

Pulls latest changes from remote and applies them to your system.

### Commit Changes

```
/chezmoi:commit
```

Interactive workflow:
1. Detects changed dotfiles
2. Shows changes and asks for confirmation
3. Adds files to chezmoi source
4. Commits with descriptive message
5. Pushes to remote

### Initial Setup

```
/chezmoi:setup
```

Interactive wizard for:
- First machine: Create new dotfiles repository
- Second+ machine: Clone existing repository

## Architecture

chezmoi manages dotfiles by:
1. Storing source files in `~/.local/share/chezmoi/`
2. Tracking changes with Git
3. Applying files to home directory with `chezmoi apply`

This plugin provides Claude Code commands to streamline the workflow.

```
~/.local/share/chezmoi/     # Source (Git-managed)
├── dot_zshrc               # ~/.zshrc
├── dot_gitconfig           # ~/.gitconfig
└── private_dot_ssh/        # ~/.ssh/ (encrypted with age)

↓ chezmoi apply

~/                          # Target (actual dotfiles)
├── .zshrc
├── .gitconfig
└── .ssh/
```

## Security

- Age encryption keys (`key.txt`) are **never read** by this plugin
- Sensitive files can be encrypted with `chezmoi add --encrypt`
- 1Password integration keeps secrets out of Git

## Troubleshooting

### chezmoi not found

Install chezmoi:
```bash
brew install chezmoi
```

### Push rejected (non-fast-forward)

Remote has newer changes. Run `/chezmoi:sync` first.

### Age decryption failed

Ensure `~/.config/chezmoi/key.txt` exists and matches the encryption key.

## License

MIT License - see [LICENSE](./LICENSE)
