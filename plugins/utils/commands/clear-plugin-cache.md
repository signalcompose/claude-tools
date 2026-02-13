---
description: Clear plugin cache to fix stale version issues after /plugin update
argument-hint: <plugin-name> [--marketplace <name>] [--all] [--dry-run] [-y/--yes]
---

# Clear Plugin Cache

This command clears the plugin cache to resolve stale version issues caused by Claude Code's cache invalidation bug.

## Background

When running `/plugin update`, Claude Code updates the marketplace git repository but does not invalidate the cached plugin files. This causes updated plugins to not work correctly until the cache is manually cleared.

Related issues:
- [#14061](https://github.com/anthropics/claude-code/issues/14061) - `/plugin update` does not invalidate plugin cache
- [#15642](https://github.com/anthropics/claude-code/issues/15642) - CLAUDE_PLUGIN_ROOT points to stale version

## Sandbox要件

**重要**: このコマンドはプラグインキャッシュファイルの削除のためsandboxバイパスが必要です。

`dangerouslyDisableSandbox: true`で実行する理由:
- 操作: `~/.claude/plugins/cache/`内のディレクトリを削除
- Sandbox制限: デフォルトでは書き込み操作がブロックされる
- 安全な操作: ユーザーが開始したキャッシュクリーンアップ、システム変更のリスクなし

## Usage

以下のBashコマンドを**即座に実行**してください:

**重要**: ファイル削除のため`dangerouslyDisableSandbox: true`を使用してください。

Bash toolで実行:
- **コマンド**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/clear-plugin-cache.sh "$ARGUMENTS"`
- **dangerouslyDisableSandbox**: `true`（必須）

## Arguments

| Argument | Description |
|----------|-------------|
| `plugin-name` | Name of the plugin to clear cache for |
| `--marketplace <name>` | Specify marketplace (default: claude-tools) |
| `--all` | Clear all plugin caches for the specified marketplace |
| `--dry-run` | Show what would be deleted without actually deleting |
| `-y, --yes` | Skip confirmation prompt (useful for automated workflows) |

## Examples

- Clear single plugin: `/utils:clear-plugin-cache cvi`
- Clear with marketplace: `/utils:clear-plugin-cache plugin --marketplace other-market`
- Clear all: `/utils:clear-plugin-cache --all --marketplace claude-tools`
- Clear all (skip confirmation): `/utils:clear-plugin-cache --all --marketplace claude-tools -y`
- Dry run: `/utils:clear-plugin-cache cvi --dry-run`

## After Clearing

After clearing the cache, restart Claude Code for changes to take effect.
