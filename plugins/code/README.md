# code - Claude Code Plugin

Code quality tools for Claude Code: commit review, PR team review, and refactoring team.

## Features

- **Team-based Code Review**: 反復的、自動修正レビューループ
- **PR Team Review**: 4つの専門エージェントによる並行PRレビュー + CI統合
- **Refactoring Team**: 分析→ユーザー承認→実行のリファクタリングワークフロー
- **Quality Assurance**: critical/important問題の完全解決を保証
- **PR Creation Gate**: PR作成前にレビュー実行をチェック（PreToolUseフック）

## Requirements

- macOS or Linux
- Git installed and configured
- jq (optional, for better JSON parsing in hooks)

## Installation

```
/plugin marketplace add signalcompose/claude-tools
/plugin install code@claude-tools
```

## Commands & Skills

| Command/Skill | Description |
|---------------|-------------|
| `/code:review-commit` | Review staged changes and approve for commit |
| `/code:pr-review-team` | Team-based PR review with specialized agents |
| `/code:refactor-team` | Team-based code refactoring with analysis |
| `/code:trufflehog-scan` | Run TruffleHog security scan on current project |

## Usage

### Basic Code Review

```
/code:review-commit
```

This will:
1. Check for staged changes (`git diff --cached`)
2. Create review team (reviewer + fixer)
3. Review code iteratively until quality is achieved
4. Auto-fix critical/important issues
5. Set approval flag for PR creation

### With PR Creation Gate (Optional)

Enable the PreToolUse hook to enforce code review before PR creation:

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
            "command": "bash /path/to/check-pr-review-gate.sh"
          }
        ]
      }
    ]
  }
}
```

2. With the hook enabled:
   - `gh pr create` will be blocked until review is approved
   - Run `/code:review-commit` first to review and approve
   - After approval, `gh pr create` proceeds
   - Other commands (`git commit`, `gh pr view`, etc.) are not affected

## コードレビューワークフロー

### 概要

`/code:review-commit`は、コミット前に**品質を保証**する反復的、チームベースのコードレビューを提供。

### 仕組み

1. **変更をステージング**: `git add <files>`
2. **レビュー実行**: `/code:review-commit`
3. **自動品質ループ**:
   - レビューチーム作成 (reviewer + fixer)
   - Reviewerがコードを分析 (pr-review-toolkit:code-reviewer)
   - critical/important問題発見時:
     - Fixerが自動的に問題を解決
     - 変更がステージング
     - 修正を検証するため再レビュー
   - critical/important = 0まで繰り返し（最大5回）
4. **コミット**: `git commit -m "message"`

### 品質保証

フラグベースの承認フロー：
- ✅ **問題を修正**（フラグ立てるだけではない）
- ✅ **品質達成まで反復**
- ✅ **専門的レビューagentを使用**
- ✅ **シンプルなフラグ方式**（`/tmp/claude/review-approved-${REPO_HASH}`）

### PR Creation Gate (PreToolUse Hook)

`check-pr-review-gate.sh` はPreToolUseフックとして動作し、`gh pr create` コマンドのみをゲートします。

**動作**:
- `gh pr create` 実行時にレビュー承認フラグ（`/tmp/claude/review-approved-${REPO_HASH}`）を確認
- フラグが存在すればPR作成を許可し、フラグを消費（ワンタイムユース）
- フラグが存在しなければPR作成をブロック（exit 2）
- `# skip-review` コメントでバイパス可能
- `git commit` やその他のコマンドには影響しない

### 無限ループ防止

最大5回のレビュー反復。5回の反復後も問題が残る場合：
- ユーザーに警告を表示
- コミットは許可（警告付き）
- 想定: エッジケース、手動レビューが必要

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
plugins/code/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata
├── commands/
│   ├── review-commit.md       # Commit review command
│   ├── pr-review-team.md      # PR team review command
│   ├── refactor-team.md       # Refactoring team command
│   └── trufflehog-scan.md     # Security scan command
├── skills/
│   ├── review-commit/
│   │   ├── SKILL.md           # Review skill definition
│   │   └── references/
│   │       └── review-criteria.md
│   ├── pr-review-team/
│   │   ├── SKILL.md           # PR review team skill
│   │   └── references/
│   │       ├── ci-integration.md
│   │       └── security-checklist.md
│   └── refactor-team/
│       ├── SKILL.md           # Refactoring team skill
│       └── references/
│           └── analysis-criteria.md
├── scripts/
│   ├── check-pr-review-gate.sh      # PreToolUse hook (checks review flag)
│   └── enforce-code-review-rules.sh # UserPromptSubmit hook (enforces review policy)
├── tests/
│   ├── check-code-review.bats       # PR review gate hook tests (BATS)
│   └── validate-skills.bats         # Structural validation tests (BATS)
├── hooks/
│   └── hooks.json            # Optional hook configuration
├── .claude/
│   └── settings.json         # Permissions
├── README.md                 # This file
└── LICENSE                   # MIT License
```

## Troubleshooting

### "Code Review Required"

`gh pr create` がブロックされた場合、`/code:review-commit` を実行してレビューを完了してください。

### "Review completed with warnings"

Maximum review iterations (5) reached. Issues remain but commit is allowed.
Consider manual review of the warnings.

### Hook not working

1. Ensure jq is installed: `brew install jq`
2. Verify hook path in settings.json
3. Check script permissions: `chmod +x scripts/*.sh`

## License

MIT License - see [LICENSE](./LICENSE)
