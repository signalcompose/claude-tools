---
description: "Research topics using Codex CLI"
---

# Codex Research Command

Research technical topics using OpenAI Codex CLI.

## Steps

1. **Check Codex Installation**

Run the installation check script:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-codex.sh
```

If this fails, inform the user to install Codex CLI:
- `npm install -g @openai/codex`
- Set `OPENAI_API_KEY` environment variable

2. **Execute Research Query**

**IMPORTANT**: The codex CLI requires access to macOS system configuration APIs that are blocked by Claude Code's sandbox. You MUST use `dangerouslyDisableSandbox: true` when executing this script. Without this, codex CLI will crash with exit code 101.

Run the research with the provided arguments:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/codex-exec.sh "$ARGUMENTS"
```

3. **Summarize Results**

After execution:
- Summarize the key findings
- Highlight actionable insights
- Note any limitations or caveats

## Usage Examples

```
/codex:research What is dependency injection
/codex:research How to implement retry logic in TypeScript
/codex:research Best practices for error handling in Node.js
```

## Notes

- Research queries are executed via `codex exec`
- Timeout is set to 120 seconds
- Results may vary based on Codex model capabilities
