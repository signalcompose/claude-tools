---
name: gemini-search
description: |
  Web search using Google Antigravity CLI (agy, formerly Gemini CLI).
  Use for: latest information, documentation lookup, current events,
  or when up-to-date web data is needed.
context: fork
agent: Explore
allowed-tools: Bash
---

# Web Search Skill (Antigravity CLI)

## Overview

This skill enables web search using Google Antigravity CLI (`agy`), the
successor to the Gemini CLI. Use it when you need:

- Latest information not in training data
- Current documentation or API references
- Recent news or events
- Up-to-date web data

> Note: Google transitioned Gemini CLI to Antigravity CLI. Gemini CLI stopped
> serving requests on 2026-06-18 for AI Pro/Ultra and free-tier users, so this
> skill now drives the `agy` binary.

## Prerequisites

Antigravity CLI (`agy`) must be installed and signed in. Run the check script first:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-gemini.sh
```

If `agy` is missing, install it and sign in:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
agy   # one-time browser sign-in
```

## Usage

### Basic Web Search

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/gemini-search.sh "<search query>"
```

**IMPORTANT**: `agy` needs write access to its config/cache under
`~/.gemini/antigravity-cli/`, which Claude Code's sandbox blocks. When running
the script via the Bash tool, set `dangerouslyDisableSandbox: true`; otherwise
`agy` exits non-zero with shell command errors even though it is installed and
signed in.

### Examples

```bash
# Search for latest Claude Code features
${CLAUDE_PLUGIN_ROOT}/scripts/gemini-search.sh "Claude Code latest features 2026"

# Look up current API documentation
${CLAUDE_PLUGIN_ROOT}/scripts/gemini-search.sh "OpenAI API rate limits 2026"

# Research recent news
${CLAUDE_PLUGIN_ROOT}/scripts/gemini-search.sh "AI regulation updates January 2026"
```

## Workflow

1. **Check Prerequisites**
   - Verify Antigravity CLI (`agy`) installation
   - Ensure sign-in is complete

2. **Execute Search**
   - Run gemini-search.sh with query
   - Wait for results (120s timeout)

3. **Process Results**
   - Summarize key findings
   - Note relevant sources
   - Highlight latest information

## Error Handling

| Error | Solution |
|-------|----------|
| `agy` not found | Install: `curl -fsSL https://antigravity.google/cli/install.sh \| bash` |
| Not signed in | Run `agy` once to complete browser sign-in |
| Legacy Gemini CLI only | Migrate to `agy` (see install above); optionally `agy plugin import gemini` |
| Timeout | Retry with a more specific query |

## Notes

- Uses the Antigravity CLI default model (web grounding works well with it)
- Override with the `AGY_MODEL` environment variable (run `agy models` for names)
- 120-second timeout to prevent hanging
- The script runs `agy --print "<query>" </dev/null`; the stdin redirect is
  required so `agy` does not block on a missing terminal in non-TTY contexts
  (such as Claude Code's Bash tool)
- Results are returned to the forked context to avoid main context pollution
