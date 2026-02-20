---
description: Run the full development cycle (sprint, audit, ship, retrospective) autonomously
---

# Dev Cycle

実装からPR作成、振り返りまでの全サイクルを自律実行する。

## 使い方

```
/code:dev-cycle <plan-source>
```

`<plan-source>` には以下を指定できる:
- GitHub Issue URL（例: `https://github.com/owner/repo/issues/123`）
- プランファイルパス（例: `docs/plans/phase-2-plan.md`）
- インライン説明
- 空（`docs/plans/` から次のフェーズを自動検出）

## 実行ステージ

| ステージ | スキル | 説明 |
|---------|--------|------|
| 1 | `code:sprint-impl` | 実装スプリント |
| 2 | `code:audit-compliance` | 原則コンプライアンス監査 |
| 3 | `code:shipping-pr` | コードレビュー＋PR作成 |
| 4 | `code:retrospective` | 振り返り＋改善 |

## 関連スキル

- `/code:setup-dev-env` — 実行前の環境チェック
- `/code:sprint-impl` — スプリントのみ実行
- `/code:audit-compliance` — 監査のみ実行
- `/code:shipping-pr` — PR作成のみ実行
- `/code:retrospective` — 振り返りのみ実行
