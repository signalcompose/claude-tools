---
description: Configure CVI speech rate (wpm)
---

# CVI Speed Configuration

CVI（Claude Voice Integration）の読み上げ速度を設定します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
~/.claude/scripts/cvi-speed $ARGUMENTS
```

## 引数

- （引数なし） - 現在の速度を表示
- `[数値]` - 速度を変更（90-350 wpm）
- `reset` - デフォルト（200 wpm）に戻す

## 推奨速度

- **180** - ゆっくり、聞き取りやすい
- **200** - 標準速度（デフォルト）
- **220** - やや速め、効率的

## 使用例

- `/cvi-speed` - 現在の速度を確認
- `/cvi-speed 220` - 速度を220 wpmに設定
- `/cvi-speed reset` - デフォルトに戻す

## 注意事項

- 設定は `~/.cvi/config` に保存されます
- 変更後、次回のタスク完了時から新しい速度が適用されます

実行後、結果を報告してください。
