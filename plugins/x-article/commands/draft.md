---
description: "Generate X Articles draft markdown from topic and target audience"
argument-hint: "<topic> [--lang <ja|en>]"
---

# X Articles ドラフト生成

## Step 1: 記事構造ガイドを読む

`${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/article-structure.md` を**必ず最初に読む**こと。

## Step 2: ドラフト生成（方針の厳守）

以下の方針を**すべて厳守**してドラフトを生成する:

### プライバシー・公開範囲

- **プライベートなプロジェクト名・リポジトリ名は伏せる**
  - 例: 「あるOSSプロジェクト」「チームで使っているツール」等に置き換え
- **パブリックな OSS・GitHub public リポジトリはそのまま記載可**
- コードは**必ず抽象化**（プロジェクト固有の変数名・ファイルパス等を除去）

### 文体・構成

- **コンパクト**に書く（各セクション 300 字程度を目安）
- For English Readers セクションと TL;DR は**英語**で書く
- 読者が「何を検索すれば良いか」が伝わる書き方
- 構成テンプレート（article-structure.md 参照）に従う

### X Articles 制約の適用

- テーブル → `Before → After` テキスト形式、または箇条書きに変換
- コードブロック → `[ここにコードを手動挿入: コードブロックボタンで追加]` フラグに
- 水平線 → `[ここに仕切りを手動挿入: エディタの「─」ボタンで追加]` フラグに

## Step 3: ファイルとして保存

生成したドラフトをマークダウンファイルとして保存する。

ファイル名の提案例: `draft-{トピックの英語スラッグ}.md`（例: `draft-draftjs-paste-tips.md`）

ユーザーに保存先を確認してから保存すること。

## Step 4: 次のステップを案内

ドラフト生成後、以下を案内する:

1. `/x-article:header` でヘッダー画像を生成
2. `/x-article:review` でファクトチェック
3. `/x-article:publish` で公開
