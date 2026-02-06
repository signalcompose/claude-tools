# .claude/settings.json Template

## Official Reference

- [Claude Code Settings - Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/settings)

## Design Philosophy

- **Single Template + Addon approach**: One base template for team development, with optional addons
- `allow`: **Safe defaults** — read-only operations + side-effect-free tools
- `ask`: File writes, Git operations, build tools, network operations (require confirmation)
- `deny`: Sensitive files, destructive operations, irreversible commands
- **Tech-Stack tools**: Selected based on Phase 1 project planning, added to `ask`
- **Ralph Loop addon**: Scoped `allow` rules for autonomous operation

## Base Template

```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "Glob(*)",
      "Grep(*)",
      "WebSearch(*)",
      "TodoWrite(*)"
    ],
    "ask": [
      "Write(*)",
      "Edit(*)",
      "WebFetch(*)",
      "NotebookEdit(*)",
      "Bash(git :*)",
      "Bash(gh :*)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./**/credentials.json)",
      "Read(./**/*.pem)",
      "Read(./**/*.key)",
      "Bash(rm -rf :*)",
      "Bash(rm -r :*)",
      "Bash(git push --force :*)",
      "Bash(git push -f :*)",
      "Bash(git reset --hard :*)",
      "Bash(git clean -f :*)",
      "Bash(git clean -fd :*)",
      "Bash(git checkout . :*)",
      "Bash(git restore . :*)",
      "Bash(git branch -D :*)",
      "Bash(gh repo delete :*)",
      "Bash(gh repo archive :*)",
      "Bash(gh secret :*)",
      "Bash(sudo :*)",
      "Bash(chmod 777 :*)",
      "Bash(chmod -R 777 :*)"
    ]
  },
  "cleanupPeriodDays": 30
}
```

**Note**: Tech-stack tools are added to `ask` based on the technology selected in Phase 1. See [Tech-Stack Blocks](#tech-stack-blocks-phase-1-selection) below.

## Tool Reference

### Always Included

| Category | Permission | Tools | Rationale |
|----------|-----------|-------|-----------|
| Read-only | `allow` | `Read(*)`, `Glob(*)`, `Grep(*)` | File reading has no side effects |
| Search | `allow` | `WebSearch(*)` | Read-only web search, no side effects |
| Task management | `allow` | `TodoWrite(*)` | Session-scoped task tracking only |
| File write | `ask` | `Write(*)`, `Edit(*)` | Modifies project files |
| Notebook | `ask` | `NotebookEdit(*)` | Modifies Jupyter notebooks |
| Network | `ask` | `WebFetch(*)` | Fetches external URLs |
| Git | `ask` | `Bash(git :*)` | Repository operations |
| GitHub CLI | `ask` | `Bash(gh :*)` | GitHub API operations |

### Tech-Stack Blocks (Phase 1 Selection)

Add the relevant blocks to `ask` based on the project's technology stack detected in Phase 1:

| Stack | Tools to add to `ask` |
|-------|----------------------|
| **Node.js** | `Bash(npm :*)`, `Bash(npx :*)`, `Bash(pnpm :*)`, `Bash(yarn :*)`, `Bash(bun :*)`, `Bash(node :*)` |
| **Python** | `Bash(python :*)`, `Bash(python3 :*)`, `Bash(pip :*)`, `Bash(pip3 :*)`, `Bash(uv :*)`, `Bash(poetry :*)` |
| **Rust** | `Bash(cargo :*)` |
| **Go** | `Bash(go :*)` |
| **Docker** | `Bash(docker :*)`, `Bash(docker-compose :*)` |
| **Ruby** | `Bash(bundle :*)`, `Bash(gem :*)` |
| **Java/Kotlin** | `Bash(gradle :*)`, `Bash(mvn :*)` |
| **Network** | `Bash(curl :*)`, `Bash(wget :*)` |

**Example**: A Node.js + Docker project would add to `ask`:
```json
"Bash(npm :*)",
"Bash(npx :*)",
"Bash(node :*)",
"Bash(docker :*)",
"Bash(docker-compose :*)"
```

## Ralph Loop / Autonomous Operation Addon

For Ralph Loop or other autonomous workflows, move scoped write/git operations from `ask` to `allow`:

```json
"allow": [
  "Write(./src/**)",
  "Write(./tests/**)",
  "Write(./docs/**)",
  "Edit(./src/**)",
  "Edit(./tests/**)",
  "Edit(./docs/**)",
  "Bash(git add :*)",
  "Bash(git commit :*)",
  "Bash(git diff :*)",
  "Bash(git status :*)",
  "Bash(git log :*)"
]
```

**Must remain in `ask` (even with Ralph Loop)**:
- `Bash(git push :*)` — affects remote repository
- `Bash(gh pr create :*)` — affects remote repository
- Unscoped `Write(*)` / `Edit(*)` — scope is too broad

**Important**: Directory paths (`./src/**`, `./tests/**`, `./docs/**`) must be adjusted to match the project's actual directory structure.

## MCP / Plugin Tools

MCP server tools and plugin skills can also be managed via permissions:

```
# MCP tool permission example
mcp__servername__toolname

# Skill permission example
Skill(plugin:skillname)
```

Add these to `allow` or `ask` as appropriate for the project's MCP configuration.

## Customization Notes

- Adjust tech-stack entries based on the project's actual toolchain
- Add project-specific tool commands to `ask` as needed
- Add additional sensitive file patterns to `deny` as needed
- Users can override with `.claude/settings.local.json` (not committed to git)
- Consider adding scoped `Write`/`Edit` rules for frequently modified directories

## Security Notes

### Deny Pattern Limitations

- Permission patterns use glob-style matching; they cannot match all flag combinations
  - Example: `rm -rf` and `rm -r -f` are different patterns
- Deny rules are a safety net, not a complete security boundary
- Combine with `.gitignore`, pre-commit hooks, and code review for defense in depth
- The `deny` list focuses on the most common destructive patterns
