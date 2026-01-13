---
name: clear-plugin-cache
description: Clear plugin cache to fix stale version issues after /plugin update
argument-hint: <plugin-name> [--marketplace <name>] [--all] [--dry-run]
allowed-tools:
  - Bash
---

# Clear Plugin Cache

This command clears the plugin cache to resolve stale version issues caused by Claude Code's cache invalidation bug.

## Background

When running `/plugin update`, Claude Code updates the marketplace git repository but does not invalidate the cached plugin files. This causes updated plugins to not work correctly until the cache is manually cleared.

Related issues:
- [#14061](https://github.com/anthropics/claude-code/issues/14061) - `/plugin update` does not invalidate plugin cache
- [#15642](https://github.com/anthropics/claude-code/issues/15642) - CLAUDE_PLUGIN_ROOT points to stale version

## Usage

Execute the cache clear script with the provided arguments:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/clear-plugin-cache.sh $ARGUMENTS
```

## Arguments

| Argument | Description |
|----------|-------------|
| `plugin-name` | Name of the plugin to clear cache for |
| `--marketplace <name>` | Specify marketplace (default: claude-tools) |
| `--all` | Clear all plugin caches for the specified marketplace |
| `--dry-run` | Show what would be deleted without actually deleting |

## Examples

- Clear single plugin: `/utils:clear-plugin-cache cvi`
- Clear with marketplace: `/utils:clear-plugin-cache plugin --marketplace other-market`
- Clear all: `/utils:clear-plugin-cache --all --marketplace claude-tools`
- Dry run: `/utils:clear-plugin-cache cvi --dry-run`

## After Clearing

After clearing the cache, restart Claude Code for changes to take effect.
