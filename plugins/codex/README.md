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

2. Set your OpenAI API key:
   ```bash
   export OPENAI_API_KEY=your-api-key
   ```

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
- `OPENAI_API_KEY` environment variable for authentication
- 120-second timeout for all operations

## Technical Details

### Context Isolation

This plugin uses `context: fork` to isolate large outputs from the main conversation context, preventing context pollution from verbose Codex responses.

### Security

Tool access is restricted to `Bash(codex:*)` pattern, ensuring only Codex-related commands can be executed within the skill context.

## Troubleshooting

### "Codex CLI is not installed"

Install Codex CLI globally:
```bash
npm install -g @openai/codex
```

### "OPENAI_API_KEY not set"

Export your API key:
```bash
export OPENAI_API_KEY=your-api-key
```

### Timeout errors

Codex operations timeout after 120 seconds. For large codebases:
- Review smaller directories
- Review specific files instead of entire projects

## License

MIT
