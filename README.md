# claude-tools

[![GitHub Sponsors](https://img.shields.io/badge/GitHub_Sponsors-Signal_compose-EA4AAA?style=for-the-badge&logo=github)](https://github.com/sponsors/signalcompose)
[![GitHub Sponsors](https://img.shields.io/badge/GitHub_Sponsors-dropcontrol-EA4AAA?style=for-the-badge&logo=github)](https://github.com/sponsors/dropcontrol)

Development workflow plugins for Claude Code's official plugin system.

## Core Workflow

These plugins work together to form an end-to-end development lifecycle:

```
/ypm:new           Set up a new project with plans and documentation
     |
/code:dev-cycle    Autonomously run: sprint -> audit -> ship -> retrospective
     |
/code:simplify     (optional) Simplify and refine code post-implementation
     |
/code:pr-review-team   Team-based PR review with specialized agents
     |
/ypm:update        Update project status after shipping
```

### Before & After

**Without dev-cycle** (manual steps):
1. Read the plan, create issue, write specs
2. Implement feature, run tests
3. Stage files, review code, fix issues, re-review
4. Commit, push, create PR
5. Run PR review, fix findings, push again
6. Write retrospective notes

**With `/code:dev-cycle`**:
```bash
/code:dev-cycle docs/plans/phase-3-plan.md
```
One command. Four stages run autonomously.

### dev-cycle Stages

| Stage | What happens |
|-------|-------------|
| **Sprint** | Plan parsing, issue creation, parallel team implementation, tests, build verification |
| **Audit** | DDD/TDD/DRY/ISSUE/PROCESS compliance check |
| **Ship** | Code review loop (auto-fix), commit, push, PR creation |
| **Retrospective** | Two-agent parallel analysis, learnings update, metrics recording |

## Design Principles

1. **Documentation Driven Development (DDD)**: Documentation is the single source of truth. Specs are written before code, and kept in sync with implementation.

2. **Official Plugin System Compliance**: Built on Claude Code's plugin system (skills, commands, hooks, agents). No custom runtime or framework required.

3. **External CLI Bridge**: Integrates external CLI tools (Codex, Gemini, Kiro) as Claude Code plugins, bringing their capabilities into the same workflow.

## Available Plugins

### Development Lifecycle

| Plugin | Commands | Description |
|--------|----------|-------------|
| [ypm](./plugins/ypm) | `/ypm:new`, `/ypm:update`, `/ypm:next` | Project management - setup wizard, status tracking, task prioritization |
| [code](./plugins/code) | `/code:dev-cycle`, `/code:shipping-pr`, `/code:review-commit` | Autonomous dev lifecycle, code review, PR creation gate |

### Supporting Tools

| Plugin | Commands | Description |
|--------|----------|-------------|
| [cvi](./plugins/cvi) | `/cvi:speak`, `/cvi:lang`, `/cvi:check` | Voice notifications for Claude Code on macOS |
| [codex](./plugins/codex) | `/codex:research`, `/codex:review` | OpenAI Codex CLI integration for research and code review |
| [gemini](./plugins/gemini) | `/gemini:search` | Google Gemini CLI integration for web search |
| [kiro](./plugins/kiro) | `/kiro:research` | AWS Kiro CLI integration for AWS expert assistance |
| [chezmoi](./plugins/chezmoi) | `/chezmoi:check`, `/chezmoi:sync` | Dotfiles management integration using chezmoi |
| [utils](./plugins/utils) | `/utils:clear-plugin-cache` | Utility commands for plugin cache management |
| [x-article](./plugins/x-article) | `/x-article:draft`, `/x-article:publish` | X (Twitter) Articles publishing workflow |

## Quick Start

```bash
# 1. Add the marketplace
/plugin marketplace add signalcompose/claude-tools

# 2. Browse plugins interactively
/plugin    # Opens the Discover tab

# 3. Install a plugin
/plugin install code@claude-tools

# 4. Run the dev cycle
/code:dev-cycle docs/plans/my-plan.md
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
/plugin install x-article@claude-tools
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
- [docs/dev-cycle-guide.md](./docs/dev-cycle-guide.md) - Dev Cycle usage guide and permissions philosophy
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

MIT License - Signal compose Inc.
