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

いずれの経路でも、ツールの返り値（`Speaking: <text>`）を以下の形式でユーザーに表示してください（絵文字不可）:

```
Voice: "読み上げたテキスト"
```
