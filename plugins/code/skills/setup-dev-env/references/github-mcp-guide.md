# GitHub MCP Setup Guide

How to configure the GitHub MCP server for Claude Code.

## Prerequisites

- GitHub account
- GitHub Personal Access Token (PAT)

## Step 1: Create a Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)" or use Fine-grained tokens
3. Required scopes:
   - `repo` — Full control of private repositories
   - `read:org` — Read org and team membership

4. Copy the generated token (you won't see it again)

## Step 2: Configure `.mcp.json`

Create or edit `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<your-token-here>"
      }
    }
  }
}
```

**Security note**: `.mcp.json` contains secrets. Ensure it is listed in `.gitignore`.

## Step 3: Verify `.gitignore`

Add to `.gitignore` if not already present:

```
.mcp.json
```

## Step 4: Restart Claude Code

After creating `.mcp.json`, restart Claude Code to load the MCP server.

## Step 5: Verify

Run `/setup-dev-env` to confirm GitHub MCP is working (Check 5 should show PASS).

Alternatively, ask Claude Code to run `mcp__github__get_me` — it should return your GitHub user info.

## Troubleshooting

### "Tool not available" Error

- Verify `.mcp.json` is in the project root
- Restart Claude Code
- Check that `npx` is available in your PATH

### "Authentication failed" Error

- Verify your PAT has the required scopes (`repo`, `read:org`)
- Ensure the token hasn't expired
- Regenerate the token if needed

### Sandbox / TLS Errors

The `gh` CLI may hit TLS restrictions in Claude Code's sandbox.
Use GitHub MCP tools (`mcp__github__*`) instead of `gh` CLI for GitHub operations.
This is a known constraint documented in the project's MEMORY.md.
