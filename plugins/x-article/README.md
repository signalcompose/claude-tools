# x-article

X (Twitter) Articles への記事投稿ワークフローを自動化するプラグイン。

手作業で記事を投稿した際に得られた知見（DraftJS の制約・ヘッダー画像生成・ブラウザ操作パターン）を
スキルとして格納し、コマンドから参照できる構造になっています。

## インストール

```bash
/plugin install x-article
```

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `/x-article:draft <topic>` | 記事ドラフトを生成 |
| `/x-article:header --title <title> [--subtitle <subtitle>]` | ヘッダー画像を生成（1200×480 PNG）|
| `/x-article:review [draft-file.md]` | ファクトチェック・レビュー |
| `/x-article:publish [draft-file.md]` | ブラウザ自動操作で記事を公開 |

## ワークフロー例

```bash
# 1. ドラフト生成
/x-article:draft "DraftJS エディタで安定ペーストする方法"

# 2. ヘッダー画像生成
/x-article:header --title "DraftJS Paste Tips" --subtitle "X Articles エディタで安定ペーストする方法" --output .x-article/header.png

# 3. ファクトチェック
/x-article:review .x-article/draft-draftjs-paste-tips.md

# 4. 公開
/x-article:publish .x-article/draft-draftjs-paste-tips.md
```

## 必要な MCP（publish コマンド）

`/x-article:publish` はブラウザ操作に以下の MCP を使用します（優先順位順）:

1. **Claude in Chrome MCP**（推奨）: ユーザーのブラウザを使うため X に既にログイン済み
2. **Playwright MCP**（フォールバック）: 別プロセスでブラウザ起動
3. **手動案内**（MCP なし）: JS スニペットを出力してユーザーが手動実行

Claude in Chrome MCP を使うと 1Password 等の Chrome 拡張が有効なままブラウザ操作できます。

## 記事執筆の方針

このプラグインが生成するドラフトは以下の方針に従います:

- **汎用ナレッジ共有**が目的（特定プロジェクトの宣伝記事にしない）
- プライベートなプロジェクト名・リポジトリ名は伏せる
- パブリックな OSS はそのまま記載可
- For English Readers / TL;DR セクションは英語で書く

## 要件

- Python 3.10+（ヘッダー画像生成）
- Pillow（自動インストール）
- Claude in Chrome MCP または Playwright MCP（publish コマンド）

## ライセンス

MIT
