---
name: kiro-research
description: |
  Research AWS topics or troubleshoot errors using Kiro CLI.
  Use for: AWS documentation, error investigation,
  CloudFormation/CDK questions, AWS best practices.
context: fork
agent: Explore
allowed-tools: Bash
---

# Kiro Research Skill

This skill provides integration with Kiro CLI for AWS research and troubleshooting tasks.

## Prerequisites

- Kiro CLI installed (visit https://kiro.dev or download from AWS)
- AWS credentials configured (for AWS-specific operations)

## Available Scripts

All scripts are located in `${CLAUDE_PLUGIN_ROOT}/scripts/`.

### 1. Check Installation

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-kiro.sh
```

Verifies Kiro CLI is installed and accessible.

### 2. Research Mode (kiro-cli chat)

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/kiro-ask.sh "your research question"
```

Use for:
- AWS service documentation lookup
- CloudFormation/CDK troubleshooting
- AWS error investigation
- Best practices inquiry
- Architecture recommendations

Example:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/kiro-ask.sh "How do I configure VPC endpoints for S3?"
```

## Workflow

1. First, verify Kiro CLI is available using `check-kiro.sh`
2. For research tasks, use `kiro-ask.sh` with the research prompt
3. Summarize findings and provide actionable recommendations

## Kiro CLI Options Reference

| Option | Description |
|--------|-------------|
| `--no-interactive` | Run without user input (used by scripts) |
| `--agent <AGENT>` | Specify agent to use |
| `--model <MODEL>` | Specify model to use |
| `--trust-all-tools` | Trust all tools |
| `--trust-tools <TOOLS>` | Trust specific tools only |

## Error Handling

- **Timeout**: Commands timeout after 120 seconds
- **Not installed**: Provides installation instructions
- **Credentials**: Prompts to configure AWS credentials if needed

## Notes

This skill uses `context: fork` to isolate large outputs from the main conversation context.
