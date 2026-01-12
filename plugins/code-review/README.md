# code-review - Claude Code Plugin

Claude Code integration for code review workflow before commits.

## Features

- **Code Review**: Automated review of staged changes
- **Pre-commit Hook**: Optional hook to enforce review before commit
- **Hash Verification**: Ensures reviewed code matches committed code

## Requirements

- macOS or Linux
- Git installed and configured
- jq (optional, for better JSON parsing in hooks)

## Installation

```
/plugin marketplace add signalcompose/claude-tools
/plugin install code-review
```

## Commands & Skills

| Command/Skill | Description |
|---------------|-------------|
| `/code:review-commit` | Review staged changes and approve for commit |
| `/code:trufflehog-scan` | Run TruffleHog security scan on current project |

## Usage

### Basic Code Review

```
/code:review-commit
```

This will:
1. Check for staged changes (`git diff --cached`)
2. Perform code review (quality, security, best practices)
3. Report any issues found
4. Approve for commit if no blocking issues

### With Pre-commit Hook (Optional)

Enable the pre-commit hook to enforce code review:

1. Add to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash /path/to/check-code-review.sh"
          }
        ]
      }
    ]
  }
}
```

2. With the hook enabled:
   - Direct `git commit` will be blocked
   - Run `/code:review-commit` first
   - After approval, `git commit` proceeds

## How It Works

```
Stage changes → /code:review-commit → Approval hash saved → git commit (allowed)
     ↓                   ↓                    ↓                    ↓
  git add            Review code         .claude/review-approved    Push
                     Check quality        (hash of staged diff)
                     Check security
```

### Hash Verification

The plugin uses SHA-256 hash of staged changes to ensure:
- Code hasn't changed between review and commit
- Review approval is tied to specific changes
- Re-staging files requires re-review

## Review Criteria

The code review checks for:

### Code Quality
- Readability and maintainability
- Proper error handling
- No hardcoded sensitive values

### Security
- No exposed secrets or credentials
- No SQL injection vulnerabilities
- No XSS vulnerabilities
- Input validation where needed

### Best Practices
- Project conventions (CLAUDE.md)
- Naming conventions
- No unnecessary duplication

### Logic
- No obvious bugs
- Edge cases handled
- Correct algorithm usage

## Files

```
plugins/code-review/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata
├── commands/
│   └── trufflehog-scan.md    # Security scan command
├── skills/
│   └── review-commit/
│       └── SKILL.md        # Review skill definition
├── scripts/
│   ├── approve-review.sh     # Saves approval hash
│   └── check-code-review.sh  # Pre-commit hook script
├── hooks/
│   └── hooks.json            # Optional hook configuration
├── .claude/
│   └── settings.json         # Permissions
├── README.md                 # This file
└── LICENSE                   # MIT License
```

## Troubleshooting

### "Code review required before commit"

Run `/code:review-commit` to review staged changes before committing.

### "Staged changes have been modified since review"

Changes were made after review approval. Run `/code:review-commit` again.

### Hook not working

1. Ensure jq is installed: `brew install jq`
2. Verify hook path in settings.json
3. Check script permissions: `chmod +x scripts/*.sh`

## License

MIT License - see [LICENSE](./LICENSE)
