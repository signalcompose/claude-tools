# PR Body Template

Use this format when creating PRs via `mcp__github__create_pull_request`:

```markdown
## Summary
- Bullet points summarizing the changes

## Test plan
- [x] npm run typecheck
- [x] npm run build
- [x] npm test — X tests passed
- [x] npm run lint

Closes #<issue-number>

Generated with [Claude Code](https://claude.com/claude-code)
```

**Notes**:
- **owner/repo**: Extract from `git remote -v`
- **head**: Current branch name
- **base**: `main`
- **title**: English, under 70 chars, matches commit type
