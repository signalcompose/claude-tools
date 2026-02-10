# Validation Rules

Detailed validation rules for plugin automated testing.

---

## Check 1: Script Syntax Validation

### Purpose

Verify all shell scripts have valid bash syntax without executing them.

### Method

Use `bash -n` (dry run mode) to check syntax:

```bash
bash -n plugins/<plugin>/scripts/<script>.sh
```

### Success Criteria

- Exit code 0: Syntax is valid
- Exit code != 0: Syntax error

### Examples

**Good script** (no syntax errors):
```bash
bash -n plugins/code/scripts/check-code-review.sh
# Exit code: 0
# Output: (none)
```

**Bad script** (syntax error):
```bash
bash -n plugins/bad/scripts/broken.sh
# Exit code: 2
# Output: broken.sh: line 10: syntax error near unexpected token `fi'
```

### Common Syntax Errors

1. **Missing closing quotes**:
```bash
echo "Hello world
# Error: unexpected end of file
```

2. **Unclosed brackets**:
```bash
if [ -f file.txt ]; then
    echo "exists"
# Error: syntax error: unexpected end of file (missing 'fi')
```

3. **Invalid command substitution**:
```bash
VAR=$cat file.txt)
# Error: syntax error near unexpected token `)'
```

---

## Check 2: Executable Permissions

### Purpose

Verify scripts have execute permission so they can be run by hooks.

### Method

Use `test -x` to check executable bit:

```bash
test -x plugins/<plugin>/scripts/<script>.sh
echo $?  # 0 = executable, 1 = not executable
```

### Success Criteria

- Exit code 0: Script is executable
- Exit code 1: Script is not executable

### Examples

**Executable script**:
```bash
test -x plugins/code/scripts/check-code-review.sh
# Exit code: 0
```

**Non-executable script**:
```bash
test -x plugins/bad/scripts/missing-x.sh
# Exit code: 1
```

### How to Fix

Add execute permission:
```bash
chmod +x plugins/<plugin>/scripts/<script>.sh
```

### Why This Matters

Claude Code hooks require scripts to have execute permission. Without it, hooks will fail silently or with permission denied errors.

---

## Check 3: Hook Configuration Validation

### Purpose

Verify hooks.json is valid and references existing, executable scripts.

### Method

1. **Validate JSON syntax**:
```bash
jq empty plugins/<plugin>/hooks/hooks.json
```

2. **Extract hook commands**:
```bash
jq -r '.hooks[] | .[] | .hooks[] | .command' hooks.json
```

3. **For each command**:
   - Parse script path (expand `${CLAUDE_PLUGIN_ROOT}`)
   - Verify script exists
   - Verify script is executable

### Valid Hook Types

- `PreToolUse` - Before tool execution
- `PostToolUse` - After tool execution
- `UserPromptSubmit` - Before user prompt submission
- `Stop` - When Claude stops (task completion)
- `SessionStart` - When session starts
- `Notification` - When notification is triggered

### Hook Structure

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/check.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

### Validation Steps

**Step 1: Parse hook command**
```bash
COMMAND=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' hooks.json)
# Output: bash ${CLAUDE_PLUGIN_ROOT}/scripts/check.sh
```

**Step 2: Extract script path**
```bash
SCRIPT_PATH=$(echo "$COMMAND" | sed 's/.*${CLAUDE_PLUGIN_ROOT}/plugins\/<plugin>/')
# Output: plugins/<plugin>/scripts/check.sh
```

**Step 3: Verify script exists**
```bash
test -f "$SCRIPT_PATH"
# Exit code: 0 = exists
```

**Step 4: Verify script is executable**
```bash
test -x "$SCRIPT_PATH"
# Exit code: 0 = executable
```

### Examples

**Valid hook**:
```json
{
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-code-review.sh"
}
```
- ✓ Valid hook type
- ✓ Script exists: `plugins/code/scripts/check-code-review.sh`
- ✓ Script is executable

**Invalid hook** (missing script):
```json
{
  "type": "command",
  "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/missing.sh"
}
```
- ✓ Valid hook type
- ✗ Script does not exist
- Error: Hook will fail at runtime

### Common Issues

1. **Typo in script path**:
```json
"command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/chek-review.sh"
//                                                 ^ typo
```

2. **Wrong variable syntax**:
```json
"command": "bash $CLAUDE_PLUGIN_ROOT/scripts/check.sh"
//                ^ missing braces
```

3. **Script not executable**:
```bash
ls -l scripts/check.sh
# -rw-r--r-- 1 user group 1234 Jan 1 12:00 check.sh
#  ^ missing 'x' bit
```

---

## Check 4: File Structure Validation

### Purpose

Verify plugin has required files and at least one functional component.

### Required Files

1. **`.claude-plugin/plugin.json`** (mandatory)
   - Contains plugin metadata
   - Must be valid JSON

2. **`README.md`** (mandatory)
   - User-facing documentation
   - Describes plugin purpose and usage

3. **At least one functional component**:
   - `commands/*.md` (slash commands)
   - `skills/*/SKILL.md` (skills)
   - `hooks/hooks.json` (hooks)

### Validation Method

```bash
# Check plugin.json
test -f plugins/<plugin>/.claude-plugin/plugin.json

