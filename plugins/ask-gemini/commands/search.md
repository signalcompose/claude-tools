---
description: "Web search using Gemini CLI"
---

# Web Search via Gemini CLI

Execute a web search using Google Gemini CLI.

## Step 1: Check Prerequisites

First, verify Gemini CLI is installed and ready:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-gemini.sh
```

If the check fails, guide the user through installation.

## Step 2: Execute Search

**IMPORTANT**: The Gemini CLI requires write access to configuration and cache directories that are blocked by Claude Code's sandbox. You MUST use `dangerouslyDisableSandbox: true` when executing this script. Without this, the Gemini CLI will fail with shell command errors.

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

- **Gemini not installed**: Provide installation instructions
- **Authentication error**: Guide user to run `gemini` for OAuth
- **Timeout**: Suggest retrying with a more specific query
