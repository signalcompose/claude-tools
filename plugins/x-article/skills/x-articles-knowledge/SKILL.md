---
name: x-articles-knowledge
description: |
  X (Twitter) Articles のエディタ仕様・記事構造・ベストプラクティス。
  Use when: "X Articlesの記事を書く", "Twitter Article", "X Articlesのエディタ",
  "DraftJSの制約", "ヘッダー画像を作る", "記事を公開する", "X Articlesに投稿",
  "ヘッダー画像を生成する", "publish to X Articles".
user-invocable: false
---

# X Articles ナレッジベース

X (Twitter) Articles への記事投稿に関する知見をまとめたリファレンス集。

## 用途別リファレンス

### ヘッダー画像を生成したい場合

`${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/header-image.md` を読む。

スクリプト: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/header-image.py --title "..." --subtitle "..."`

### 記事のドラフトを作成したい場合

`${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/article-structure.md` を読む。

記事の方針・構成テンプレート・X Articles の制約（マークダウン変換ルール）を確認すること。

### エディタにコンテンツを貼り付けたい場合

`${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/draftjs-editor.md` を読む。

DraftJS の制約、成功パターン（DataTransfer + ClipboardEvent）、カーソル操作の注意点。

### ファクトチェック・レビューをしたい場合

`${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/fact-checking.md` を読む。

URL 確認方法、コマンド名・マーケットプレイス名の検証手順。

### ブラウザ自動操作をしたい場合

`${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/browser-automation.md` を読む。

Claude in Chrome MCP / Playwright MCP の使い分け、フォールバック手順。

## コマンドとの連携

| コマンド | 参照先 |
|---------|-------|
| `/x-article:draft` | article-structure.md |
| `/x-article:header` | header-image.md（スクリプト直接実行） |
| `/x-article:review` | fact-checking.md |
| `/x-article:publish` | draftjs-editor.md + browser-automation.md |
