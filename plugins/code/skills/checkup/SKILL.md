---
name: checkup
description: |
  Surface things worth considering before merging a PR: simplify run, pr-review-team iterate,
  security scan (trufflehog), .gitignore patterns, tests, docs, and any project-specific items
  from CLAUDE.md. This is a reminder, not a verifier.
  Use when: "merge 前チェック", "チェックリスト", "何か漏れてない?", "pre-merge", "checkup",
  "マージ前確認".
user-invocable: true
---

# /code:checkup — pre-merge reminder list

**MANDATORY framing**: This skill is a **reminder**, not a **verifier**. Its job is to
*surface* items the user may want to consider before merging. It MUST NOT:

- Claim any item is "done" or "not done"
- Declare "all clear" or "ready to merge"
- Infer status from flags, logs, timestamps, or git history

The user reads the surfaced list, judges each item, and acts. Accuracy of judgement
belongs to the user, not to this skill.

## How to present the list

Output a single flat list. For each core item, one line of `item name — purpose`.
No check marks. No status columns. No categorization by "likely done" vs "likely
pending". Each item is presented as a prompt for the user to consider.

## Core checklist (hardcoded, apply to every run)

Always surface all of these:

- **simplify** — has `/simplify` (or equivalent) been run on this diff for reuse / quality / efficiency?
- **pr-review-team** — has `/code:pr-review-team` been run with explicit iterate-till-c=0-i=0 instruction?
- **secret scan** — has `/code:trufflehog-scan` (or equivalent) been run recently?
- **.gitignore security patterns** — does `.gitignore` have the `code:security-patterns` marker? (The `check-gitignore-security.sh` pre-commit hook already guards this; surface here as reminder in case the hook is disabled.)
- **tests** — do project tests pass locally against the current working tree?
- **docs** — if behavior or public API changed, is the documentation updated?

## Project-specific checklist (read from CLAUDE.md)

Read the current project's `CLAUDE.md` (both `~/.claude/CLAUDE.md` and the
project-local one if present). Scan for explicit pre-merge / pre-ship / pre-commit
items the project calls out. Surface anything you find as additional list entries
in the same flat format.

Do **not** invent items that aren't in CLAUDE.md. Do **not** summarize what the
project does. Only surface explicit "remember to do X before merging / shipping /
committing" items.

If CLAUDE.md mentions nothing pre-merge specific, that section is simply absent
from the output.

## Output format

```
## Pre-merge checklist

(Consider each item. This list does NOT claim any item is done — that is your judgement.)

- simplify — <one-line purpose>
- pr-review-team — <one-line purpose>
- secret scan — <one-line purpose>
- .gitignore security patterns — <one-line purpose>
- tests — <one-line purpose>
- docs — <one-line purpose>

## Project-specific (from CLAUDE.md)
- <item> — <one-line>
- <item> — <one-line>

(If CLAUDE.md lists nothing specific, omit this section.)
```

End with a brief neutral note, e.g.:
`Review each item and decide; this list does not declare readiness.`

Then add a one-line invitation so the user knows they can delegate the
per-item inspection manually if they want it:

`If you'd like me to actually inspect each item and report status, say "check".`

The skill itself still does not verify. Inspection only happens on the user's
explicit follow-up ("check"), keeping this skill as a reminder.

## Rationalization patterns to reject

- "Looks clean to me, all done." — not this skill's call to make
- "git log shows simplify was invoked recently, so that's covered." — inference is explicitly out of scope
- "CI is green, so tests are fine." — CI runs on a PR, not necessarily on the local tree
- "I already ran pr-review-team, so it's done." — the user already knows what they ran; this skill's job is to prompt, not confirm

## Out of scope

- Inspection of git state, PR state, flag files, or log timestamps
- Pass/fail judgement of any item
- Enforcement or blocking
- Integration with any pipeline state machine

These are explicitly out of scope so the skill stays reliable. If verification is
ever wanted, it should be a separate skill layered on top — not folded in here.
