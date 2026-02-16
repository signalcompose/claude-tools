---
description: Review working directory changes for code quality, security, and best practices before creating a PR
---

# Code Review for Commit

ステージング済み変更をレビューし、コミット前にすべてのcritical/important問題を修正。

## 使い方

実行: /code:review-commit

確認: git diff --staged --stat

## ワークフロー

1. **変更をステージング**: git add <files>
2. **レビュー実行**: /code:review-commit
3. **自動修正ループ**:
   - レビューチーム作成 (reviewer + fixer)
   - Reviewerが問題を発見（信頼度 >= 80）
   - Fixerがcritical/important問題を解決
   - 品質達成まで再レビュー（最大5回）
4. **コミット**: git commit -m "message"

## 品質保証

レビューループは以下を保証：
- すべてのcritical問題が解決
- すべてのimportant問題が解決
- 専門的なpr-review-toolkit:code-reviewer agentによるコード品質検証
- シンプルなフラグ方式で承認管理

## 例

```bash
# 1. 変更を加える
echo "// new feature" >> src/app.ts

# 2. 変更をステージング
git add src/app.ts

# 3. レビュー実行（チーム作成、問題修正）
/code:review-commit

# 4. コミット
git commit -m "feat: add new feature"
```

## 関連項目

- スキル実装: skills/review-commit/SKILL.md
- PR作成ゲートフック: scripts/check-pr-review-gate.sh
