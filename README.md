# claude-tools

Claude Code plugins by SignalCompose

## Overview

This repository serves as a marketplace for Claude Code plugins developed by SignalCompose. Plugins are managed as Git subtrees or directly within the repository.

> **Official Documentation**: See [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins) for details on the plugin system.

## Available Plugins

| Plugin | Description | Category | Status |
|--------|-------------|----------|--------|
| [CVI](./plugins/cvi) | Claude Voice Integration - Voice notifications for Claude Code on macOS | productivity | Available |
| [YPM](./plugins/ypm) | Your Project Manager - Project management for Claude Code | productivity | Available |
| [chezmoi](./plugins/chezmoi) | Dotfiles management integration using chezmoi | productivity | Available |
| [code](./plugins/code) | Code review workflow integration for git commits | developer-tools | Available |
| [utils](./plugins/utils) | Utility commands for plugin management (cache clearing, etc.) | developer-tools | Available |
| [codex](./plugins/codex) | OpenAI Codex CLI integration for research and code review | developer-tools | Available |
| [gemini](./plugins/gemini) | Google Gemini CLI integration for web search | productivity | Available |
| [kiro](./plugins/kiro) | AWS Kiro CLI integration for AWS expert assistance | developer-tools | Available |

## Quick Start

```bash
# 1. Add the marketplace
/plugin marketplace add signalcompose/claude-tools

# 2. Browse plugins interactively
/plugin    # Opens the Discover tab

# 3. Install a plugin
/plugin install cvi@claude-tools

# 4. Use plugin commands
/cvi:status
```

## Installation

### Add Marketplace

```bash
/plugin marketplace add signalcompose/claude-tools
```

### Install Plugins

You can browse and install plugins using the interactive `/plugin` command, or use CLI commands directly:

```bash
# Install specific plugin (format: plugin-name@marketplace-name)
/plugin install cvi@claude-tools
/plugin install ypm@claude-tools
/plugin install chezmoi@claude-tools
/plugin install code@claude-tools
/plugin install utils@claude-tools
/plugin install codex@claude-tools
/plugin install gemini@claude-tools
/plugin install kiro@claude-tools
```

### Install with Scope (Optional)

```bash
# Install to project scope (shared with team via .claude/settings.json)
/plugin install cvi@claude-tools --scope project

# Install to user scope (default, personal settings)
/plugin install cvi@claude-tools --scope user

# Install to local scope (local settings only)
/plugin install cvi@claude-tools --scope local
```

## Plugin Management

### Update Marketplace

```bash
/plugin marketplace update claude-tools
```

### Clear Plugin Cache (Important!)

Due to a known Claude Code bug ([#14061](https://github.com/anthropics/claude-code/issues/14061), [#15642](https://github.com/anthropics/claude-code/issues/15642)), running `/plugin marketplace update` updates the marketplace repository but **does not invalidate the plugin cache**. This means updated plugins may not work correctly.

**To apply updates properly:**

1. Update the marketplace:
   ```bash
   /plugin marketplace update claude-tools
   ```

2. Clear the cache for updated plugins:
   ```bash
   # Clear specific plugin cache
   /utils:clear-plugin-cache cvi
   /utils:clear-plugin-cache utils

   # Or clear all plugin caches for this marketplace
   /utils:clear-plugin-cache --all --marketplace claude-tools
   ```

3. Restart Claude Code

**Dry run** (see what would be deleted):
```bash
/utils:clear-plugin-cache cvi --dry-run
```

### Other Commands

```bash
# List all marketplaces
/plugin marketplace list

# Remove marketplace
/plugin marketplace remove claude-tools

# Uninstall plugin
/plugin uninstall cvi@claude-tools

# Disable plugin (without uninstalling)
/plugin disable cvi@claude-tools

# Enable plugin
/plugin enable cvi@claude-tools

# Validate marketplace
/plugin validate .
```

## Documentation

- [docs/INDEX.md](./docs/INDEX.md) - Documentation index
- [docs/specifications.md](./docs/specifications.md) - Marketplace and plugin specifications
- [docs/architecture.md](./docs/architecture.md) - Architecture overview
- [docs/development-guide.md](./docs/development-guide.md) - Plugin development guide
- [docs/onboarding.md](./docs/onboarding.md) - Onboarding guide for contributors

### Official Claude Code Documentation

- [Create plugins](https://code.claude.com/docs/en/plugins) - Plugin creation guide
- [Plugins reference](https://code.claude.com/docs/en/plugins-reference) - Technical reference
- [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) - Marketplace creation
- [Discover plugins](https://code.claude.com/docs/en/discover-plugins) - Plugin installation

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes
4. Push to your branch
5. Create a Pull Request

See [docs/development-guide.md](./docs/development-guide.md) for detailed instructions.

## License

MIT License
