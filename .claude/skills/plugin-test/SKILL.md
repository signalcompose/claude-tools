---
name: plugin-test
description: Interactive plugin testing with automated validation and manual test guidance
user-invocable: true
---

# Plugin Test Skill

Test a plugin interactively with automated validation and step-by-step manual testing.

## Usage

```
/plugin-test <plugin-name-or-path>
```

**Examples**:
- `/plugin-test code` - Simple name (backward compatible)
- `/plugin-test plugins/utils` - Relative path
- `/plugin-test ../other-plugin` - Parent directory
- `/plugin-test /abs/path/to/plugin` - Absolute path
- `/plugin-test .` - Current directory

## Testing Development Branches Without Merge

**Problem**: Testing feature branch plugins without merging to main (avoids affecting auto-update users).

**Solution A: Docker Sandboxes (Recommended)**
- microVM isolation with `docker sandbox run claude .`
- Complete separation from production environment
- See: `docs/testing/docker-sandboxes-guide.md`

**Solution B: --plugin-dir (Lightweight)**
- Session isolation with `claude --plugin-dir plugins/xxx`
- Simpler but less isolated than Docker

## Instructions for Claude

When user invokes `/plugin-test <plugin-name-or-path>`:

### Step 0: Resolve Plugin Path

Before loading plugin information, resolve the plugin directory path from user input.

**Input parameter**: `<plugin-name-or-path>` (can be simple name, relative path, absolute path, or `.`)

**Resolution algorithm**:

1. **Try backward-compatible path first** (for simple plugin names):
   ```bash
   # Check if plugins/<input>/.claude-plugin/plugin.json exists
   test -f "plugins/<input>/.claude-plugin/plugin.json"
   ```
   - If exists: `PLUGIN_ROOT="plugins/<input>"`
   - If not: Continue to step 2

2. **Try direct path** (for relative/absolute paths):
   ```bash
   # Check if <input>/.claude-plugin/plugin.json exists
   test -f "<input>/.claude-plugin/plugin.json"
   ```
   - If exists: `PLUGIN_ROOT="<input>"`
   - If not: Continue to step 3

3. **Error - plugin not found**:
   ```
   ✗ Error: Plugin not found

   Searched:
   - plugins/<input>/.claude-plugin/plugin.json (NOT FOUND)
   - <input>/.claude-plugin/plugin.json (NOT FOUND)

   Valid examples:
   - /plugin-test code                    (simple name)
   - /plugin-test plugins/utils           (relative path)
   - /plugin-test ../other-plugin         (parent directory)
   - /plugin-test /abs/path/to/plugin     (absolute path)
   - /plugin-test .                       (current directory)
   ```
   Stop execution - ask user to verify path.

4. **Extract plugin name from plugin.json**:
   ```bash
   PLUGIN_NAME=$(jq -r '.name' "<PLUGIN_ROOT>/.claude-plugin/plugin.json")
   ```

5. **Display resolution result**:
   ```
   === Resolved Plugin Path ===

   Plugin path: <PLUGIN_ROOT>
   Plugin name: <PLUGIN_NAME>
   ```

**Important notes**:
- Backward compatibility: `plugins/<input>/` is always tried first
- Path resolution is case-sensitive
- Symlinks are supported (resolved to real path)
- All subsequent steps use `<PLUGIN_ROOT>` as the base directory

### Step 1: Load Plugin Information

Read the following files from `<PLUGIN_ROOT>/`:

1. **Core files** (read in parallel):
   - `.claude-plugin/plugin.json` - Plugin metadata
   - `hooks/hooks.json` (if exists) - Hook configuration
   - `README.md` - Plugin description

2. **Discover resources**:
   - List all `.sh` scripts in `scripts/` directory
   - List all `SKILL.md` files in `skills/` directory
   - List all `.md` files in `commands/` directory

Display plugin summary:
```
=== Plugin: <name> ===

Description: <from plugin.json>
Version: <hash-based from claude-tools>

Resources:
✓ Scripts: X files
✓ Skills: Y files
✓ Commands: Z files
✓ Hooks: N types configured
```

### Step 2: Run Automated Validation

Execute these checks **sequentially** (run all checks regardless of failures):

#### Check 1: Script Syntax

For each `.sh` script in `scripts/`:
```bash
bash -n <PLUGIN_ROOT>/scripts/<script-name>.sh
```

**Report format**:
- `✓ <script-name>` if exit code 0
- `✗ <script-name>: <error>` if exit code != 0

#### Check 2: Executable Permissions

For each `.sh` script:
```bash
test -x <PLUGIN_ROOT>/scripts/<script-name>.sh
```

**Report format**:
- `✓ <script-name>: executable` if test passes
- `⚠ <script-name>: not executable (run chmod +x)` if test fails

#### Check 3: Hook Configuration

If `hooks/hooks.json` exists:

1. **Validate JSON syntax**:
```bash
jq empty <PLUGIN_ROOT>/hooks/hooks.json
```

2. **For each hook**, extract and verify:
   - Hook type is valid (PreToolUse, PostToolUse, UserPromptSubmit, Stop, SessionStart, Notification)
   - Referenced script exists
   - Script has execute permission

**Report format**:
```
✓ PreToolUse: check-code-review.sh (exists, executable)
✗ PostToolUse: missing-script.sh (not found)
```

#### Check 4: File Structure

Verify required files:
- `✓ plugin.json` (must exist)
- `✓ README.md` (must exist)
- `✓ At least one of: commands/, skills/, hooks/`

#### Check 5: Sandbox Compatibility

Scan all `.sh` scripts for common issues:

**Good patterns** (no warning):
- `${CLAUDE_PLUGIN_ROOT}`
- `/tmp/claude/`
- `TMPDIR=${TMPDIR:-/tmp/claude}`

