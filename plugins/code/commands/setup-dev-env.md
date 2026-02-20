---
description: Check and fix dev environment setup (Node.js, deps, build, git, MCP, permissions)
---

# Setup Dev Env

開発環境をチェックし、dev-cycle ワークフローを実行するための前提条件を確認する。

## 使い方

```
/code:setup-dev-env          # チェックのみ（変更なし）
/code:setup-dev-env --fix    # チェック＋自動修正
```

## チェック内容

| # | チェック | 説明 |
|---|---------|------|
| 1 | Node.js >= 20 | バージョン確認 |
| 2 | Dependencies | node_modules の存在と鮮度 |
| 3 | Build | dist/ ディレクトリの存在 |
| 4 | Git branch | mainブランチ外にいることを確認 |
| 5 | GitHub MCP | mcp__github__get_me の疎通確認 |
| 6 | Code review skill | code:review-commit スキルの存在確認 |
| 7 | Permissions | settings.local.json の権限設定確認 |

## 実行前に必要なもの

- Node.js >= 20
- Git リポジトリ（remote origin 設定済み）
- GitHub MCP の設定（`.mcp.json`）

## 関連スキル

- `/code:dev-cycle` — メインのdev-cycleワークフロー
- `/code:sprint-impl` — スプリント実装サブワークフロー
