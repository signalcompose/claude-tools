---
description: Run an implementation sprint with parallel team agents, TDD, and verification
---

# Sprint Implementation

実装プランを受け取り、並列チームエージェントで実装し、テスト・型チェックを行う。

## 使い方

```
/code:sprint-impl <plan-source>
```

`<plan-source>` には以下を指定できる:
- GitHub Issue URL
- プランファイルパス（例: `docs/plans/phase-2-plan.md`）
- インライン説明
- 空（`docs/plans/` から次のフェーズを自動検出）

## 実行フェーズ

| フェーズ | 内容 |
|---------|------|
| 0 | Serena コンテキスト読み込み |
| 1 | コンテキスト収集（CLAUDE.md、docs、package.json）|
| 2 | 依存関係チェック（npm install）|
| 3 | Issue トラッキング設定 |
| 4 | タスク依存関係分析 |
| 4.5 | DDD スペックドキュメント作成 |
| 5 | シーケンシャル基盤実装 |
| 6 | 並列実装（Team Agent）|
| 7 | 統合検証（tsc, vitest, eslint）|
| 8 | カバレッジチェック |
| 9 | サマリーレポート |

## 関連スキル

- `/code:dev-cycle` — 全サイクル実行（sprint → audit → ship → retro）
- `/code:audit-compliance` — 実装後の監査
