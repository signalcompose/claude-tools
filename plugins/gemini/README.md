# Gemini Search Plugin

Google Gemini CLI integration for web search in Claude Code.

## Features

- Web search using Gemini CLI
- Forked context to avoid main context pollution
- 60-second timeout for reliability

## Prerequisites

### Install Gemini CLI

```bash
npm install -g @anthropic-ai/gemini
# or
brew install gemini-cli
```

### Authenticate

Run `gemini` once to complete OAuth authentication with your Google account.

## Installation

```bash
/plugin install gemini@claude-tools
```

## Usage

### Command

```
/gemini:search <query>
```

### Skill

The `gemini-search` skill is automatically available for Claude to use when web search is needed.

### Examples

```
/gemini:search Claude Code latest features 2026
/gemini:search OpenAI API rate limits
/gemini:search React 19 new features
```

## How It Works

1. The plugin checks if Gemini CLI is installed and authenticated
2. Executes the search query using `gemini-2.5-flash` model
3. Returns comprehensive web search results
4. Results are processed in a forked context to keep the main conversation clean

## Configuration

No additional configuration required. The plugin uses your existing Gemini CLI authentication.

## Troubleshooting

### Gemini CLI not found

Install Gemini CLI using npm or brew:

```bash
npm install -g @anthropic-ai/gemini
```

### Authentication failed

Run `gemini` in your terminal to complete OAuth authentication.

### Search timeout

The search has a 60-second timeout. Try a more specific query if searches are timing out.

## License

MIT
