# claude-tools

Claude Code plugins by SignalCompose

## Overview

This repository serves as a marketplace for Claude Code plugins developed by SignalCompose. Plugins are managed as git submodules.

## Available Plugins

| Plugin | Description | Status |
|--------|-------------|--------|
| [CVI](./plugins/cvi) | Claude Voice Integration - Voice notifications for Claude Code on macOS | Available |
| [YPM](./plugins/ypm) | Your Project Manager - Project management for Claude Code | Available |
| [chezmoi](./plugins/chezmoi) | Dotfiles management integration using chezmoi | Available |
| [code](./plugins/code-review) | Code review workflow integration for git commits | Available |

## Installation

### 1. Add Marketplace

```bash
/plugin marketplace add signalcompose/claude-tools
```

### 2. Install Plugins

```bash
# Install specific plugin
/plugin install cvi@claude-tools
/plugin install ypm@claude-tools
/plugin install chezmoi@claude-tools
/plugin install code@claude-tools
```

### 3. Update Marketplace

```bash
/plugin marketplace update claude-tools
```

## Quick Start

1. Add the marketplace with `/plugin marketplace add signalcompose/claude-tools`
2. Install desired plugins with `/plugin install <plugin>@claude-tools`
3. Use plugin commands (e.g., `/cvi:status`, `/ypm:update`, `/chezmoi:check`, `/code:review-commit`)
4. See individual plugin documentation for detailed usage

## Documentation

- [docs/INDEX.md](./docs/INDEX.md) - Documentation index
- [docs/specifications.md](./docs/specifications.md) - Marketplace specifications
- [docs/architecture.md](./docs/architecture.md) - Architecture overview
- [docs/development-guide.md](./docs/development-guide.md) - Plugin development guide

## Contributing

1. Fork this repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Commit your changes
4. Push to your branch
5. Create a Pull Request

See [docs/development-guide.md](./docs/development-guide.md) for detailed instructions.

## License

MIT License
