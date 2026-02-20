# Expected Permissions

Required entries in `.claude/settings.local.json` for dev-cycle workflows.

## Permission Entries

### Git Operations (required)

```json
"Bash(git add :*)",
"Bash(git commit :*)",
"Bash(git status :*)",
"Bash(git diff :*)",
"Bash(git log :*)",
"Bash(git branch :*)",
"Bash(git push :*)",
"Bash(git checkout :*)"
```

### GitHub CLI (required)

```json
"Bash(gh issue :*)",
"Bash(gh pr :*)"
```

### GitHub MCP (required)

```json
"mcp__github__get_me",
"mcp__github__list_issues",
"mcp__github__list_branches",
"mcp__github__list_pull_requests",
"mcp__github__get_file_contents",
"mcp__github__list_commits",
"mcp__github__issue_write",
"mcp__github__issue_read",
"mcp__github__pull_request_read",
"mcp__github__create_pull_request",
"mcp__github__update_pull_request"
```

### Other (optional)

```json
"Skill(codex:codex-research)",
"WebFetch(domain:registry.npmjs.org)"
```

### Ask Permissions

```json
"Bash(git :*)"
```

### Sandbox Settings (required)

```json
"sandbox": {
  "enabled": true,
  "autoAllowBashIfSandboxed": true
}
```

## Checking Logic

1. Read `.claude/settings.local.json`
2. Parse `permissions.allow` array
3. Check that all **required** entries are present
4. Report missing entries as WARN (optional) or FAIL (required)
5. If `--fix`, propose adding missing required entries

## Notes

- These entries are generic and applicable to any project using dev-cycle workflows
- `sandbox` settings are separate from `permissions` — check both sections
