---
description: Run a post-sprint retrospective with Auditor and Researcher agents to verify quality and process
---

# Retrospective

出荷後に Auditor と Researcher エージェントによる振り返りを実施する。

## 使い方

```
/code:retrospective             # 現在のブランチを振り返り
/code:retrospective <branch>    # 指定ブランチを振り返り
```

## 実行ステップ

| ステップ | 内容 |
|---------|------|
| 1 | スコープ確認（ブランチ、コミット一覧）|
| 2 | Auditor + Researcher エージェントを並列実行 |
| 3 | レポートを統合し、改善を適用 |
| 4 | 問題があれば修正・コミット |
| 5 | 振り返りアーティファクトをコミット |
| 6 | ブランチをプッシュ |

## エージェント役割

- **Auditor**: DDD/TDD/DRY/ISSUE/PROCESS の5原則を検証
- **Researcher**: コード品質・アーキテクチャを分析

## 関連スキル

- `/code:dev-cycle` — 全サイクル（retrospective 含む）
- `/code:audit-compliance` — 原則監査のみ
