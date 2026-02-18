---
description: Read text aloud using CVI settings
user-invocable: false
---

# CVI Speak

テキストをCVI設定に従って読み上げます。

音声APIへのアクセスが必要なため、以下のBashコマンドを **`dangerouslyDisableSandbox: true`** で即座に実行してください:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak-sync.sh "$ARGUMENTS"
```

上記の結果を確認し、以下の形式でユーザーに表示してください（絵文字不可）:

```
Voice: "読み上げたテキスト"
```
