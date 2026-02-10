# Test Patterns by Plugin Type

Manual test patterns organized by plugin type.

---

## Overview

Different plugin types require different manual testing approaches:

1. **Hook-Based Plugins** - Test hook triggering and blocking
2. **Voice/Audio Plugins** - Test audio playback and interruption
3. **Team/Agent Plugins** - Test team spawning and coordination
4. **Utility Plugins** - Test commands and skills

---

## 1. Hook-Based Plugins

**Examples**: code, cvi (partial)

**Detection criteria**:
- Has `hooks/hooks.json`
- Contains PreToolUse or PostToolUse hooks

### Test 1.1: PreToolUse Hook Blocking

**Purpose**: Verify hook blocks tool execution when conditions not met

**Setup**:
```bash
# Stage a file to create a testable scenario
echo "// Test change" >> README.md
git add README.md
```

**Execute**:
```bash
# Attempt blocked action (e.g., git commit without approval)
git commit -m "test: should be blocked"
```

**Expected behavior**:
- Command is blocked
- Error message is displayed
- Exit code is 2 (blocking error)

**Validation questions**:
1. Was the commit blocked? (yes/no)
2. Did an error message appear? (yes/no)
3. What was the error message? (text)

**Success criteria**:
- ✓ Commit blocked
- ✓ Error message shown
- ✓ Changes remain staged

### Test 1.2: PostToolUse Hook Execution

**Purpose**: Verify hook executes after tool use

**Setup**:
```bash
# Prepare environment for hook trigger
# (varies by plugin)
```

**Execute**:
```bash
# Execute tool that triggers PostToolUse hook
# Example: Run a git command
git status
```

**Expected behavior**:
- Hook executes after command
- Side effects occur (logs, notifications, etc.)

**Validation questions**:
1. Did the hook execute? (yes/no)
2. Were expected side effects observed? (yes/no)

**Success criteria**:
- ✓ Hook triggered
- ✓ Expected behavior occurred

### Test 1.3: Hook Approval Flow

**Purpose**: Verify hook allows action after approval

**Setup**:
```bash
# Stage changes
echo "// Test" >> README.md
git add README.md
```

**Execute**:
```bash
# 1. Run approval command (varies by plugin)
# Example for code plugin: /code:review-commit

# 2. Retry blocked action
git commit -m "test: should succeed after approval"
```

**Expected behavior**:
- Approval command succeeds
- Subsequent action is not blocked
- Approval flag/state is consumed

