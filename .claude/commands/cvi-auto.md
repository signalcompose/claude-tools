---
description: Manage language auto-detection settings
---

# CVI Language Auto-Detection

CVI（Claude Voice Integration）の言語自動検出機能を管理します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
~/.claude/scripts/cvi-auto $ARGUMENTS
```

## 引数

- （引数なし） - 現在の自動検出設定を表示
- `on` - 言語自動検出を有効化
- `off` - 言語自動検出を無効化
- `status` - 詳細ステータスと使用例を表示

## 使用例

- `/cvi-auto` - 現在の設定を確認
- `/cvi-auto on` - 自動検出を有効化
- `/cvi-auto off` - 自動検出を無効化
- `/cvi-auto status` - 詳細情報を表示

## 機能説明

言語自動検出を有効にすると、[VOICE]タグ内のテキストを分析し、日本語/英語を自動判定して適切な音声で読み上げます。

実行後、結果を報告してください。
