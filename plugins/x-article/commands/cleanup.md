---
description: x-article ワークスペース（.x-article/）の内容をゴミ箱に移動する
argument-hint: ""
---

## Step 1: ワークスペースの確認

`.x-article/` ディレクトリの内容を一覧表示する。

```bash
ls -lh .x-article/ 2>/dev/null || echo ".x-article/ ディレクトリが存在しません"
```

ディレクトリが存在しない、または空の場合は「クリーンアップ対象のファイルはありません」と報告して終了する。

## Step 2: ユーザーへの確認

一覧を表示した後、以下のメッセージでユーザーに確認を求める:

```
以下のファイルをゴミ箱に移動します:
  （ファイル一覧）

よろしいですか？（yes/no）
```

ユーザーが「no」または「キャンセル」と答えた場合は処理を中止する。

## Step 3: ゴミ箱に移動

ユーザーが確認した場合、`trash` コマンドの有無を確認してから実行する。
`trash` が利用できない場合は Finder で開く案内を行い、**Claude 自身は削除を実行しない**。

```bash
if command -v trash &>/dev/null; then
  trash .x-article/
else
  echo "trash コマンドが見つかりません。以下のいずれかを実行してください:"
  echo "  1. brew install trash && trash .x-article/"
  echo "  2. Finder で手動削除: open .x-article/"
fi
```

## Step 4: 完了報告

```
.x-article/ をゴミ箱に移動しました。
次回 /x-article:draft を実行すると自動的に再作成されます。
```
