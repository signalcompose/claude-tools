---
description: "Fact-check and review X Articles draft"
argument-hint: "[markdown-file-path]"
---

# X Articles レビュー・ファクトチェック

## Step 1: ファクトチェックガイドを読む

`${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/fact-checking.md` を**最初に読む**こと。

## Step 2: ドラフトの読み込み

引数でファイルパスが指定された場合はそのファイルを読み込む。
指定がない場合は、現在のディレクトリにある `draft-*.md` ファイルを探してユーザーに選択を促す。

## Step 3: 外部 URL の確認

ドラフト内の外部 URL をすべて抽出し、`curl` で確認する。

Bash tool で実行:
- **コマンド例**: `curl -sI --max-time 5 "https://example.com" | head -5`
- **dangerouslyDisableSandbox**: `true`（sandbox 環境でネットワークアクセスがブロックされる場合があるため）
- **間隔**: URL ごとに 1 秒間隔を空けること

## Step 4: コマンド名・固有名詞の確認

以下を確認する（fact-checking.md の一覧を参照）:

- Claude Code コマンド名（`/plugin install` 等）の正確性
- プラグイン名のスペル・ハイフン区切り
- X / Twitter 関連の現在の正式名称
- 技術用語のキャピタライゼーション（DraftJS, DataTransfer 等）

## Step 5: レビュー結果の報告

以下の分類で報告する:

### Critical（修正必須）
（URL 404、事実誤記等）

### Important（修正推奨）
（コマンド名ミス、名称の誤り等）

### Minor（任意）
（表記揺れ、スタイル等）
