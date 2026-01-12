---
description: Control CVI voice notification (on/off/show)
---

# CVI State Control

CVI（Claude Voice Integration）の音声通知機能を制御します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/cvi $ARGUMENTS
```

## 引数

- `on` - 音声通知を有効化
- `off` - 音声通知を無効化
- `show` - 現在のステータスを表示
- `help` - ヘルプを表示
- （引数なし） - ヘルプを表示

## 使用例

- `/cvi:state on` - 音声通知を有効化
- `/cvi:state off` - 音声通知を無効化
- `/cvi:state show` - 現在の設定を確認

## 関連コマンド

- `/cvi:speed` - 読み上げ速度を設定
- `/cvi:lang` - 言語を設定（ja/en）
- `/cvi:voice` - 音声を選択
- `/cvi:auto` - 言語自動検出の設定
- `/cvi:check` - セットアップ診断
- `/cvi:practice` - 英語練習モードの設定

実行後、結果を報告してください。
