# Commit Format

## Conventional Commits (title: English, body: Japanese)

```bash
git commit -m "<type>(<scope>): <English summary>" -m "<Japanese description>

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

- If pre-commit hook blocks: re-run approve script, then retry commit
- Never use `--no-verify` flag
