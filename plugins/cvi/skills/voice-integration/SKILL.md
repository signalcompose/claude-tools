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

## MANDATORY: Task Completion Pattern

**Every task completion MUST follow this exact pattern:**

```
[detailed task explanation...]

[VOICE]Brief summary in 2-3 sentences explaining what was done[/VOICE]

<use Skill tool: skill="cvi:speak" args="Brief summary">
```

**CRITICAL: Use Skill tool, NOT text**
- ❌ Do NOT write `/cvi:speak xxx` as text
- ✅ Use Skill tool with `skill="cvi:speak"` and `args="your message"`

**Why both [VOICE] and Skill tool call?**
- `[VOICE]` tag: For display in the response (visible to user)
- Skill tool `/cvi:speak`: Triggers actual voice notification (macOS notification + Glass sound + voice)

**If you forget to use Skill tool:**
- ❌ Stop hook will BLOCK your stop request
- ❌ No voice notification will play
- ❌ User will not hear task completion

## [VOICE] Tag Usage

**Every task completion response MUST end with a [VOICE] tag:**

```
[detailed task explanation...]

[VOICE]Brief summary in 2-3 sentences explaining what was done[/VOICE]
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
| `/cvi:speak` | Directly speak text (bypasses Stop hook timing) |

## Best Practices

1. **Be clear and informative**: 2-3 sentences covering what was done and the outcome
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

## English Practice Mode

When `ENGLISH_PRACTICE=on` in `~/.cvi/config`:

**If user input contains non-ASCII characters (Japanese, etc.):**
1. Show English equivalent: `> "English instruction"`
2. Prompt: `your turn`
3. **Wait for user to repeat in English**
4. **Then execute the instruction**

**Important clarifications:**
- This mode affects USER prompts only, not Claude's response language
- Claude responds in the language set by Claude Code's `language` setting
- If user's English is unclear, ask for clarification before acting
- When user asks "How do you say X in English?", answer the question

## Direct Voice Notification with /cvi:speak

**For immediate voice notification**, use the Skill tool to call `/cvi:speak` after your [VOICE] tag:

```
[detailed task explanation...]

[VOICE]Brief summary[/VOICE]

<use Skill tool: skill="cvi:speak" args="Brief summary">
```

**CRITICAL**: Do NOT write `/cvi:speak` as text. You MUST use the Skill tool.

This approach:
- **Bypasses Stop hook timing issues**: Claude triggers voice directly
- **Keeps [VOICE] tag for display**: The tag remains visible in the response
- **Uses CVI settings**: Language, voice, and speed settings are respected
- **Includes all notifications**: macOS notification, Glass sound, and voice

**Important**: The Stop hook will BLOCK if `/cvi:speak` is not called via Skill tool.

## What /cvi:speak Does

When you call `/cvi:speak <message>`:
1. Displays macOS notification with the message
2. Plays Glass sound (completion indicator)
3. Reads the message aloud using configured voice settings

All three happen together, providing a complete notification experience.

## Fallback Behavior

If no [VOICE] tag is present, the first 200 characters of the response are automatically read aloud. Using a [VOICE] tag provides better control over what is spoken.
