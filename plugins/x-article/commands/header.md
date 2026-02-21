---
description: "Generate header image for X Articles (1200x480 PNG)"
argument-hint: "--title <title> [--subtitle <subtitle>] [--output <filename.png>]"
---

# X Articles ヘッダー画像生成

以下のBashコマンドを**即座に実行**してください:

**重要**: `dangerouslyDisableSandbox: true` を使用してください（apt-get による Pillow インストールの可能性があるため）。

Bash toolで実行:
- **コマンド**: `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/header-image.py "$ARGUMENTS"`
- **dangerouslyDisableSandbox**: `true`（必須）

## 実行後の確認

画像が生成されたら、ファイルサイズと以下を確認:

- サイズが 1200×480 px になっているか
- テキストが下端 60px 以内にはみ出していないか

## 使用例

```
/x-article:header --title "DraftJS Paste Tips" --subtitle "X Articles エディタで安定ペーストする方法" --output .x-article/header.png
/x-article:header --title "My Article Title"
```

## ヘッダー画像ガイド

詳細なフォント検出・レイアウト設定については:
`${CLAUDE_PLUGIN_ROOT}/skills/x-articles-knowledge/references/header-image.md` を参照。
