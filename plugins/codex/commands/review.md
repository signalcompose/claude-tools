---
description: "Review code using Codex CLI"
---

# Codex Code Review Command

Review code using OpenAI Codex CLI.

## Steps

1. **Check Codex Installation**

Run the installation check script:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-codex.sh
```

If this fails, inform the user to install Codex CLI:
- `npm install -g @openai/codex`
- Set `OPENAI_API_KEY` environment variable

2. **Execute Code Review**

**IMPORTANT**: The codex CLI requires access to macOS system configuration APIs that are blocked by Claude Code's sandbox. You MUST use `dangerouslyDisableSandbox: true` when executing this script. Without this, codex CLI will crash with exit code 101.

Run the review with the provided arguments:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/codex-review.sh "$ARGUMENTS"
```

Supported targets:
- `--staged` - Review all uncommitted changes (staged + unstaged)
- `<file>` - Review specific file
- `<directory>` - Review directory

**Important**: `--staged` uses `codex exec review uncommitted` which reviews **all uncommitted changes**, not just staged files. To review only specific files, use the file/directory target instead.

3. **Present Results**

After execution:
- Categorize issues by severity (critical, warning, suggestion)
- Highlight security concerns first
- Provide specific line references where applicable
- Suggest improvements

## Usage Examples

```
/codex:review --staged
/codex:review src/index.ts
/codex:review ./lib
/codex:review package.json
```

## Notes

- Review timeout is set to 120 seconds
- For staged changes, ensure files are staged with `git add` first
- Large files or directories may take longer to process
