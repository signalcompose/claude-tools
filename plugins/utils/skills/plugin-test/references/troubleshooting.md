# Troubleshooting Guide

Common issues during plugin testing and how to resolve them.

---

## Phase 1: Automated Validation Issues

### Issue: Script Syntax Error

**Symptom**:
```
✗ check-code-review.sh: line 42: syntax error near unexpected token `fi'
```

**Causes**:
- Missing closing quotes
- Unclosed brackets/parentheses
- Invalid command syntax
- Bash version incompatibility

**Solutions**:

1. **Check the specific line**:
```bash
sed -n '42p' plugins/code/scripts/check-code-review.sh
```

2. **Common fixes**:
   - Add missing `fi`, `done`, or `esac`
   - Close open quotes
   - Balance brackets: `[[ ]]`, `( )`, `{ }`

3. **Test fix**:
```bash
bash -n plugins/code/scripts/check-code-review.sh
```

---

### Issue: Permission Denied

**Symptom**:
```
⚠ check-code-review.sh: not executable
```

**Cause**:
- Script missing execute permission
- Created/edited without preserving permissions

**Solution**:
```bash
chmod +x plugins/code/scripts/check-code-review.sh
```

**Verify**:
```bash
ls -l plugins/code/scripts/check-code-review.sh
# Should show: -rwxr-xr-x (note the 'x' bits)
```

**Prevent in future**:
- Set execute permission immediately after creating script
- Check permissions before committing

---

### Issue: Hook Configuration Invalid

**Symptom**:
```
✗ PostToolUse: missing-script.sh (not found)
```

**Causes**:
- Typo in script filename
- Script in wrong directory
- Hook references deleted script

**Solutions**:

1. **Find the reference**:
```bash
jq '.hooks.PostToolUse' plugins/code/hooks/hooks.json
```

2. **Check if script exists**:
```bash
ls plugins/code/scripts/missing-script.sh
```

3. **Fix options**:
   - **If typo**: Fix hook configuration
   - **If script missing**: Create the script
   - **If obsolete**: Remove hook entry

4. **Validate JSON after fix**:
```bash
jq empty plugins/code/hooks/hooks.json
```

---

### Issue: Sandbox Compatibility Warning

**Symptom**:
```
⚠ Found hardcoded paths in:
  - check-review.sh:15: ~/.claude/config
  - check-review.sh:23: /tmp/file
```

**Causes**:
- Hardcoded paths in scripts
- Not using `${CLAUDE_PLUGIN_ROOT}`
- Direct `/tmp/` usage

**Solutions**:

1. **Replace hardcoded `~/.claude/` paths**:

**Before**:
```bash
CONFIG="~/.claude/config"
```

**After**:
```bash
CONFIG="${HOME}/.claude/config"
# Or better: make it configurable
```

2. **Replace `/tmp/` with `/tmp/claude/`**:

**Before**:
```bash
TEMP_FILE="/tmp/my-file"
```

**After**:
```bash
TMPDIR="${TMPDIR:-/tmp/claude}"
TEMP_FILE="${TMPDIR}/my-file"
```

3. **Use `${CLAUDE_PLUGIN_ROOT}`**:

**Before**:
```bash
source /Users/yamato/.claude/plugins/code/scripts/common.sh
```

**After**:
```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/common.sh"
```

---

### Issue: File Structure Invalid

**Symptom**:
```
✗ No functional components found (need commands/, skills/, or hooks/)
```

**Cause**:
- Plugin has no commands, skills, or hooks
- Directories not created
- Empty directories

**Solution**:

Create at least one component:

**Option 1: Add a command**:
```bash
mkdir -p plugins/<plugin>/commands
cat > plugins/<plugin>/commands/hello.md <<'EOF'
# Hello Command

Say hello!

Hello: !`echo "Hello from plugin"`
EOF
```

**Option 2: Add a skill**:
```bash
mkdir -p plugins/<plugin>/skills/my-skill
cat > plugins/<plugin>/skills/my-skill/SKILL.md <<'EOF'
---
name: my-skill
description: Example skill
---

# My Skill

Instructions for Claude...
EOF
```

**Option 3: Add hooks**:
```bash
mkdir -p plugins/<plugin>/hooks
cat > plugins/<plugin>/hooks/hooks.json <<'EOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Task completed'"
          }
        ]
      }
    ]
  }
}
EOF
```

---

## Phase 2: Manual Testing Issues

### Issue: Hook Not Blocking

**Symptom**:
- Test expects commit to be blocked
- Commit succeeds without error

**Causes**:
1. Hook not installed/registered
2. Script returning exit code 0 instead of 2
3. Hook matcher not matching tool
4. Script has syntax error (fails silently)

**Solutions**:

**Check 1: Verify hook is installed**:
```bash
# Check if plugin is loaded
/plugin list

# For manual hooks, check settings.json
cat ~/.claude/settings.json | jq '.hooks'
```

**Check 2: Test hook script directly**:
```bash
# Simulate hook input
echo '{"tool_input":{"command":"git commit -m test"}}' | \
  bash plugins/code/scripts/check-code-review.sh
