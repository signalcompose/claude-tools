---
name: setup-dev-env
description: |
  Check and configure the development environment for running dev-cycle workflows.
  Verifies Node.js, dependencies, build, Git state, GitHub MCP, pre-commit hooks, and permissions.
  Use when starting a new session or before running /code:dev-cycle, /code:sprint-impl.
  This skill should be used when the user says "setup", "check environment", "dev env",
  "環境チェック", "セットアップ", "開発環境確認".
user-invocable: true
argument-hint: [--fix]
---

# Dev Workflow Setup Check

Verify and configure the development environment for dev-cycle workflows.

## Input

`$ARGUMENTS` may contain:

- `--fix` — Auto-fix fixable items (npm install, npm run build)
- Empty — Check-only mode (report status without modifications)

## Execution Flow

Run all 8 checks in sequence. Collect results, then output a summary table.

### Check 1: Node.js Version

```bash
node --version
```

- **PASS**: Version >= 20.0.0
- **FAIL**: Version < 20.0.0
- **Auto-fix**: No — provide guidance: "Install Node.js >= 20 via nvm or official installer"

Parse the version by stripping the leading `v` and comparing major version number.

### Check 2: Dependencies

Check two conditions:

1. `node_modules/` directory exists
2. `package-lock.json` modification time is newer than or equal to `package.json`

```bash
# Check existence
test -d node_modules && echo "EXISTS" || echo "MISSING"

# Check freshness (macOS stat)
stat -f %m package.json
stat -f %m package-lock.json
```

- **PASS**: Both conditions met
- **WARN**: `node_modules/` exists but `package-lock.json` is stale
- **FAIL**: `node_modules/` missing
- **Auto-fix**: Yes — `npm install --cache /tmp/claude/npm-cache`

### Check 3: Build

Check if a `dist/` directory exists under `$CLAUDE_PROJECT_DIR`:

```bash
test -d "${CLAUDE_PROJECT_DIR}/dist" && echo "EXISTS" || echo "MISSING"
```

- **PASS**: `dist/` directory exists
- **FAIL**: `dist/` missing entirely
- **SKIP**: If no build command is defined in `package.json` (i.e., `scripts.build` is absent), skip this check
- **Auto-fix**: Yes (if build command exists) — `npm run build`

Note: This check is project-agnostic. The specific contents of `dist/` are not verified.

### Check 4: Git State

```bash
git branch --show-current
git remote -v
```

- **PASS**: Not on `main` AND remote `origin` configured
- **WARN**: On `main` branch — "Switch to a feature branch before running /code:dev-cycle"
- **FAIL**: No remote configured
- **Auto-fix**: No — provide guidance only

Display current branch name in the Status column.

### Check 5: GitHub MCP

Attempt to call `mcp__github__get_me` using the ToolSearch tool to discover it, then invoke it.

- **PASS**: Tool responds with user info
- **FAIL**: Tool not available or call fails — provide guidance referencing `${CLAUDE_PLUGIN_ROOT}/skills/setup-dev-env/references/github-mcp-guide.md`
- **Auto-fix**: No — guide user to configure `.mcp.json`

**Important**: Use ToolSearch to discover the tool first. If discovery fails, that itself indicates FAIL.

### Check 6: Code Review Skill

Check that the `code:review-commit` skill is available (the approval flag is now created
inline by the skill — no external script required):

```bash
ls ~/.claude/plugins/cache/claude-tools/code/*/skills/review-commit/SKILL.md 2>/dev/null | head -1
```

- **PASS**: `review-commit/SKILL.md` found in plugin cache
- **WARN**: Skill not found — "Install claude-tools/code plugin for automated code review"
- **Auto-fix**: No — guide user to install the plugin

### Check 7: Permissions

Read `.claude/settings.local.json` and verify it contains the required permission entries.

Reference: Read `${CLAUDE_PLUGIN_ROOT}/skills/setup-dev-env/references/expected-permissions.md` for the full list of required entries.

Check categories:

- **GitHub MCP permissions**: `mcp__github__get_me`, `mcp__github__issue_write`, `mcp__github__create_pull_request`, etc.
- **Git permissions**: `Bash(git add :*)`, `Bash(git push :*)`, etc.
- **Sandbox settings**: `sandbox.enabled` and `sandbox.autoAllowBashIfSandboxed`

- **PASS**: All required entries present
- **WARN**: Some entries missing — list them
- **Auto-fix**: Yes (with `--fix`) — propose adding missing entries to `settings.local.json`

**Important**: When auto-fixing, show the diff to the user before applying. Never silently modify permission files.

### Check 8: .gitignore Security Patterns

Check that `.gitignore` contains the security patterns marker `code:security-patterns`.
This prevents accidental commit of secrets (`.env`, `*.key`, `*.pem`, `credentials*`).

Reference: Read `${CLAUDE_PLUGIN_ROOT}/skills/setup-dev-env/references/gitignore-security-patterns.md` for the full pattern block and rationale.

**Check logic**:

1. Does `.gitignore` exist?
2. Does it contain the marker `code:security-patterns`?

```bash
# Check for marker
grep -q "code:security-patterns" .gitignore 2>/dev/null && echo "PASS" || echo "MISSING"
```

- **PASS**: Marker found in `.gitignore`
- **WARN**: `.gitignore` exists but marker is missing
- **FAIL**: `.gitignore` does not exist at all
- **Auto-fix**: Yes — append the security patterns block from the reference file to `.gitignore` (create file if absent)

**Auto-fix behavior**:
- If `.gitignore` does not exist: create the file with the marker block
- If `.gitignore` exists but marker is missing: append the marker block to the end
- If marker is already present: do nothing (idempotent)

**Important**: A PreToolUse hook (`check-gitignore-security.sh`) blocks `git commit` when the marker is missing. Running `/code:setup-dev-env --fix` resolves this by adding the patterns.

## Output Format

After all checks complete, output a summary table:

```
## Dev Workflow Setup Check

| # | Check | Status | Detail |
|---|-------|--------|--------|
| 1 | Node.js >= 20 | PASS | v22.x.x |
| 2 | Dependencies | PASS | - |
| 3 | Build | WARN | dist/ outdated, rebuilding... |
| 4 | Git branch | PASS | feature/phase-8 |
| 5 | GitHub MCP | FAIL | .mcp.json not found |
| 6 | Code review skill | PASS | code:review-commit available |
| 7 | Permissions | PASS | All entries present |
| 8 | .gitignore Security | PASS | Security patterns present |
```

Status values:

- **PASS** — No action needed
- **WARN** — Non-blocking issue, may affect some workflows
- **FAIL** — Blocking issue, must be resolved before running /code:dev-cycle
- **SKIP** — Check not applicable for this project

### Action Required Section

If any WARN or FAIL items exist, output an "Action Required" section with specific guidance for each issue. Reference the appropriate guide files.

### Auto-fix Summary

If `--fix` was specified and fixes were applied, output a summary of changes made:

```
### Auto-fixes Applied
- Dependencies: Ran `npm install` (success)
- Build: Ran `npm run build` (success)
- Permissions: Added 3 entries to settings.local.json
```

## Output Rules

For shared output language rules, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/output-rules.md`.

All user-facing output MUST follow the user's configured language setting.
SKILL.md being in English does not change this.
