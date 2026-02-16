---
description: Run team-based PR review with parallel specialized agents and iterative fix loop
---

# PR Review Team

チーム編成による PR レビュー。4つの専門エージェントを並行起動し、CI 結果と統合して反復的に修正。

## 使い方

```
/code:pr-review-team [PR番号]
```

PR番号を省略すると、現在のブランチに紐づく PR を自動検出します。

## ワークフロー

1. **対象PR特定** — PR番号の解決、プロジェクトコンテキスト検出
2. **レビューチーム作成** — 4つの専門レビュアー + fixer を並行起動
   - code-reviewer: コード品質・バグ検出
   - silent-failure-hunter: サイレント障害・エラーハンドリング
   - pr-test-analyzer: テストカバレッジ分析
   - comment-analyzer: コメント正確性検証
3. **CI結果収集** — `gh pr checks` で CI 状態を取得、失敗ログ分析
4. **統合・修正** — レビュー結果 + CI 結果を fixer に一括送信
5. **反復ループ** — Critical/Important = 0 かつセキュリティ全合格まで（最大5回）
6. **完了報告** — サマリー表示、マージはユーザー指示待ち

## 完了条件

- Critical 問題 = 0
- Important 問題 = 0
- セキュリティチェックリスト全項目合格

## 関連

- **pre-commit レビュー**: `/code:review-commit`（コミット前の品質ゲート）
- **リファクタリング**: `/code:refactor-team`（PR非依存のコード改善）
