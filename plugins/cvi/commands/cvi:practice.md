---
description: Toggle English practice mode on/off
---

# CVI English Practice Mode

CVI（Claude Voice Integration）の英語練習モードを設定します。

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/cvi-practice $ARGUMENTS
```

## 引数

- （引数なし） - 現在の状態を表示
- `on` - 英語練習モードを有効化
- `off` - 英語練習モードを無効化
- `status` - 現在の状態を表示

## English Practice Modeの動作

**有効時 (on)**:
1. ユーザーが日本語で指示
2. Claudeが英語での表現を提示:
   ```
   > "English instruction here"

   your turn
   ```
3. ユーザーが英語でリピート
4. Claudeが実行

**無効時 (off)** (デフォルト):
- 言語に関係なく直接実行

## 使用例

- `/cvi:practice` - 現在の状態を確認
- `/cvi:practice on` - 有効化
- `/cvi:practice off` - 無効化

## 注意事項

- 設定は `~/.cvi/config` の `ENGLISH_PRACTICE` に保存されます
- 英語練習用の機能であり、通常の作業効率を優先する場合はオフにしてください

実行後、結果を報告してください。
