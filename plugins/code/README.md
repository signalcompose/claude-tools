# code - Claude Code Plugin

Lean code-quality tooling for Claude Code: parallel review teams, refactoring team,
secret scanning, and a pre-merge checklist reminder. No pipeline orchestration, no
enforcement hooks beyond a single pre-commit security check.

## Design principles

- **Let auto mode drive.** No phase-gated pipeline, no state machine that competes
  with auto mode's run-to-completion behaviour.
- **Skills when parallel subagents add value.** `pr-review-team` and `refactor-team`
  orchestrate multiple specialised agents — that is the value. Everything that was
  just "orchestration over other skills" has been removed.
- **Checklists, not verifiers.** `/code:checkup` surfaces pre-merge items as a
  reminder; it does not claim they are done. Judgement stays with the user.
- **One physical safety hook.** `check-gitignore-security.sh` blocks `git commit`
  when `.gitignore` lacks the security-patterns marker. Everything else is advisory.

## Commands

| Command | Purpose |
|---------|---------|
| `/code:pr-review-team [PR]` | 4 parallel reviewer agents + CI integration + iterate-until-converged fix loop |
| `/code:refactor-team` | Team-based refactoring: analyse → user approval → execute |
| `/code:checkup` | Pre-merge checklist reminder (does not verify) |
| `/code:trufflehog-scan` | Run TruffleHog secret scan on the current git repository |

`/code:pr-review-team` works best when invoked with an explicit iterate instruction,
e.g. `/code:pr-review-team 123 iterate until critical=0 important=0`. The skill body
holds the contract, but the explicit prompt reinforces it at the strong layer.

## Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `check-gitignore-security.sh` | PreToolUse on `git commit*` | Blocks commit if `.gitignore` lacks the `code:security-patterns` marker. Suggests a one-line fix. |
| `pr-review-team/scripts/verify-workflow.sh` | Stop | When a `pr-review-team` run is active, verifies the workflow completed properly (all reviewers ran, security checklist read, etc.) |

No other hooks. No state files. No flag directories. No PostToolUse monitors.

## Installation

```
/plugin marketplace add signalcompose/claude-tools
/plugin install code@claude-tools
```

## Typical workflow

1. Plan (`/plan` built-in, or just chat)
2. Implement in auto mode
3. Commit, push, `gh pr create`
4. `/code:pr-review-team <PR> iterate until c=0 i=0`
5. Before merge: `/code:checkup` surfaces items worth considering
6. Merge when ready (user-initiated only)

## Files

```
plugins/code/
├── commands/
│   ├── pr-review-team.md
│   ├── refactor-team.md
│   ├── trufflehog-scan.md
│   └── checkup.md (optional wrapper, see skills/checkup)
├── skills/
│   ├── _shared/
│   ├── checkup/
│   ├── pr-review-team/
│   └── refactor-team/
├── scripts/
│   ├── check-gitignore-security.sh
│   ├── pr-review-state.sh
│   └── wait-ci-checks.sh
├── references/
│   └── gitignore-security-patterns.md
├── hooks/hooks.json
└── tests/
    ├── pr-review-state-session-binding.bats
    └── validate-skills.bats
```

## History

This plugin previously shipped an orchestration suite (`autopilot`, `dev-cycle`,
`sprint-impl`, `audit-compliance`, `shipping-pr`, `retrospective`, `review-commit`,
`plan`, `setup-dev-env`) that wrapped other skills behind phase gates. Repeated
real-run observations (claude-tools #247, #250, #251, #253, #254, #260) showed the
phase gates were at a weaker signal layer than auto mode's run-to-completion drive
and the leader's current-turn prompt. The orchestration was removed; `/code:checkup`
replaces the pre-merge portion of those flows as a reminder-only skill.
