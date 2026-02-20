# Commit Format

## Conventional Commits (title: English, body: user's configured language)

See `${CLAUDE_PLUGIN_ROOT}/skills/_shared/output-rules.md` for language configuration.

```bash
git commit -m "<type>(<scope>): <English summary>" -m "<description in user's configured language>

<details of what was implemented/fixed>

Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

## Types

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `test` | Test additions/changes |
| `refactor` | Code refactoring |
| `chore` | Maintenance tasks |

## Rules

- If pre-commit hook blocks: fix the root cause, then retry commit (see prohibitions.md rule 4)
- Never use `--no-verify` flag
