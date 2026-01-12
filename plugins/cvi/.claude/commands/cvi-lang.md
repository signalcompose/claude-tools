---
description: Configure CVI language (ja/en)
---

# CVI Language Configuration

CVI（Claude Voice Integration）の読み上げ言語を設定します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
~/.claude/scripts/cvi-lang $ARGUMENTS
```

## 引数

- （引数なし） - 現在の言語設定を表示
- `ja` - 日本語に設定
- `en` - 英語に設定
- `reset` - デフォルト（ja）に戻す

## 使用例

- `/cvi-lang` - 現在の言語を確認
- `/cvi-lang ja` - 日本語に設定
- `/cvi-lang en` - 英語に設定
- `/cvi-lang reset` - デフォルトに戻す

## 注意事項

- 設定は `~/.cvi/config` に保存されます
- Siri音声を使用している場合、両言語とも自然な発音で読み上げられます
- [VOICE]タグを使用している場合、タグ内のテキストがそのまま読み上げられます

実行後、結果を報告してください。