**Validation questions**:
1. Did approval command succeed? (yes/no)
2. Did commit succeed after approval? (yes/no)
3. Was approval consumed (can't commit twice)? (yes/no)

**Success criteria**:
- ✓ Approval granted
- ✓ Action succeeded
- ✓ Approval consumed

---

## 2. Voice/Audio Plugins

**Examples**: cvi

**Detection criteria**:
- Plugin name or description contains "voice", "speak", "audio", "tts"
- Has commands/skills related to voice

### Test 2.1: Voice Playback

**Purpose**: Verify audio plays correctly

**Setup**:
```bash
# Ensure audio is enabled
# Check system volume is not muted
```

**Execute**:
```
# Use voice command
/cvi:speak "This is a test message"
```

**Expected behavior**:
- Audio plays through speakers
- Message is clearly audible
- Correct voice is used (language-appropriate)

**Validation questions**:
1. Did you hear audio? (yes/no)
2. Was the message clear? (yes/no)
3. Was the correct voice used? (yes/no)

**Success criteria**:
- ✓ Audio played
- ✓ Message audible
- ✓ Correct voice

### Test 2.2: Audio Interruption

**Purpose**: Verify audio stops when interrupted

**Setup**:
```
# Start a long audio playback
/cvi:speak "This is a very long message that will take several seconds to complete and should be interrupted before finishing"
```

**Execute**:
```bash
# Immediately send new user input (before audio finishes)
# Type any message in Claude Code
```

**Expected behavior**:
- Audio stops immediately
- No audio overlap
- Temp files cleaned up

**Validation questions**:
1. Did audio stop immediately? (yes/no)
2. Was there any audio overlap? (yes/no)

**Success criteria**:
- ✓ Audio interrupted
- ✓ No overlap
- ✓ Clean shutdown

### Test 2.3: Language Detection

**Purpose**: Verify correct voice selected for language

**Setup**:
```bash
# Check language settings
/cvi:check
```

**Execute**:
```
# Test Japanese
/cvi:speak "これは日本語のテストです"

# Test English
/cvi:speak "This is an English test"
```

**Expected behavior**:
- Japanese uses Japanese voice (Kyoko)
- English uses English voice

**Validation questions**:
1. Was Japanese voice used for Japanese? (yes/no)
2. Was English voice used for English? (yes/no)

**Success criteria**:
- ✓ Correct Japanese voice
- ✓ Correct English voice

---

## 3. Team/Agent Plugins

**Examples**: code (review-commit skill)

**Detection criteria**:
- Has skills with "team", "agent", "spawn" in description
- Uses TeamCreate or Task tool in skill

### Test 3.1: Team Spawning

**Purpose**: Verify team spawns successfully

**Setup**:
```bash
# Prepare environment for team-based task
echo "// Test" >> README.md
git add README.md
```

**Execute**:
```
# Invoke skill that spawns team
/code:review-commit
```

**Expected behavior**:
- Team created successfully
- Multiple agents spawn
- Agents communicate and coordinate

**Validation questions**:
1. Did team spawn successfully? (yes/no)
2. How many agents were spawned? (number)
3. Did agents communicate? (yes/no)

**Success criteria**:
- ✓ Team created
- ✓ Agents spawned
- ✓ Communication observed

### Test 3.2: Agent Coordination

**Purpose**: Verify agents work together correctly

**Setup**:
```bash
# Same as Test 3.1
```

**Execute**:
```
# Continue from Test 3.1
# Observe agent behavior
```

**Expected behavior**:
- Agents complete assigned tasks
- Work is coordinated (no conflicts)
- Results are communicated back

**Validation questions**:
1. Did agents complete their tasks? (yes/no)
2. Was work coordinated properly? (yes/no)
3. Were results communicated? (yes/no)

**Success criteria**:
- ✓ Tasks completed
- ✓ Coordination successful
- ✓ Results delivered

### Test 3.3: Team Shutdown

**Purpose**: Verify team shuts down cleanly

**Setup**:
```bash
# Continue from Test 3.2
```

**Execute**:
```
# Wait for team to complete work
# Team should shutdown automatically
```

**Expected behavior**:
- All agents shutdown cleanly
- Team resources cleaned up
- No zombie processes

**Validation questions**:
1. Did all agents shutdown? (yes/no)
2. Were resources cleaned up? (yes/no)
3. Any errors during shutdown? (yes/no)

**Success criteria**:
- ✓ Clean shutdown
- ✓ Resources freed
- ✓ No errors

---

## 4. Utility Plugins

**Examples**: utils, ypm, chezmoi

**Detection criteria**:
- Has commands or skills
- No special hooks (or simple hooks)
- General-purpose functionality

### Test 4.1: Basic Command Execution

**Purpose**: Verify commands execute successfully

**Execute**:
```
# Invoke a command from the plugin
/<plugin>:<command>
```

**Expected behavior**:
- Command executes without errors
- Expected output is produced
- Side effects occur (if applicable)

**Validation questions**:
1. Did command execute successfully? (yes/no)
2. Was output as expected? (yes/no)
3. Did side effects occur? (yes/no)

**Success criteria**:
- ✓ Command succeeded
- ✓ Expected output
- ✓ Side effects correct

### Test 4.2: Skill Invocation

**Purpose**: Verify skills work correctly

**Execute**:
```
# Invoke a skill from the plugin
/<plugin>:<skill> [args]
```

**Expected behavior**:
- Skill provides guidance to Claude
- Claude follows skill instructions
- Task is completed successfully

**Validation questions**:
1. Did skill load correctly? (yes/no)
2. Did Claude follow instructions? (yes/no)
3. Was task completed? (yes/no)

**Success criteria**:
- ✓ Skill loaded
- ✓ Instructions followed
- ✓ Task completed

### Test 4.3: Error Handling

**Purpose**: Verify plugin handles errors gracefully

**Execute**:
```
# Invoke command with invalid input
/<plugin>:<command> <invalid-args>
```

**Expected behavior**:
- Error is caught
- Clear error message shown
- No crash or hang

**Validation questions**:
1. Was error caught? (yes/no)
2. Was error message clear? (yes/no)
3. Did plugin crash? (yes/no)

**Success criteria**:
- ✓ Error caught
- ✓ Clear message
- ✓ No crash

---

## Special Case: Mixed-Type Plugins

Some plugins combine multiple types (e.g., cvi has both hooks and voice).

**Detection criteria**:
- Matches multiple type criteria

**Test approach**:
- Run all applicable test patterns
- Test interaction between features

**Example** (cvi):
1. Run Hook-Based tests (Stop hook)
2. Run Voice/Audio tests (playback, interruption)
3. Test interaction:
   - Does Stop hook trigger voice?
   - Does UserPromptSubmit interrupt voice?

---

## Test Flow Template

For each test:

```
Test X.Y: <Name>
────────────────────────────

Purpose: <Why this test matters>

Setup (if needed):
```bash
# Commands to prepare environment
```

Ready to proceed? (yes/skip/abort)

Execute:
```bash
# Commands or actions to perform
```

Expected Behavior:
- <What should happen>
- <Observable results>

Did it work as expected? (yes/no/error)

[Record result: ✓ PASS / ✗ FAIL / ⚠ SKIP]

Issues (if any):
<User can describe what went wrong>
```

---

## Summary

| Plugin Type | Key Tests | Detection Method |
|-------------|-----------|------------------|
| Hook-Based | Hook blocking, approval flow | Has hooks.json, PreToolUse |
| Voice/Audio | Playback, interruption | "voice"/"audio" in name/desc |
| Team/Agent | Spawn, coordination, shutdown | Skills with "team"/"agent" |
| Utility | Command exec, skill invoke | Has commands/skills |

**Customize tests** based on specific plugin features and use cases.
