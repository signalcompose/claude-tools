---
name: speak
description: |
  Speak a message using CVI (Claude Voice Integration).
  Use when: task completion notification, voice message to user.
user-invocable: false
---

# CVI Speak - Voice Notification

Deliver voice notification via persistent CVI Reporter Agent.

## Architecture

**SendMessage-based direct control** with compacting resilience:

```
Main Session
  ↓ (1) SendMessage (type: message)
CVI Reporter Agent (persistent)
  ↓ (2) Execute speak.sh
macOS notification + Glass + voice
  ↓ (3) SendMessage reply
Main Session (notification delivered)
```

**Key features**:
- **Persistent Reporter**: Created once, reused across multiple notifications
- **Compacting resilient**: Auto-respawn on compacting or shutdown
- **No recursion**: Direct speak.sh execution (NOT `/cvi:speak`)

## Step 1: Ensure Reporter Agent Exists

**Check**: Is `cvi-reporter` agent available?

Use SendMessage to ping Reporter:
```
type: "message"
recipient: "cvi-reporter"
summary: "Health check"
content: "ping"
```

**If Reporter responds**: Proceed to Step 2

**If Reporter not found** (no response or error):
- Spawn new Reporter with Task tool
- Agent name: `cvi-reporter`
- Reporter instructions:

```markdown
You are the CVI Reporter Agent. Your role:

1. **Receive voice notification requests** via SendMessage (type: message)
2. **Execute speak.sh** directly (NOT /cvi:speak)
3. **Reply to sender** with completion status

**Message handling**:
- Receive: `content` field contains message to speak
- Format: 2-3 sentences max for voice
- Execute: `bash ~/.claude/plugins/cache/claude-tools/cvi/*/scripts/speak.sh "{message}"`
- Reply: SendMessage back to sender with "Voice notification delivered"

**Configuration**:
- Check `~/.cvi/config` for CVI_ENABLED (default: on)
- If disabled, reply "CVI disabled" without executing

**CRITICAL**: Never call /cvi:speak (infinite recursion). Always use speak.sh directly.

**Lifetime**: Persist across compacting. If respawned, immediately ready to receive requests.
```

## Step 2: Send Notification Request to Reporter

**Use SendMessage tool**:

```
type: "message"
recipient: "cvi-reporter"
summary: "Voice notification request"
content: "{args from caller}"
```

**Reporter will**:
1. Receive message
2. Check CVI_ENABLED in ~/.cvi/config
3. Format message (2-3 sentences)
4. Execute speak.sh directly
5. Reply to sender

## Step 3: Wait for Reporter Reply

**Reporter reply will contain**:
- "Voice notification delivered" (success)
- "CVI disabled" (if CVI_ENABLED=off)
- Error message (if speak.sh failed)

Display reply to user.

## Compacting Resilience

**On compacting**:
- Reporter agent may be terminated
- Next `/cvi:speak` call will re-detect missing Reporter (Step 1)
- Auto-respawn new Reporter
- Continue normal operation

**No manual cleanup needed**: Reporter persists indefinitely until compacting.

## Notes

- **Migration from queue system**: Replaces PostToolUse hook + queue file
- **Persistent agent**: Created once, handles multiple notifications
- **SendMessage-based**: Direct control without skill recursion
- **Compacting safe**: Auto-recovery on agent loss

## Example Usage

```
<use Skill tool: skill="cvi:speak" args="Task completed successfully. All files updated.">
```

Flow:
1. Main session checks Reporter exists (Step 1)
2. Sends message to Reporter (Step 2)
3. Reporter executes speak.sh → macOS notification + Glass + voice
4. Reporter replies → Main session displays confirmation