echo $?  # Should be 2 for blocking
```

**Check 3: Verify hook matcher**:
```bash
jq '.hooks.PreToolUse[].matcher' plugins/code/hooks/hooks.json
# Should match tool name (e.g., "Bash")
```

**Check 4: Check for script errors**:
```bash
bash -n plugins/code/scripts/check-code-review.sh
```

**Fix**: Correct the identified issue and re-run test.

---

### Issue: Audio Not Playing

**Symptom**:
- No sound during voice test
- Skill completes but no audio

**Causes**:
1. System volume muted
2. Audio output device wrong
3. `say` command not available
4. Script error

**Solutions**:

**Check 1: System audio**:
- Check volume is not muted
- Test with: `say "test"`
- Verify correct output device

**Check 2: Verify `say` command**:
```bash
which say
# Should return: /usr/bin/say (on macOS)
```

**Check 3: Test audio script directly**:
```bash
bash plugins/cvi/scripts/speak-from-queue.sh
# Manually trigger the script
```

**Check 4: Check logs**:
```bash
# Look for error messages in Claude Code output
# Check /tmp/claude/ for temp files
ls -la /tmp/claude/
```

---

### Issue: Team Not Spawning

**Symptom**:
- Skill invoked but no team created
- Error: "TeamCreate tool not available"

**Causes**:
1. Runtime limitation (Claude Code version)
2. Permission issue
3. Skill syntax error

**Solutions**:

**Check 1: Verify Claude Code version**:
- Team features require recent Claude Code version
- Update Claude Code if outdated

**Check 2: Check skill syntax**:
```bash
# Read skill file
cat plugins/code/skills/review-commit/SKILL.md

# Look for TeamCreate usage
grep -n "TeamCreate" plugins/code/skills/review-commit/SKILL.md
```

**Check 3: Test manually**:
- Try creating team in main conversation
- If fails, issue is environmental, not plugin-specific

---

### Issue: Agent Not Responding

**Symptom**:
- Agent spawned but not performing task
- Agent idle/stuck

**Causes**:
1. Agent waiting for input
2. Task not properly assigned
3. Agent configuration issue

**Solutions**:

**Check 1: Verify task assignment**:
- Check if task was assigned to agent
- Verify task status

**Check 2: Send message to agent**:
- Use SendMessage to communicate
- Check if agent is waiting for input

**Check 3: Check agent logs**:
- Review agent output for errors
- Look for blocking issues

---

### Issue: Test Cannot Be Completed

**Symptom**:
- Cannot execute test due to environment
- Missing dependencies
- Hardware limitation

**Solutions**:

**Option 1: Skip test**:
```
When prompted: "Ready to proceed? (yes/skip/abort)"
Answer: skip
```

**Option 2: Document limitation**:
- Note in test results
- Mark as "SKIP - environment limitation"
- Provide reason

**Option 3: Abort testing**:
```
When prompted: "Ready to proceed? (yes/skip/abort)"
Answer: abort
```

---

## Common Error Messages

### "Plugin not found"

**Cause**: Plugin directory doesn't exist or is misnamed

**Fix**:
```bash
ls plugins/  # Verify plugin name
# Use exact name from directory
```

---

### "jq: command not found"

**Cause**: jq not installed

**Fix**:
```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq
```

---

### "Permission denied" (during hook execution)

**Cause**: Script not executable

**Fix**:
```bash
chmod +x plugins/<plugin>/scripts/<script>.sh
```

---

### "No such file or directory"

**Cause**: Script path wrong in hooks.json

**Fix**:
1. Verify script exists
2. Check path in hooks.json
3. Ensure `${CLAUDE_PLUGIN_ROOT}` is used correctly

---

## Debugging Tips

### Enable Verbose Output

**For bash scripts**:
```bash
# Add to top of script
set -x  # Print each command before execution
```

**For hook debugging**:
```bash
# Run script manually with verbose flag
bash -x plugins/code/scripts/check-code-review.sh
```

---

### Check Environment Variables

```bash
# Check CLAUDE_PLUGIN_ROOT (in hooks)
echo "${CLAUDE_PLUGIN_ROOT}"

# Check TMPDIR
echo "${TMPDIR}"
```

---

### Isolate Issues

**Test components individually**:

1. **Script syntax**: `bash -n script.sh`
2. **Script execution**: `bash script.sh`
3. **Hook JSON**: `jq empty hooks.json`
4. **File existence**: `test -f file && echo exists`

**Then combine** to find where integration fails.

---

## Getting Help

If issues persist after trying these solutions:

1. **Re-run validation**:
```
/utils:plugin-test <plugin>
```

2. **Check documentation**:
- Plugin README.md
- CLAUDE.md (if exists)

3. **Report issue**:
- Include error messages
- Include test results
- Include environment info (OS, Claude Code version)

4. **Ask user**:
- If stuck, ask user for guidance
- User may have context you don't

---

## Prevention

**Best practices to avoid issues**:

1. **Always run Phase 1 before manual testing**
2. **Fix automated issues first**
3. **Test scripts individually before integration**
4. **Use version control** - commit working versions
5. **Document unusual configurations**
6. **Test on clean environment** when possible

---

## Summary

| Issue | Quick Fix | Verify Command |
|-------|-----------|----------------|
| Syntax error | Fix line mentioned in error | `bash -n script.sh` |
| Permission denied | `chmod +x script.sh` | `test -x script.sh` |
| Hook not blocking | Check exit code in script | Test script directly |
| Audio not playing | Check volume, test `say` | `say "test"` |
| Team not spawning | Check Claude Code version | Try manual TeamCreate |

**Remember**: Most issues are configuration/environment, not bugs in testing framework.
