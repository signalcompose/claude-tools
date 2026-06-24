# ask-gemini — Web Search Plugin

Google Antigravity CLI (`agy`) integration for web search in Claude Code.

> **Migration note:** Google transitioned the Gemini CLI to the **Antigravity CLI**
> (binary: `agy`). Gemini CLI stopped serving requests on **2026-06-18** for
> Google AI Pro/Ultra and free-tier users. This plugin now drives `agy`.
> The command name `/ask-gemini:search` is unchanged.

## Features

- Web search using Antigravity CLI (`agy`)
- Forked context to avoid main context pollution
- 120-second timeout for reliability

## Prerequisites

### Install Antigravity CLI

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

The installer places the `agy` binary in `~/.local/bin` and adds it to your PATH.

### Sign in

Run `agy` once to complete browser-based OAuth sign-in with your Google account.

```bash
agy
```

### (Optional) Import old Gemini settings

If you used the legacy Gemini CLI, you can import its configuration:

```bash
agy plugin import gemini
```

## Installation

```bash
/plugin install ask-gemini@claude-tools
```

## Usage

### Command

```
/ask-gemini:search <query>
```

### Skill

The `gemini-search` skill is automatically available for Claude to use when web search is needed.

### Examples

```
/ask-gemini:search Claude Code latest features 2026
/ask-gemini:search OpenAI API rate limits
/ask-gemini:search React 19 new features
```

## How It Works

1. The plugin checks if Antigravity CLI (`agy`) is installed and signed in
2. Wraps the query in a web-search prompt and runs `agy --print "<prompt>" </dev/null`
3. Returns comprehensive web search results
4. Results are processed in a forked context to keep the main conversation clean

> The `</dev/null` redirect is required: the prompt is passed as the `--print`
> argument, but `agy --print` still reads stdin and would otherwise block forever
> in a non-TTY context (such as Claude Code's Bash tool) waiting for EOF.

## Configuration

### Default Model

The plugin uses the Antigravity CLI default model, which provides grounded web
search out of the box. No model flag is passed by default.

### Custom Model

Override the model with the `AGY_MODEL` environment variable:

```bash
export AGY_MODEL="Gemini 3.5 Flash (Low)"
```

Run `agy models` to list the available model names for your account.

## Troubleshooting

### `agy` not found

Install Antigravity CLI:

```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

### Not signed in

Run `agy` in your terminal to complete browser sign-in.

### Search timeout

The search has a 120-second timeout. Try a more specific query if searches are timing out.

## License

MIT
