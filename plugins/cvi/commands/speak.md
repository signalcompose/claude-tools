---
description: Read text aloud using CVI settings
user-invocable: false
---

# CVI Speak

テキストを CVI 設定に従って読み上げます。

## 実行経路: MCP tool（唯一の経路）

`mcp__cvi-voice__speak` を **Skill tool 経由ではなくツール呼び出しとして即座に実行してください**。引数:

- `text`: `$ARGUMENTS` の内容
- `voice`: 省略可（CVI config の per-language voice が使われる）
- `rate`: 省略可（CVI config の SPEECH_RATE が使われる）

MCP server は Claude Code の sandbox 外で動作するため、`dangerouslyDisableSandbox: true`
は不要です。permission prompt も発生しません。

`mcp__cvi-voice__speak` が未登録、または呼び出しが失敗した場合は、MCP server の状態を
`/cvi:check` で診断してください。Bash fallback は存在しません（MCP 一本化、#242）。

## 結果表示

以下の形式でユーザーに表示してください（絵文字不可）:

```
Voice: "読み上げたテキスト"
```

- ツールの返り値は `Speaking: <text>` 形式。`<text>` 部分を上の `"読み上げたテキスト"` に入れて表示する
- **CVI 無効（`CVI_ENABLED=off`）のとき**: MCP 経路は `CVI is disabled. Enable with: /cvi:state on` を文字列として返す。この場合は `Voice: "..."` ではなく、その案内文字列をそのまま表示する
