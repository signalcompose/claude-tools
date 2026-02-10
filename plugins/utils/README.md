# utils

Utility commands and skills for Claude Code plugin management and testing.

## Overview

This plugin provides utility commands and skills to help manage and test Claude Code plugins. It includes workarounds for plugin cache issues and an interactive testing framework.

## Skills

### `/utils:plugin-test <plugin-name>`

Interactive plugin testing with automated validation and step-by-step manual test guidance.

**Features**:
- **Phase 1: Automated Validation** (5 checks)
  - Script syntax validation
  - Executable permissions check
  - Hook configuration verification
  - File structure validation
  - Sandbox compatibility scan

- **Phase 2: Manual Testing** (interactive)
  - Plugin type detection (Hook-based, Voice/Audio, Team/Agent, Utility)
  - Step-by-step test guidance
  - User confirmation for each test
  - Result recording and summary

**Usage**:
```
/utils:plugin-test code
/utils:plugin-test cvi
/utils:plugin-test ypm
```

**Benefits**:
- Reduces manual test time by 50%
- Provides consistent test coverage
- Automates repetitive checks
- Guides through manual tests interactively
- Generates test summary report

See `skills/plugin-test/SKILL.md` for detailed documentation.

---

## Available Commands

### `/utils:clear-plugin-cache`

Clear plugin cache to fix stale version issues after running `/plugin update`.

## Known Issues (Claude Code)

This plugin exists as a workaround for known Claude Code bugs:

| Issue | Description | Status |
|-------|-------------|--------|
| [#14061](https://github.com/anthropics/claude-code/issues/14061) | `/plugin update` does not invalidate plugin cache | Open |
| [#15642](https://github.com/anthropics/claude-code/issues/15642) | CLAUDE_PLUGIN_ROOT points to stale version | Open |
| [#15369](https://github.com/anthropics/claude-code/issues/15369) | Plugin uninstall does not clear cached files | Open |
| [#16453](https://github.com/anthropics/claude-code/issues/16453) | Plugin cache grows indefinitely | Open |

## Installation

```bash
/plugin install utils@claude-tools
```

## Usage

### Clear Single Plugin Cache

```bash
# Clear cache for a specific plugin (default marketplace: claude-tools)
/utils:clear-plugin-cache cvi

# Clear cache for a plugin from another marketplace
/utils:clear-plugin-cache some-plugin --marketplace other-market
```

### Clear All Plugin Caches

```bash
# Clear all plugin caches for a marketplace (requires confirmation)
/utils:clear-plugin-cache --all --marketplace claude-tools
```

### Dry Run

Preview what would be deleted without actually deleting:

```bash
/utils:clear-plugin-cache cvi --dry-run
/utils:clear-plugin-cache --all --marketplace claude-tools --dry-run
```

## After Clearing Cache

After clearing the cache, **restart Claude Code** for changes to take effect.

## Cache Location

Plugin caches are stored at:
```
~/.claude/plugins/cache/<marketplace>/<plugin>/
```

## License

MIT
