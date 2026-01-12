---
description: Diagnose CVI setup status
---

# CVI Setup Diagnosis

CVI（Claude Voice Integration）のセットアップ状態を診断します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/cvi-check $ARGUMENTS
```

## チェック項目

- Siri音声設定
- スクリプト実行権限
- hooks設定
- 読み上げ速度
- 言語設定
- 音声設定

## 使用例

- `/cvi:check` - セットアップ状態を診断

## 問題が見つかった場合

診断結果に従って設定を修正してください。
詳細は `/cvi:setup` でセットアップを再実行できます。

実行後、結果を報告してください。
