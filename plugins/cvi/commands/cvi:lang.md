---
description: Configure CVI language (ja/en)
---

# CVI Language Setting

CVI（Claude Voice Integration）の[VOICE]タグ言語を設定します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/cvi-lang $ARGUMENTS
```

## 引数

- （引数なし） - 現在の言語を表示
- `ja` - 日本語に設定
- `en` - 英語に設定
- `reset` - デフォルト（ja）に戻す

## 使用例

- `/cvi:lang` - 現在の言語を確認
- `/cvi:lang ja` - 日本語に設定
- `/cvi:lang en` - 英語に設定

## 注意

この設定は[VOICE]タグのサマリー言語を制御します。
Claudeの応答言語（settings.jsonのlanguage）とは独立した設定です。

実行後、結果を報告してください。
