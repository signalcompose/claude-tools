---
description: Watch a Codex job for progress, stalls, and external kills
---

# Watch Codex Job

Codex companion のジョブを監視し、**進捗・停滞・外部 kill** を行として出力する。

## なぜ必要か

`codex-companion.mjs status --json` の `status` を待機条件にしてはいけない。
ジョブが外部から kill されても `"status": "running"` のまま残る（dead pid の回収処理が
存在しない）ため、`until status != running` のループは**永久に発火しない**。
2026-08-27 にこれで 64 分を失った。

このコマンドは companion を呼ばず `state.json` を直接読み、**ログの mtime と pid の生存**
という2つの事実で判定する。

## Usage

引数なしで、現在の workspace の実行中ジョブを監視する:

!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/watch-codex.sh --help`

```
watch-codex.sh [job-id] [--stall-secs N] [--interval N] [--workspace PATH] [--state-root PATH]
```

`job-id` は `codex-companion.mjs status --json` の `running[].id`、または
`state.json` の `jobs[].id`。**発注直後に監視を張るなら job-id を明示する**のが確実
（省略時は「その workspace の最新 active ジョブ」を選ぶため、起動が早すぎると
まだ対象が存在しない）。

## 出力する行と exit code

| 行 | 意味 | exit |
|---|---|---|
| `MILESTONE` | コマンド完了/**失敗**（exit code つき） | - |
| `PHASE` | `editing -> verifying` などの遷移 | - |
| `STALL` | ログが N 秒伸びていない・**プロセスは生存** | 2 |
| `KILLED` | **pid 消滅・state は running のまま** | 3 |
| `DONE` | `status=completed` で正常終了 | 0 |
| `FAILED` | `status=failed`/`cancelled` 等で終了 | 4 |
| `ERROR` | 監視対象を解決できない / 監視を継続できない | 1 |

成功と失敗を同じ exit 0 に畳まない。畳むと呼び出し側が終了コードで区別できず、
「running でなくなった＝成功」という元の誤りに戻る。

起動時点で完了済みのマイルストーンは再生しない（件数と直近1件だけ表示）。

## 回し方

`Monitor` tool に食わせるか、`run_in_background` で回す。
出力行がそのまま通知したい事象になっている。

## 🔴 STALL が出た時の心得

**「N 分応答なし」を即ハングと断定しない。** `STALL` と `KILLED` を分けているのは、
原因が違えば対処も違うため。

| 事象 | 意味 | 対処 |
|---|---|---|
| `KILLED` | プロセスが消滅している | ハングではない。**再開**する。原因調査に時間を使わない |
| `STALL` | プロセスは生きているがログが伸びない | 長時間コマンドかハング。**まず当のコマンドを自分で回して切り分ける** |

2026-08-27 の実例: 停滞していたコマンドを手元で実行したら exit 0・数秒で完了した。
つまりハングではなく外部 kill だった。切り分けを飛ばして「ハングの原因調査」に
入っていたら、さらに時間を失っていた。

詳細は `${CLAUDE_PLUGIN_ROOT}/references/codex-stall-triage.md` を読む。
