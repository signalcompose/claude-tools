---
description: Read text aloud using CVI settings
user-invocable: false
---

# CVI Speak

テキストをCVI設定に従って読み上げます。

**アーキテクチャ**: PostToolUse Hook Direct Execution

## 仕組み

1. Main Sessionがメッセージを`~/.cvi/speak-current`に書き込み
2. "Speaking: <message>" を即座に表示
3. PostToolUse hookが`speak-current.sh`を実行（sandbox外）
4. 音声再生（osascript + afplay + say）
5. `speak-current`ファイルを削除（処理済み）

## 手順

### 1. CVI有効チェック

Read tool で `~/.cvi/config` を読み取り、`CVI_ENABLED` の値を確認：
- `CVI_ENABLED=off` の場合: "CVI is disabled. Enable with: /cvi:state on" と表示して終了
- それ以外（`on` または未設定）: 次のステップへ

### 2. メッセージを書き込み

Write tool で `~/.cvi/speak-current` にメッセージを書き込む：

```
Write:
  file_path: ~/.cvi/speak-current
  content: "$ARGUMENTS"
```

**重要**: `$ARGUMENTS`は引数として渡されたメッセージ全体。

### 3. 即座に表示

以下のメッセージを表示して終了：

```
Speaking: <メッセージ内容>
```

**注意**:
- PostToolUse hookが自動的に音声を再生するため、ここで待機する必要はない
- リアルタイムで音声が再生される（キューファイルなし）

## エラーハンドリング

- **Write失敗**: "Failed to write message to ~/.cvi/speak-current" と表示
- **音声再生失敗**: PostToolUse hookのログを確認（通常は表示されない）

## 注意事項

- `speak-current`ファイルは音声再生後に自動削除される
- 複数プロジェクトで同時に`/cvi:speak`を呼ぶと、片方のメッセージが失われる可能性がある（将来の改善予定）
- PostToolUse hookはsandbox外で実行されるため、osascript/afplay/sayが正常に動作する
