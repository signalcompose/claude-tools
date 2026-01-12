---
description: Configure CVI speech rate (wpm)
---

# CVI Speech Rate Control

CVI（Claude Voice Integration）の読み上げ速度を設定します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/cvi-speed $ARGUMENTS
```

## 引数

- （引数なし） - 現在の速度を表示
- `[数値]` - 速度を指定（wpm: words per minute）
- `reset` - デフォルト速度（200wpm）に戻す

## 推奨速度

- 180 wpm: ゆっくり、聞き取りやすい
- 200 wpm: 標準速度（デフォルト）
- 220 wpm: やや速め、効率的

## 使用例

- `/cvi:speed` - 現在の速度を確認
- `/cvi:speed 220` - 速度を220wpmに設定
- `/cvi:speed reset` - デフォルトに戻す

実行後、結果を報告してください。
