---
description: Read text aloud using CVI settings
user-invocable: false
---

# CVI Speak

テキストを CVI 設定に従って読み上げます。

## 優先経路: MCP tool

Claude Code に `mcp__cvi-voice__speak` が登録されている場合、**これを Skill tool 経由ではなく**
**ツール呼び出しとして即座に実行してください**。引数:

- `text`: `$ARGUMENTS` の内容
- `voice`: 省略可（CVI config の per-language voice が使われる）
- `rate`: 省略可（CVI config の SPEECH_RATE が使われる）

MCP server は Claude Code の sandbox 外で動作するため、`dangerouslyDisableSandbox: true`
は不要です。permission prompt も発生しません。

## フォールバック: Bash 経路

`mcp__cvi-voice__speak` が未登録、または呼び出しで失敗した場合のみ、以下の Bash コマンドを
**`dangerouslyDisableSandbox: true`** で即座に実行してください:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/post-speak.sh "$ARGUMENTS"
```

この経路は `say` / `afplay` / `osascript` への直接 IPC を必要とするため sandbox bypass が必須です。

## 結果表示

以下の形式でユーザーに表示してください（絵文字不可）:

```
Voice: "読み上げたテキスト"
```

- **MCP 経路**: ツールの返り値は `Speaking: <text>` 形式。`<text>` 部分を上の `"読み上げたテキスト"` に入れて表示する
- **Bash fallback 経路**: `post-speak.sh` の stdout にも `Speaking: <text>` が出力される（script 末尾で echo）ので、MCP 経路と同じ扱い
- **CVI 無効（`CVI_ENABLED=off`）のとき**: MCP 経路は `CVI is disabled. Enable with: /cvi:state on` を文字列として返す。この場合は `Voice: "..."` ではなく、その案内文字列をそのまま表示する
