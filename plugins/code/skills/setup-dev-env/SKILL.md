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

Run all 13 checks in sequence. Collect results, then output a summary table.

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

Check that `.gitignore` contains the security patterns marker `code:security-patterns` with an up-to-date content hash.
This prevents accidental commit of secrets (`.env`, `*.key`, `*.pem`, `credentials*`).

Reference: Read `${CLAUDE_PLUGIN_ROOT}/skills/setup-dev-env/references/gitignore-security-patterns.md` for the full pattern block, content hash, and rationale.

**Check logic**:

1. Does `.gitignore` exist?
2. Does it contain the marker `code:security-patterns`?
3. Does the hash in the marker match the hash in the reference file?

```bash
# Check for marker presence
grep -q "code:security-patterns" .gitignore 2>/dev/null && echo "PRESENT" || echo "MISSING"

# Extract hash from .gitignore marker (if present)
grep -o 'code:security-patterns:[a-f0-9]*' .gitignore 2>/dev/null | head -1 | cut -d: -f3
```

- **PASS**: Marker found with matching hash
- **WARN (outdated)**: Marker found but hash differs from reference — patterns need updating
- **WARN (missing)**: `.gitignore` exists but marker is missing
- **FAIL**: `.gitignore` does not exist at all
- **Auto-fix**: Yes — append or replace the security patterns block from the reference file

**Auto-fix behavior**:
- If `.gitignore` does not exist: create the file with the marker block
- If `.gitignore` exists but marker is missing: append the marker block to the end
- If marker exists but hash is outdated: replace the entire marker block (from `# [code:security-patterns` to `# [/code:security-patterns]`) with the latest version
- If marker with matching hash is already present: do nothing (idempotent)

**Important**: A PreToolUse hook (`check-gitignore-security.sh`) blocks `git commit` when the marker is missing. Running `/code:setup-dev-env --fix` resolves this by adding the patterns.

### Check 9: Auto Mode Heuristic

