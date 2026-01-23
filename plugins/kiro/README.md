# Kiro Plugin

AWS Kiro CLI integration for Claude Code.

## Features

- **AWS Research**: Query AWS topics and documentation using Kiro CLI
- **Troubleshooting**: Investigate AWS errors and issues
- **Best Practices**: Get AWS architecture recommendations

## Prerequisites

1. Install Kiro CLI:
   - Visit: https://kiro.dev
   - Or download from AWS

2. Configure AWS credentials (for AWS-specific operations)

## Installation

```bash
/plugin install kiro@claude-tools
```

## Commands

### `/kiro:research`

Research AWS topics using Kiro CLI.

```bash
/kiro:research What is AWS Lambda?
/kiro:research How to troubleshoot CloudFormation stack failures
/kiro:research Best practices for AWS CDK project structure
```

## Kiro CLI Options

| Option | Description |
|--------|-------------|
| `--no-interactive` | Run without user input (used by scripts) |
| `--agent <AGENT>` | Specify agent to use |
| `--model <MODEL>` | Specify model to use |
| `-a, --trust-all-tools` | Allows model to use any tool without confirmation |
| `--trust-tools=<TOOL_NAMES>` | Trust only specific tools (e.g., `--trust-tools=fs_read,fs_write`) |

## Configuration

No additional configuration required. The plugin uses:
- Kiro CLI default configuration
- 120-second timeout for all operations

## Technical Details

### Context Isolation

This plugin uses `context: fork` to isolate large outputs from the main conversation context, preventing context pollution from verbose Kiro responses.

### Output Handling

All output from `kiro-cli` (both stdout and stderr) is merged into stdout for easier capture and display. This means error messages from `kiro-cli` will appear in the normal output stream rather than stderr.

## Troubleshooting

### "Kiro CLI is not installed"

Install Kiro CLI:
- Visit: https://kiro.dev
- Or download from AWS

### Timeout errors

Kiro operations timeout after 120 seconds. For complex queries:
- Break down into smaller questions
- Be more specific with your prompts

### Timeout command not available (macOS)

If you see a warning about missing timeout command:
```bash
# Install coreutils for gtimeout
brew install coreutils
```

### "readonly database" error

If you see `error: attempt to write a readonly database`:

1. **Reinstall shell integrations**:
   ```bash
   kiro-cli integrations install dotfiles
   ```

2. **Remove WAL files** (while kiro is not running):
   ```bash
   rm ~/Library/Application\ Support/kiro/User/globalStorage/kiro.kiroagent/index/index.sqlite-wal
   rm ~/Library/Application\ Support/kiro/User/globalStorage/kiro.kiroagent/index/index.sqlite-shm
   ```

3. **Check directory permissions**:
   ```bash
   chmod u+w ~/.kiro
   chmod -R u+w ~/Library/Application\ Support/kiro
   ```

## License

MIT
