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

**ファイル名**: タイムスタンプ付きで生成する（キャッシュ問題・バージョン混在を防ぐため）

```
draft-{トピックの英語スラッグ}-{YYYYMMDD}-{HHmm}.md
例: draft-draftjs-paste-tips-20260219-1430.md
```

タイムスタンプは現在時刻を使用すること。

**保存先**: `.x-article/` ディレクトリ（存在しない場合は作成する）。
Write ツールには絶対パスが必要なため、`pwd` で取得したカレントディレクトリを先頭に付けて絶対パスを構築すること（例: `pwd` が `/Users/yamato/proj` なら `/Users/yamato/proj/.x-article/draft-xxx.md`）。
このディレクトリは `.gitignore` 済みのワークスペースであり、`/x-article:cleanup` で一括削除できる。

**保存後、ファイルパスを明示的に出力する**（publishフェーズで引数として使用するため）:

```
ドラフトを保存しました:
  ファイルパス: /path/to/draft-draftjs-paste-tips-20260219-1430.md

次のコマンドで公開できます:
  /x-article:publish /path/to/draft-draftjs-paste-tips-20260219-1430.md
```

## Step 4: 次のステップを案内

ドラフト生成後、以下を案内する（**ファイルパスを各コマンドに明記すること**）:

1. `/x-article:header --title "記事タイトル"` でヘッダー画像を生成
2. `/x-article:review {ファイルパス}` でファクトチェック
3. `/x-article:publish {ファイルパス}` で公開

**フェーズを分けるメリット**: 下書きフェーズと公開フェーズを別セッションで実行できる。長文記事でコンテキストが枯渇した場合も、ファイルパスを引数に渡すことで新セッションから継続できる。
