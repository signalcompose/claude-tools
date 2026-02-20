# Main Agent Absolute Prohibitions

The following actions are **absolutely prohibited**. Violations result in HIGH FAIL in PROCESS audit:

1. **Manual review-approval hash creation**
   - NEVER directly write to `/tmp/claude/review-approved-*` files
   - Approval must always go through `approve-review.sh` script

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