**Bad patterns** (warn):
- `~/.claude/` (except in documentation/setup comments)
- `/tmp/` without `/tmp/claude/` (should use TMPDIR)

**Detection method**:
```bash
# Check for bad patterns
grep -n '~/.claude' <PLUGIN_ROOT>/scripts/*.sh | grep -v CLAUDE_PLUGIN_ROOT | grep -v '^[[:space:]]*#'
grep -n '/tmp/' <PLUGIN_ROOT>/scripts/*.sh | grep -v '/tmp/claude' | grep -v '^[[:space:]]*#'
```

**Report format**:
```
✓ Sandbox compatible
⚠ Found hardcoded paths in:
  - script.sh:15: ~/.claude/config
  - script.sh:23: /tmp/file
```

#### Summary Display

After all checks:
```
=== Phase 1: Automated Validation ===

[1/5] Script Syntax: PASS (3/3 scripts)
[2/5] Executable Permissions: PASS (3/3 scripts)
[3/5] Hook Configuration: PASS (3 hooks verified)
[4/5] File Structure: PASS
[5/5] Sandbox Compatibility: PASS

✓ Phase 1: ALL CHECKS PASSED (5/5)
```

If any check fails:
```
✗ Phase 1: FAILED (3/5 passed)

Issues:
- Script syntax error in check-code-review.sh:42
- Missing script: missing-script.sh
```

### Step 3: Manual Test Guidance

Based on plugin type (detected from hooks and skills):

#### 3.1 Detect Plugin Type

**Hook-based plugin** if:
- Has PreToolUse or PostToolUse hooks
- Examples: code, cvi

**Voice/Audio plugin** if:
- Has "voice", "speak", "audio" in plugin name or description
- Examples: cvi

**Team/Agent plugin** if:
- Has skills that reference "team", "agent", "spawn"
- Examples: code (review-commit)

**Utility plugin** if:
- Has commands or skills
- No special hooks
- Examples: utils, ypm

#### 3.2 Guide Manual Tests

For each detected plugin type, guide user through relevant tests.

**General test flow**:
1. Display test name and purpose
2. Show setup commands (if needed)
3. Ask: `Ready to proceed? (yes/skip/abort)`
4. Show execution steps
5. Ask: `Did it work as expected? (yes/no/error)`
6. Record result

**See `references/test-patterns.md` for detailed test patterns by plugin type.**

**Example interaction**:

    === Phase 2: Manual Testing ===

    Test 2.1: Hook Blocking Behavior
    ────────────────────────────────

    Purpose: Verify PreToolUse hook blocks git commit without approval

    Setup:
    Please run these commands:

        echo "// Test" >> README.md
        git add README.md

    Ready to proceed? (yes/skip/abort)

After user confirms:
```
Execute:
Please run: git commit -m "test: should block"

Expected: Commit should be blocked with error message

Did it work as expected? (yes/no/error)
```

Record result and continue to next test.

### Step 4: Generate Test Summary

After all tests complete, display:

```
=== Test Summary ===

Automated Checks: 5/5 PASSED
Manual Tests: 3/3 PASSED

Overall: ✓ ALL TESTS PASSED

Issues Found:
[None]

Next Steps:
- Record results in docs/testing/e2e-test-results-{date}.md
- Proceed with PR creation if needed
```

If any failures:
```
Overall: ✗ 2 FAILURES

Issues Found:
- Hook not blocking commits (Test 2.1)
- Audio playback failed (Test 2.3)

Next Steps:
- Fix hook script permissions
- Check audio configuration
- Re-run /plugin-test <plugin> after fixes
```

## Development Testing

**When testing development branch plugins**:

### Method A: Docker Sandboxes (Recommended ⭐⭐⭐)

**Workflow**:
1. Develop in feature branch (Terminal 1 - host environment)
2. Run `docker sandbox run claude .` (Terminal 2 - separate terminal)
3. Test plugins in sandbox session (Terminal 2)
4. Report results back to host session (Terminal 1)
5. Merge if tests pass

**Why this works**:
- Complete microVM isolation
- Zero impact on production plugin cache
- Same as Team workflow (user bridges two sessions)

**See**: `docs/testing/docker-sandboxes-guide.md` for detailed guide

### Method B: --plugin-dir (Lightweight ⭐)

**Workflow**:
```bash
git checkout feature/your-feature
claude --plugin-dir plugins/utils
/plugin-test .
exit
```

**Why this works**:
- Session-level isolation
- Simpler than Docker (no separate terminal needed)
- Less isolation than microVM

## Important Notes

1. **Flexible Path Support**: The skill supports multiple path formats:
   - Simple names (backward compatible): `code` → `plugins/code/`
   - Relative paths: `plugins/utils`, `../other-plugin`
   - Absolute paths: `/abs/path/to/plugin`
   - Current directory: `.`
   - Path resolution happens in Step 0 before any validation

2. **Progressive Disclosure**: This frontmatter contains core instructions only. See `references/` for:
   - Detailed validation rules
   - Plugin-specific test patterns
   - Troubleshooting guide

3. **No Plugin Execution**: This skill CANNOT execute plugins directly. It guides the user to execute commands and reports results.

4. **Parallel Reading**: Always read plugin files in parallel when possible to maximize efficiency.

5. **Run All Checks**: In Phase 1, run all checks even if some fail. This provides complete diagnostic information.

6. **Interactive Flow**: Always wait for user confirmation before proceeding to next test.

## See Also

- `references/validation-rules.md` - Detailed validation rules
- `references/test-patterns.md` - Test patterns by plugin type
- `references/troubleshooting.md` - Common issues and solutions
- `docs/testing/docker-sandboxes-guide.md` - Docker Sandboxes for development testing
