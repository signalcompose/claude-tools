---
name: gemini-search
description: |
  Web search using Google Gemini CLI.
  Use for: latest information, documentation lookup, current events,
  or when up-to-date web data is needed.
context: fork
agent: Explore
allowed-tools: Bash
---

# Gemini Web Search Skill

## Overview

This skill enables web search using Google Gemini CLI. Use it when you need:

- Latest information not in training data
- Current documentation or API references
- Recent news or events
- Up-to-date web data

## Prerequisites

Gemini CLI must be installed and authenticated. Run the check script first:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-gemini.sh
```

## Usage

### Basic Web Search

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/gemini-search.sh "<search query>"
```

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
   - Verify Gemini CLI installation
   - Ensure authentication is complete

2. **Execute Search**
   - Run gemini-search.sh with query
   - Wait for results (60s timeout)

3. **Process Results**
   - Summarize key findings
   - Note relevant sources
   - Highlight latest information

## Error Handling

| Error | Solution |
|-------|----------|
| Gemini CLI not found | Install via `npm install -g @google/gemini-cli` |
| Authentication failed | Run `gemini` to complete OAuth |
| Timeout | Retry with more specific query |

## Notes

- Uses `gemini-2.5-flash` model for fast responses
- 60-second timeout to prevent hanging
- Results are returned to the forked context to avoid main context pollution
