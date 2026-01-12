---
name: voice-integration
description: |
  This skill should be used when the user asks about "[VOICE] tag", "voice notification",
  "TTS settings", "speech rate", "voice language", "text-to-speech", or mentions CVI configuration.
  Also use this skill when completing tasks to provide voice notification summaries.
version: 1.0.0
---

# Voice Integration Guide

This skill provides guidance on using CVI (Claude Voice Integration) for voice notifications in Claude Code.

## [VOICE] Tag Usage

**Every task completion response MUST end with a [VOICE] tag:**

```
[detailed task explanation...]

[VOICE]Brief summary in 140 chars or less[/VOICE]
```

## Language Configuration

The [VOICE] tag language is controlled by `VOICE_LANG` in `~/.cvi/config`:

| VOICE_LANG | [VOICE] Tag Language |
|------------|---------------------|
| `ja` | Japanese: `[VOICE]タスクが完了しました。[/VOICE]` |
| `en` | English: `[VOICE]Task completed successfully.[/VOICE]` |

**Important**: Always check `~/.cvi/config` before writing [VOICE] tags.

## When to Use [VOICE] Tag

✅ **Always use** when:
- File editing/creation completed
- Test execution completed
- Command execution completed
- Research/investigation completed
- Error resolution completed
- Any task completion

❌ **Exception** (no [VOICE] tag needed):
- When asking user questions/confirmations

## Configuration Commands

| Command | Purpose |
|---------|---------|
| `/cvi` | Enable/disable voice notifications |
| `/cvi:speed` | Adjust speech rate (wpm) |
| `/cvi:lang` | Set [VOICE] tag language (ja/en) |
| `/cvi:voice` | Select voice for each language |
| `/cvi:auto` | Enable language auto-detection |
| `/cvi:check` | Diagnose setup issues |
| `/cvi:practice` | Toggle English practice mode |

## Best Practices

1. **Keep summaries concise**: 140 characters or less
2. **Be informative**: Convey what was accomplished
3. **Match language setting**: Always follow VOICE_LANG
4. **Avoid technical jargon**: Use clear, simple language

## Examples

**English mode (VOICE_LANG=en)**:
```
[VOICE]Updated 3 configuration files. All tests passing.[/VOICE]
```

**Japanese mode (VOICE_LANG=ja)**:
```
[VOICE]設定ファイルを3つ更新しました。テストは全て成功しています。[/VOICE]
```

## Fallback Behavior

If no [VOICE] tag is present, the first 200 characters of the response are automatically read aloud. Using a [VOICE] tag provides better control over what is spoken.
