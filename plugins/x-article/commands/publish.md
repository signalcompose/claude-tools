---
description: "Publish X Articles draft via browser automation (Claude in Chrome MCP)"
argument-hint: "[markdown-file-path]"
---

# X Articles 公開

## Step 1: 必須リファレンスを読む

以下を**順番に**読むこと:

1. `${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/draftjs-editor.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/browser-automation.md`

## Step 2: ドラフトの読み込みと変換

**このコマンドは単独のセッションで実行できる**（下書きフェーズとの分離が可能）。

引数でファイルパスが指定された場合はそのファイルを読み込む。
指定がない場合は、現在のディレクトリにある `draft-*.md` ファイルを探してユーザーに選択を促す。

```
# 推奨: ファイルパスを明示的に渡す
/x-article:publish /path/to/draft-topic-20260219-1430.md

# 引数なしも可（カレントディレクトリの draft-*.md を検索）
/x-article:publish
```

マークダウンを X Articles 用 HTML に変換する（article-structure.md のルールに従う）:
- テーブル → テキスト形式
- コードブロック → `[手動挿入フラグ]` を残す
- 水平線 → `[手動挿入フラグ]` を残す

セクションを `## ` ヘッダーで分割する（3000 文字以上のセクションはさらに分割）。

## Step 3: ブラウザ MCP の確認と選択

利用可能な MCP ツールを確認し、以下の優先順位で使用する:

| 優先度 | 手段 | 確認方法 |
|--------|------|---------|
| 1 | Claude in Chrome MCP | `mcp__Claude_in_Chrome__` で始まるツールが存在するか |
| 2 | Playwright MCP | `mcp__playwright__` で始まるツールが存在するか |
| 3 | 手動案内 | 上記どちらもない場合 |

**Claude in Chrome を優先する理由**: ユーザーの実ブラウザを使うため X にログイン済み。Playwright は拡張機能（1Password 等）が動作しない。

## Step 4: X Articles エディタを開く

選択した MCP で `https://x.com/compose/articles` へ navigate する。
ページ読み込み後、「create」ボタン（新規記事作成）をクリックする。
エディタが表示されるまで待機する。

**注意**: `https://x.com/articles/new` は存在しないため使用しないこと。

## Step 5: タイトルを入力する

タイトル入力欄を特定して記事タイトルを入力する。

## Step 6: ヘッダー画像のアップロード（ユーザーに依頼）

**AskUserQuestion** ツールで以下を確認:

「ヘッダー画像を手動でアップロードしてください。アップロード完了後、「続行」と入力してください。（ヘッダー画像ファイル: header.png または `--title` 引数で生成したもの）」

ユーザーの確認後に次のステップへ進む。

## Step 7: セクションごとにペースト

browser-automation.md の DataTransfer + ClipboardEvent パターンを使用する。

### DraftJS の h2 ブロック認識の制約と回避策

**DraftJS の挙動**: ペースト時、HTMLの最初のブロック要素は現在の段落に追記される（ブロック境界が無視される）。2番目以降の要素は正しく新規ブロックとして認識される。

**正しいペースト戦略**:

1. **Section 1（最初）**: 通常通りペーストする（エディタが空なので問題なし）
   ```
   <h2>セクション1タイトル</h2><p>段落...</p>
   ```

2. **Section 2以降（2つ目〜）**: ゼロ幅スペース `\u200B` のダミー先頭ブロックを追加し、**残りのセクションをまとめて1回でペースト**する（ただし合計 3000 文字を超える場合は `draftjs-editor.md` の「ペースト分割戦略」に従い 2〜3 セクションずつに分割すること）
   ```
   <p>\u200B</p><h2>セクション2タイトル</h2><p>段落...</p><h2>セクション3タイトル</h2><p>段落...</p>
   ```
   - `\u200B`（ゼロ幅スペース）は不可視文字なので直前段落に混入しても視覚影響なし
   - `<h2>` は2番目以降の要素なので正しく新規ブロックとして認識される

**各ペーストの手順**:
1. カーソルをエディタ末尾に移動（`range.collapse(false)` + `focus()`）
2. 100ms 待機
3. `DataTransfer` + `ClipboardEvent` でペースト（`text/plain: ''` 必須）
4. 600ms 待機（DraftJS の DOM 更新待ち）
5. スクリーンショットで内容確認

**各ペースト後の必須確認**:
1. スクリーンショットを取得して内容を確認
2. すべての見出しが正しく表示されているか確認
3. 重複が検出された場合は JS でブロックを削除

**コードブロック・仕切りの手動挿入箇所**を検出したらユーザーに通知する:
「[手動挿入フラグ] が X 箇所あります。エディタでコードブロック/仕切りを手動で追加してください。」

## Step 8: 公開の最終確認（AskUserQuestion 必須）

**AskUserQuestion** ツールで以下を確認:

「記事の内容を確認してください。公開してよろしいですか？
- タイトル: [タイトル]
- セクション数: [N] 個
- 手動挿入箇所: [N] 個（未完了の場合は対応後に回答）

「はい」で公開します。「いいえ」でキャンセルします。」

**ユーザーが「はい」と回答した場合のみ**公開ボタンをクリックする。
それ以外の場合はキャンセルして修正を促す。

## フォールバック 3（MCP 全滅時）

両 MCP が利用できない場合:

1. X Articles エディタで手動実行できる JS スニペットを出力する
2. Claude in Chrome MCP のセットアップ手順を案内する:
   - Chrome ウェブストアで「Claude in Chrome」を検索してインストール
   - Claude Code の MCP 設定に追加
   - Claude Code を再起動

詳細は `${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/browser-automation.md` の「MCP 全滅時の手動案内」セクションを参照。