# Check README.md
test -f plugins/<plugin>/README.md

# Check at least one component exists
test -d plugins/<plugin>/commands || \
test -d plugins/<plugin>/skills || \
test -f plugins/<plugin>/hooks/hooks.json
```

### Success Criteria

- ✓ plugin.json exists and is valid JSON
- ✓ README.md exists
- ✓ At least one of: commands/, skills/, hooks/

### Examples

**Valid structure**:
```
plugins/code/
├── .claude-plugin/
│   └── plugin.json       ← ✓ exists
├── README.md             ← ✓ exists
├── commands/             ← ✓ has commands
├── skills/               ← ✓ has skills
└── hooks/
    └── hooks.json        ← ✓ has hooks
```

**Invalid structure** (missing component):
```
plugins/bad/
├── .claude-plugin/
│   └── plugin.json       ← ✓ exists
└── README.md             ← ✓ exists
                          ← ✗ no commands, skills, or hooks
```

---

## Check 5: Sandbox Compatibility

### Purpose

Verify scripts follow Claude Code sandbox best practices.

### Good Patterns

1. **Use `${CLAUDE_PLUGIN_ROOT}` for plugin paths**:
```bash
source ${CLAUDE_PLUGIN_ROOT}/scripts/common.sh
```

2. **Use `/tmp/claude/` for temp files**:
```bash
TEMP_FILE="/tmp/claude/my-temp-file"
```

3. **Use `TMPDIR` environment variable**:
```bash
TMPDIR=${TMPDIR:-/tmp/claude}
mkdir -p "$TMPDIR"
```

### Bad Patterns

1. **Hardcoded `~/.claude/` paths**:
```bash
CONFIG="~/.claude/config"  # ✗ Bad
```

Exception: OK in setup documentation or comments:
```bash
# Setup: Copy to ~/.claude/config  ← OK (comment)
```

2. **Direct `/tmp/` usage** (should use `/tmp/claude/`):
```bash
TEMP="/tmp/my-file"  # ✗ Bad
```

3. **Absolute paths without `${CLAUDE_PLUGIN_ROOT}`**:
```bash
/Users/yamato/.claude/plugins/.../script.sh  # ✗ Bad
```

### Detection Method

**Scan for bad patterns**:
```bash
# Check for hardcoded ~/.claude/ (excluding comments)
grep -n '~/.claude' plugins/<plugin>/scripts/*.sh | \
  grep -v CLAUDE_PLUGIN_ROOT | \
  grep -v '^[[:space:]]*#'

# Check for /tmp/ without /tmp/claude/ (catches quoted and unquoted)
grep -n '/tmp/' plugins/<plugin>/scripts/*.sh | \
  grep -v '/tmp/claude' | \
  grep -v '^[[:space:]]*#'
```

### Examples

**Good script**:
```bash
#!/bin/bash
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
TMPDIR="${TMPDIR:-/tmp/claude}"
TEMP_FILE="${TMPDIR}/my-file"

source "${PLUGIN_ROOT}/scripts/common.sh"
```
- ✓ Uses `${CLAUDE_PLUGIN_ROOT}`
- ✓ Uses `/tmp/claude/`
- ✓ Respects TMPDIR

**Bad script**:
```bash
#!/bin/bash
CONFIG="~/.claude/config"
TEMP="/tmp/my-file"

source /Users/yamato/.claude/plugins/code/scripts/common.sh
```
- ✗ Hardcoded `~/.claude/`
- ✗ Direct `/tmp/` usage
- ✗ Absolute path without variable

### Why This Matters

- **Portability**: Scripts work on any system
- **Sandbox compliance**: Respects Claude Code sandbox restrictions
- **Maintainability**: Easier to update paths centrally

---

## Summary

| Check | Method | Exit Code | Fix |
|-------|--------|-----------|-----|
| Script Syntax | `bash -n` | 0 = pass | Fix syntax errors |
| Permissions | `test -x` | 0 = pass | `chmod +x` |
| Hook Config | `jq empty` | 0 = pass | Fix JSON, verify scripts |
| File Structure | `test -f/-d` | 0 = pass | Add missing files |
| Sandbox | `grep -n` | no matches = pass | Replace with good patterns |

**All checks must pass** for Phase 1 to succeed.
