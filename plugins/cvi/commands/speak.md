---
description: Read text aloud using CVI settings
user-invocable: false
---

# CVI Speak

テキストをCVI設定に従って読み上げます。

**アーキテクチャ**: Reporter Agent ベース

## 手順

### 1. CVI有効チェック

Read tool で `~/.cvi/config` を読み取り、`CVI_ENABLED` の値を確認：
- `CVI_ENABLED=off` の場合: "CVI is disabled. Enable with: /cvi:state on" と表示して終了
- それ以外（`on` または未設定）: 次のステップへ

### 2. Reporter Agent存在確認

SendMessage tool で Reporter Agent にヘルスチェック:

```
SendMessage:
  type: "message"
  recipient: "cvi-reporter"
  content: "ping"
  summary: "Health check"
```

- **応答あり**: Step 4（通知リクエスト送信）へ
- **応答なし（エラー）**: Step 3（Reporter生成）へ

### 3. Reporter Agent生成（初回のみ）

Task tool で Reporter Agent を生成:

```
Task:
  subagent_type: "general-purpose"
  name: "cvi-reporter"
  allowed_tools: ["Bash", "Read", "SendMessage"]
  description: "CVI voice notification reporter"
  prompt: |
    You are the CVI Reporter Agent for voice notifications.

    ## Your Role
    - Listen for SendMessage requests from the main session
    - Execute voice notifications via speak.sh
    - Report execution results back to the main session

    ## Critical Rules
    1. NEVER call /cvi:speak skill - this causes infinite recursion
    2. ALWAYS execute speak.sh directly:
       bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh "<message>"
    3. ALWAYS send execution results back via SendMessage

    ## Workflow
    1. Wait for SendMessage (type: "message", content: "<message>")
    2. If content is "ping", respond "pong" (health check)
    3. Otherwise, execute: bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh "<message>"
    4. SendMessage back with execution result (success or error)

    ## Example
    Received: "Task completed"
    Execute: bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh "Task completed"
    Respond: "Voice notification delivered: Task completed"
```

**生成失敗時**:
1. Task toolのエラーメッセージを確認
2. 失敗原因を特定（例: リソース不足、権限エラー）
3. 表示: "Failed to create CVI Reporter Agent: <エラー内容>"
4. 提案: "Consider disabling CVI: /cvi:state off"
5. 終了

生成後、Step 4へ。

### 4. 通知リクエスト送信

SendMessage tool で Reporter に音声通知をリクエスト:

```
SendMessage:
  type: "message"
  recipient: "cvi-reporter"
  content: "$ARGUMENTS"
  summary: "Voice notification request"
```

### 5. Reporter返信待機（10秒タイムアウト）

Reporter から返信を待機。以下のいずれかで処理を終了：

1. **返信受信時**: Step 6へ進む
2. **10秒経過時（タイムアウト）**:
   - 表示: "Timeout: CVI Reporter Agent did not respond within 10 seconds"
   - 提案: "Try: /cvi:state off to disable CVI"
   - 終了

### 6. 結果表示

Reporter からの返信内容を表示。通常は以下のメッセージ:

```
Voice notification delivered: <メッセージ内容>
```

## エラーハンドリング

- **Reporter生成失敗**: "Failed to create CVI Reporter Agent" と表示
- **通知送信失敗**: "Failed to send notification request" と表示
- **音声再生失敗**: Reporter からのエラーメッセージを表示

## 注意事項

- Reporter Agent は初回のみ生成され、以降のセッションで再利用されます
- Compacting が発生した場合、Reporter は自動的に再生成されます
- Reporter から 10秒以内に応答がない場合、タイムアウトします
