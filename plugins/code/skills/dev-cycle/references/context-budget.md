# Context Budget Management

## 概要

dev-cycle は4ステージ（sprint → audit → ship → retrospective）を1セッションで連鎖実行する。
1M コンテキスト環境では十分な余裕があるが、長大なスプリントでは後半ステージに影響する可能性がある。

この仕組みは、ステージ間にコンテキスト予算チェックを追加し、予算不足時は状態保存 → 次セッション再開への誘導を行う。

## アーキテクチャ: 3層防御

```
┌─────────────────────────────────────────┐
│  Layer 1: Hook-based Hard Gate          │
│  PostToolUse → sidecar → Stop hook      │
│  (確実に阻止)                            │
├─────────────────────────────────────────┤
│  Layer 2: SKILL.md Soft Gate            │
│  各ステージ遷移ブロック内の予算チェック指示  │
│  (Claude が自律的に判断)                  │
├─────────────────────────────────────────┤
│  Layer 3: Extended State File           │
│  dev-cycle.state.json に停止情報を記録    │
│  (次セッションでの再開情報)                │
└─────────────────────────────────────────┘
```

### Layer 1: Hook データフロー

```
PostToolUse hook (dev-cycle-context-monitor.sh)
  → .claude/.context-budget.json に remaining% 書き込み
                    ↓
Stop hook (dev-cycle-stop.sh)
  → 方法1: stdin の context_window から直接読み取り
  → 方法2: sidecar ファイルからフォールバック
                    ↓
  OK (残量 >= 閾値): 次ステージ強制 (現行動作)
  NG (残量 < 閾値):  停止許可 + state ファイルに記録 + 再開ガイド出力
```

### Layer 2: SKILL.md ソフトゲート

各ステージの "On success" ブロックに予算チェック手順を追加。
Claude が `.context-budget.json` を読んで自律的に停止判断する。

### Layer 3: 拡張 State ファイル

予算不足で停止した場合、`dev-cycle.state.json` に以下を記録:

```json
{
  "stage": "sprint",
  "status": "stopped",
  "stopped_reason": "context_budget",
  "skipped_stages": ["audit", "ship", "retrospective"],
  "remaining_pct": 35.2
}
```

## 閾値設計

1M 環境での暫定閾値（実測結果で最終決定予定）:

| 遷移ポイント | 閾値 | 残りステージの消費見込み |
|-------------|------|----------------------|
| sprint → audit | remaining >= 15% | audit + ship + retro |
| audit → ship | remaining >= 10% | ship + retro |
| ship → retro | remaining >= 5% | retro |

1M 環境では余裕があるため、閾値を大幅に引き下げ。
実測結果に応じて調整する。

## sidecar ファイル仕様

**パス**: `.claude/.context-budget.json`

```json
{
  "remaining": 65.3,
  "ts": 1708617600,
  "stage": "sprint"
}
```

- `remaining`: コンテキスト残量 (%)
- `ts`: Unix タイムスタンプ（鮮度チェック用、5分以上古いデータは無視）
- `stage`: 現在のステージ（state ファイル消失時の復元に使用）

**Git 管理外**: `.gitignore` に登録済み

## shipping-pr でのレビュー反復制限

dev-cycle 中（`.claude/dev-cycle.state.json` が存在する場合）:
- Fix Loop の上限は 3（1M 環境では十分な余裕がある）

## トラブルシューティング

### 予算データが記録されない

1. `jq` がインストールされているか確認
2. `dev-cycle.state.json` が存在するか確認（PostToolUse hook の前提条件）
3. `context_window.remaining_percentage` が stdin に含まれているか確認

### 予算チェックが効かない（常に続行）

1. `.context-budget.json` のタイムスタンプが5分以内か確認
2. Stop hook の stdin に `context_window` が含まれていれば、sidecar ファイルは不要
3. 両方とも取得できない場合、現行動作（強制続行）にフォールバック

### 予算停止後に再開できない

1. `cat .claude/dev-cycle.state.json` で状態を確認
2. `status: "stopped"` なら `skipped_stages` の最初から再開
3. 再開前に state ファイルをリセット: `echo '{"stage": "<resume_stage>"}' > .claude/dev-cycle.state.json`
