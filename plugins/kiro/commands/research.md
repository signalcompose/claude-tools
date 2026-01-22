---
description: "Research AWS topics using Kiro CLI"
---

# Kiro Research Command

Research AWS topics and troubleshoot errors using Kiro CLI.

## Steps

1. **Check Kiro CLI Installation**

Run the installation check script:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/check-kiro.sh
```

If this fails, inform the user to install Kiro CLI:
- Visit: https://kiro.dev
- Or download from AWS

2. **Execute Research Query**

Run the research with the provided arguments:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/kiro-ask.sh "$ARGUMENTS"
```

3. **Summarize Results**

After execution:
- Summarize the key findings
- Highlight actionable insights
- Note any limitations or caveats

## Usage Examples

```
/kiro:research What is AWS Lambda?
/kiro:research How to troubleshoot CloudFormation stack failures
/kiro:research Best practices for AWS CDK project structure
/kiro:research Explain AWS VPC peering configuration
```

## Notes

- Research queries are executed via `kiro-cli chat --no-interactive`
- Timeout is set to 120 seconds
- Kiro CLI is optimized for AWS-related topics
