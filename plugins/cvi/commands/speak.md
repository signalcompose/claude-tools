---
description: Read text aloud using CVI settings
user-invocable: false
---

# CVI Speak

テキストをCVI設定に従って読み上げます。

**手順**:

1. CVI が有効か確認（`~/.cvi/config` の `CVI_ENABLED` が `on` であること）
2. 無効の場合: "CVI is disabled. Enable with: /cvi:state on" と表示して終了
3. 有効の場合: Write tool を使用して `~/.cvi/speak-queue` に `$ARGUMENTS` を書き込む
4. 成功したら、以下の形式で表示:

```
Speaking: <メッセージ内容>
```

**注意**: 実際の音声再生は PostToolUse hook で自動的に処理されます。
