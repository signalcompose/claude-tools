# Codex Plugin

OpenAI Codex CLI integration for Claude Code.

## Features

- **Research**: Query technical topics using Codex CLI
- **Code Review**: Analyze code for issues and improvements

## Prerequisites

1. Install Codex CLI:
   ```bash
   npm install -g @openai/codex
   ```

2. Authentication (one of):
   - Run `codex` to complete OAuth authentication, OR
   - Set `OPENAI_API_KEY` environment variable

## Installation

```bash
/plugin install codex@claude-tools
```

## Commands

### `/codex:research`

Research technical topics using Codex CLI.

```bash
/codex:research What is dependency injection
/codex:research How to implement retry logic in TypeScript
```

### `/codex:review`

Review code using Codex CLI.

```bash
/codex:review --staged        # Review staged git changes
/codex:review src/index.ts    # Review specific file
/codex:review ./lib           # Review directory
```

## Configuration

No additional configuration required. The plugin uses:
- OAuth authentication (`~/.codex/auth.json`) or `OPENAI_API_KEY` environment variable
- 120-second timeout for all operations

## Technical Details

### Context Isolation

This plugin uses `context: fork` to isolate large outputs from the main conversation context, preventing context pollution from verbose Codex responses.

## Troubleshooting

### "Codex CLI is not installed"

Install Codex CLI globally:
```bash
npm install -g @openai/codex
```

### "Codex CLI is not authenticated"

Complete one of the following:
```bash
# Option 1: OAuth authentication (recommended)
codex

# Option 2: API key
export OPENAI_API_KEY=your-api-key
```

### Timeout errors

Codex operations timeout after 120 seconds. For large codebases:
- Review smaller directories
- Review specific files instead of entire projects

## License

MIT
