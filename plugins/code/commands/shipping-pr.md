---
description: Autonomously commit, code review, fix, push, and create a PR
---

# Shipping PR

コードレビュー・修正ループを経て、自律的にコミット・プッシュ・PR作成を行う。

## 使い方

```
/code:shipping-pr                        # 変更を自動検出してPR作成
/code:shipping-pr <commit-message-hint>  # コミットメッセージのヒントを指定
```

## 実行ステップ

| ステップ | 内容 |
|---------|------|
| 1 | 変更を分析（staged/unstaged/committed）|
| 2 | ファイルをステージング（.env等除外）|
| 3 | `pr-review-toolkit:code-reviewer` でコードレビュー |
| 4 | critical/important 問題を修正（最大3回ループ）|
| 5 | レビュー承認フラグを作成 |
| 6 | Conventional Commits 形式でコミット |
| 7 | `git push` |
| 8 | GitHub MCP で PR 作成 |
| 9 | サマリーレポート出力 |

## 重要事項

- このスキルがコード出荷の**唯一の正規経路**（アドホックな push + PR は禁止）
- `--no-verify` は絶対に使わない
- `.env` やシークレットは絶対にコミットしない

## 関連スキル

- `/code:dev-cycle` — 全サイクル（shipping-pr 含む）
- `/code:audit-compliance` — 監査（shipping-pr 前に実行）
- `/code:review-commit` — コードレビューのみ実行
