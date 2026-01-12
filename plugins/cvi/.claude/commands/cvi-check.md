---
description: Diagnose CVI setup status
---

# CVI Setup Diagnostic

CVI（Claude Voice Integration）のセットアップ状態を診断します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
~/.claude/scripts/cvi-check
```

## チェック項目

1. **Siri音声** - システムデフォルト音声の設定状態
2. **スクリプト実行権限** - 必要なスクリプトの実行権限
3. **hooks設定** - `~/.claude/settings.json`の設定状態
4. **読み上げ速度** - 現在の速度設定
5. **言語設定** - 現在の言語設定

## 使用例

- `/cvi-check` - セットアップ状態を診断

## 注意事項

- このコマンドは診断のみで、設定を変更しません
- 問題が見つかった場合、表示される指示に従って修正してください

実行後、結果を報告してください。
