# Codex ジョブが黙った時の切り分け

## 前提: 沈黙には少なくとも3種類ある

Codex に委譲したジョブから出力が来なくなった時、原因は1つではない。
**原因が違えば対処も違う**ので、対処を選ぶ前に必ず切り分ける。

| 種類 | 実際に起きていること | 対処 |
|---|---|---|
| **外部 kill** | プロセスが消滅。state は `running` のまま残る | 再開する。原因調査に時間を使わない |
| **長時間コマンド** | 正常。`cargo test` などが単に長い | 待つ。閾値を上げる |
| **ハング** | プロセスは生きているが進まない | 原因調査に入る |

`/utils:watch-codex` はこの区別を出力する。`KILLED` は1番目、`STALL` は2番目か3番目。

## 🔴 「N 分応答なし」を即ハングと断定しない

これが最も高くつく誤りになる。

2026-08-27 の実例: orbitscore で 64 分沈黙したジョブについて、停滞していた
コマンドを手元で実行したところ **exit 0・数秒で完了**した。つまりハングではなく
外部 kill だった。「ハングの原因調査」に入っていたら、存在しないバグを
探して更に時間を失っていた。

**最初にやることは仮説を立てることではなく、事実を1つ取ること。**

## 切り分けの手順

### 1. プロセスは生きているか

```bash
# state.json から pid を取る
python3 -c "
import json, glob
for f in glob.glob('$HOME/.claude/plugins/data/codex-openai-codex/state/*/state.json'):
    for j in json.load(open(f)).get('jobs', []):
        if j.get('status') in ('running', 'queued'):
            print(j['id'], j.get('pid'), j.get('phase'), j['updatedAt'])
"

# 生存確認（ps/pgrep は sandbox で拒否されうるが kill -0 はシェル組み込みなので通る）
kill -0 <pid> && echo ALIVE || echo DEAD
```

**DEAD なら外部 kill。** `status` が `running` でも信用しない。
companion に dead pid の回収処理は無く、状態は永久に残る。

### 2. 生きているなら、止まっているコマンドを自分で回す

```bash
# ログから最後に開始されたコマンドを取る
grep -a "Running command" <logFile> | tail -1
```

そのコマンドを手元で実行する。

- **すぐ終わる** → ハングではない。ジョブ側の問題（kill・環境・sandbox）を疑う
- **本当に長い** → 正常。`--stall-secs` を上げて待つ
- **手元でも止まる** → ここで初めてハングの原因調査に入る

### 3. ログが本当に伸びていないかを見る

```bash
stat -f %m <logFile>   # macOS
```

⚠️ **ログ行のタイムスタンプは UTC (`...Z`)、ファイルの mtime はローカル時刻。**
両者を直接見比べると 9 時間ずれて混乱する。比較するなら epoch 同士で行う。

## なぜ `status --json` を待機条件にしてはいけないか

openai-codex/codex 1.0.6 を読んで確認した2点。

### 1. dead pid が回収されない

ジョブが kill されても `state.json` の `status` は `running` のまま。
したがって次の待機ループは**永久に発火しない**。

```bash
# ❌ これは沈黙と実行中を区別できない
until [ "$(... status --json | jq -r .running[0].status)" != "running" ]; do sleep 30; done
```

### 2. `running[]` は現在の Claude セッション ID でフィルタされる

`codex-companion.mjs` の `filterJobsForCurrentClaudeSession` により、
**所有セッション外から呼ぶと `running: []` が返る**。
これを終了判定に使うと、ジョブが元気に動いていても初回ポーリングで
「終わった」と誤判定する。

```bash
# ❌ 別セッション・cron・バックグラウンドから呼ぶと即座に誤発火する
if ! ... status --json | grep -q '"status": "running"'; then echo DONE; fi
```

### 正しい生存signal

**自己申告ではなく、実際に起きている事実を見る。**

- ログファイルの **mtime**（実際に書かれているか）
- pid の **生存**（`kill -0`）

`/utils:watch-codex` はこの2つで判定している。

## 監視は発注と同時に張る

沈黙に気づくのが遅れる最大の原因は、監視を張っていないこと。
`/codex:rescue` などで長い実装を委譲する時は、**発注直後に job-id を渡して**
監視を起動する。

```bash
# status --json の running[].id、または state.json の jobs[].id
/utils:watch-codex <job-id>
```

job-id を省略すると「その workspace の最新 active ジョブ」を選ぶため、
**発注より前に監視を起動すると対象がまだ存在せず ERROR になる**。