Determine whether Claude Code is (or can be) running in auto mode for `/code:autopilot`.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-detect-auto-mode.sh
```

Exit code semantics:
- `0` — auto mode detected. Source printed to stdout (`opt-in-flag` / `project` / `local` / `user`).
- `1` — disabled by a managed setting (`disableAutoMode == "disable"`).
- `2` — not detected in any of the three layers.

Status mapping:

- **PASS**: detected (code 0)
- **WARN (not detected)**: code 2 — `/code:autopilot` will refuse. Guidance: set `permissions.defaultMode: "auto"` in a settings layer, or touch `.claude/autopilot.auto-mode-confirmed` for a single-project opt-in.
- **FAIL (disabled)**: code 1 — `/code:autopilot` cannot run. Guidance: managed setting disallows auto mode; escalate per organization policy.
- **Auto-fix**: No — changing permission mode affects safety posture. Guidance only.

### Check 10: settings.local.json Triage

Inspect `.claude/settings.local.json` (gitignored, personal) for bloat and stale patterns. Reference: `docs/settings-triage-guide.md`.

**Checks**:
1. `allow` count < 50 (warn if >= 50)
2. No project-absolute paths (e.g., `/Users/.../plugins/*/scripts/*.sh:*` — should use `${CLAUDE_PLUGIN_ROOT}`)
3. No stale plugin cache paths (`~/.claude/plugins/cache/*/<commit-hash>/` where the commit is not current)
4. No shell keywords in allow (`do`, `done`, `fi`, `then`, `else`)
5. No one-shot HEREDOC commit commands in allow

```bash
# Quick sanity: count allow entries
jq '.permissions.allow | length' .claude/settings.local.json 2>/dev/null
```

- **PASS**: All checks pass
- **WARN**: Any bloat/staleness detected — list specific entries; propose removal via diff
- **SKIP**: File does not exist
- **Auto-fix**: Yes (with `--fix`) — present diff, apply after user approval. **Preserve personal-dependent entries** (browser sessions, 1Password CLI, personal MCP server allows) — never remove these even if flagged.

### Check 11: settings.json (Project) Triage

Inspect `.claude/settings.json` (committed, team-shared) for promotion candidates and CLAUDE.md alignment.

**Checks**:
1. Promotion candidates: entries in `settings.local.json` that are generic enough to share with teammates (git write operations, common `gh pr create`, common WebFetch domains, etc.)
2. CLAUDE.md alignment:
   - Force-push deny patterns present (`Bash(git push --force :*)`, `Bash(git push -f :*)`)
   - `Bash(gh pr merge :*)` in `ask` (not `allow`) per CLAUDE.md merge rule
   - `Bash(gh pr merge --squash :*)` in `deny` if project rejects squash merge (check project CLAUDE.md)
3. `Read(./.env)` / `Read(./.env.*)` in `deny`

- **PASS**: Promotion pool is empty (or small) AND CLAUDE.md alignment OK
- **WARN**: Promotion candidates found OR missing expected deny/ask entries — list with diff proposal
- **SKIP**: File does not exist AND `settings.local.json` is also empty
- **Auto-fix**: Yes (with `--fix`) — diff proposal, apply after user approval

### Check 12: Plugin-Bundled Settings Inspection (Read-only)

Inspect `plugins/*/.claude/settings.json` across all installed plugins. **Read-only — never edit these files** (they are managed by each plugin's own repository).

```bash
find plugins -type f -path '*/.claude/settings.json' -print
```

For each plugin, report:
- Exists? (yes/no)
- Minimum deny list present? (force-push, sudo, chmod 777, Read(./.env))
- Any suspicious broad allow (`Bash(*)`, `Bash(python *)`, `Bash(npm run *)`) — these are auto mode hazards

- **PASS**: All inspected plugins have a minimum deny list and no broad allows
- **WARN**: A plugin is missing recommended deny entries or has broad allow — report to user; propose upstream fix (PR to that plugin's repository)
- **SKIP**: No `plugins/` directory OR no plugin-bundled settings found
- **Auto-fix**: No — plugin-bundled settings are canonical in the upstream repository

### Check 13: CLAUDE.md Integrity

Verify that `./CLAUDE.md` (project-level) covers the required sections. `~/.claude/CLAUDE.md` (global) is read-only reference — never propose edits.

Required sections (for projects in this marketplace):
- Git workflow absolute prohibitions (main direct commit, force push, etc.)
- Conventional Commits convention (commit title format, Co-Authored-By)
- Humility principle (no superlatives, accurate reporting)
- (For plugin projects) Plugin development conventions

```bash
# Very lightweight existence check (headings or keyword presence)
grep -qE '(Git workflow|git 規約|禁止事項)'  CLAUDE.md && echo "git-rules: present" || echo "git-rules: missing"
grep -qE '(Conventional Commits|コミット規約)' CLAUDE.md && echo "commit-rules: present" || echo "commit-rules: missing"
grep -qE '(Humility|humility|謙虚|superlative)' CLAUDE.md && echo "humility: present" || echo "humility: missing"
```

- **PASS**: All required sections present
- **WARN (missing)**: Specific sections missing — diff proposal with canonical text from `${CLAUDE_PLUGIN_ROOT}/skills/setup-dev-env/references/claude-md-template.md`
- **SKIP**: `./CLAUDE.md` does not exist — guidance: "Consider adding a project CLAUDE.md to capture project-specific conventions"
- **Auto-fix**: Yes (with `--fix`) — diff proposal, apply after user approval. **Never auto-append without user approval** — CLAUDE.md content is project-specific and context-dependent.

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
| 9 | Auto mode | PASS | detected via user settings |
| 10 | settings.local triage | WARN | 135 allow entries (bloat) |
| 11 | settings.json triage | PASS | aligned with CLAUDE.md |
| 12 | Plugin-bundled settings | PASS | all 8 plugins OK (read-only) |
| 13 | CLAUDE.md integrity | PASS | all required sections present |
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
