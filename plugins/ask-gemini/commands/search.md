---
description: "Web search using Antigravity CLI (agy)"
---

# Web Search via Antigravity CLI (agy)

Execute a web search using Google Antigravity CLI (`agy`), the successor to the
Gemini CLI.

## Step 1: Check Prerequisites

First, verify Antigravity CLI (`agy`) is installed and signed in:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-gemini.sh
```

If the check fails, guide the user through installation:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
agy   # one-time browser sign-in
```

## Step 2: Execute Search

**IMPORTANT**: Antigravity CLI requires write access to configuration and cache directories (under `~/.gemini/antigravity-cli/`) that are blocked by Claude Code's sandbox. You MUST use `dangerouslyDisableSandbox: true` when executing this script. Without this, `agy` will fail with shell command errors.

Run the search with the provided query:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/gemini-search.sh "$ARGUMENTS"
```

When calling the Bash tool, set `dangerouslyDisableSandbox: true` to allow configuration file operations.

## Step 3: Summarize Results

After receiving search results:

1. Extract key findings relevant to the query
2. Note any important sources or URLs
3. Highlight the most current/relevant information
4. Present a clear summary to the user

## Error Handling

- **`agy` not installed**: Provide installation instructions (`curl -fsSL https://antigravity.google/cli/install.sh | bash`)
- **Not signed in**: Guide user to run `agy` once for browser sign-in
- **Legacy Gemini CLI only**: Migrate to `agy`; optionally `agy plugin import gemini`
- **Timeout**: Suggest retrying with a more specific query
