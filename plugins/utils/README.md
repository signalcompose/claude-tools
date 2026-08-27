# utils

Utility commands for Claude Code plugin management and local plugin-ecosystem workarounds.

## Overview

This plugin collects local operational tools that poke at Claude Code's own installation — the plugin cache under `~/.claude/plugins/cache/` and the plugin data layer under `~/.claude/plugins/data/`. It exists mainly to work around known bugs in Claude Code and in the plugin ecosystem.

## Available Commands

### `/utils:clear-plugin-cache`

Clear plugin cache to fix stale version issues after running `/plugin update`.

### `/utils:watch-codex`

Watch a Codex companion job and report progress, stalls, and **external kills**.

Codex ジョブが外部から kill されても `status` は `running` のまま残るため、
`until status != running` の待機ループは永久に発火しない。このコマンドは
`state.json` を直接読み、**ログの mtime と pid の生存**という2つの事実で判定する。

```bash
/utils:watch-codex <job-id>
```

| 行 | 意味 | exit |
|---|---|---|
| `MILESTONE` | コマンド完了/失敗 | - |
| `PHASE` | フェーズ遷移 | - |
| `STALL` | ログが伸びない・**プロセスは生存** | 2 |
| `KILLED` | **pid 消滅・state は running のまま** | 3 |
| `DONE` | `status=completed` で正常終了 | 0 |
| `FAILED` | `failed`/`cancelled` 等で終了 | 4 |

停滞時の切り分け手順は [references/codex-stall-triage.md](./references/codex-stall-triage.md)。

> `/utils:watch-codex` は `openai-codex/codex` プラグインのジョブ状態
> (`~/.claude/plugins/data/codex-openai-codex/state/`) を読む。同プラグインが
> 未導入の場合は明示エラーで停止する。

## Known Issues

This plugin exists as a workaround for known bugs in Claude Code and in plugins it depends on:

| Issue | Description | Status |
|-------|-------------|--------|
| [#14061](https://github.com/anthropics/claude-code/issues/14061) | `/plugin update` does not invalidate plugin cache | Open |
| [#15642](https://github.com/anthropics/claude-code/issues/15642) | CLAUDE_PLUGIN_ROOT points to stale version | Open |
| [#15369](https://github.com/anthropics/claude-code/issues/15369) | Plugin uninstall does not clear cached files | Open |
| [#16453](https://github.com/anthropics/claude-code/issues/16453) | Plugin cache grows indefinitely | Open |
| `openai-codex/codex` 1.0.6 | Killed jobs keep `"status": "running"` — dead pids are never reconciled | Open (upstream) |
| `openai-codex/codex` 1.0.6 | `status --json` filters `running[]` by current Claude session id, so watchers outside the owning session see an empty list | Open (upstream) |

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
