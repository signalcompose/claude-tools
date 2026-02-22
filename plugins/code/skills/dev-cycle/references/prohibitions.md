# Main Agent Absolute Prohibitions

The following actions are **absolutely prohibited**. Violations result in HIGH FAIL in PROCESS audit:

1. **Manual review-approval hash creation**
   - NEVER directly write to `/tmp/claude/review-approved-*` files
   - The flag file is created by the `shipping-pr` / `review-commit` workflow after the code-reviewer Agent reports 0 critical and 0 important issues
   - Manual creation (`echo "$HASH" > /tmp/claude/review-approved-*`) is a violation

2. **Manual code review**
   - The main agent must NOT read diff and judge "no issues" itself
   - Always delegate to `pr-review-toolkit:code-reviewer` Agent

3. **Skipping `/code:shipping-pr` skill**
   - Ad-hoc `git push` + PR creation is prohibited
   - Final shipping (push + PR creation) must go through `/code:shipping-pr`
   - Mid-sprint intermediate commits (per-agent commits, etc.) are exempt

4. **Pre-commit hook circumvention**
   - `--no-verify` flag usage is prohibited
   - If a hook blocks, resolve the root cause and retry

5. **Responding in non-configured language**
   - All user-facing output MUST follow the language configured in user settings
   - SKILL.md files are written in English, but this does NOT change the output language
   - Technical terms and code identifiers may remain in English

6. **Deleting state file during active cycle**
   - NEVER delete `.claude/dev-cycle.state.json` while a dev-cycle is in progress
   - The state file drives all hook enforcement (Stop, PostToolUse, UserPromptSubmit)
   - Deleting it silently disables the entire auto-chain mechanism
   - Only the Stop hook or explicit cycle-end cleanup may remove this file
