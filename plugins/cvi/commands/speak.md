---
description: Read text aloud using CVI settings
---

# CVI Speak

テキストをCVI設定に従って読み上げます。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh $ARGUMENTS
```

## 引数

- `<text>` - 読み上げるテキスト

## 使用例

- `/cvi:speak Hello World` - 「Hello World」を読み上げ
- `/cvi:speak Task completed successfully` - タスク完了メッセージを読み上げ

## 用途

Stop hookのタイミング問題を回避するため、Claudeが直接音声通知をトリガーする際に使用します。

実行後、結果を報告してください。
