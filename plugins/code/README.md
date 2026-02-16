# code - Claude Code Plugin

Code quality tools for Claude Code: commit review, PR team review, and refactoring team.

## Features

- **Team-based Code Review**: 反復的、自動修正レビューループ
- **PR Team Review**: 4つの専門エージェントによる並行PRレビュー + CI統合
- **Refactoring Team**: 分析→ユーザー承認→実行のリファクタリングワークフロー
- **Quality Assurance**: critical/important問題の完全解決を保証
- **Pre-commit Hook**: レビュー実行をチェック（フラグベース）

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
5. Set approval flag for commit

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

従来のハッシュベース承認とは異なり、このアプローチは：
- ✅ **問題を修正**（フラグ立てるだけではない）
- ✅ **品質達成まで反復**
- ✅ **専門的レビューagentを使用**
- ✅ **ハッシュマッチングの複雑さなし**

### Fixer Agent Commits

レビュープロセス中、fixerエージェントは問題を解決するために複数回コミットする可能性があります：

1. **review-in-progressマーカー** をレビュー開始時に作成
2. Fixerエージェントはコミット前に **fixer-commitマーカー** を作成
3. Pre-commitフックがfixer-commitマーカーを検出してコミットを自動承認
4. フックがマーカーを自動削除（ワンタイムユース）
5. 各修正が再レビューをトリガーし、品質基準を満たすまで反復
6. 最終承認後にreview-in-progressマーカーを削除

**技術的詳細**:
- **マーカー方式を採用**: Git pre-commitフックは別プロセスで実行されるため、環境変数は使用不可
- **一時ファイルベース**: `/tmp/claude/fixer-commit-${REPO_HASH}` でfixerを識別
- **自動クリーンアップ**: フックがコミット時にマーカーを削除

**セキュリティ対策**:
- review-in-progressマーカーは1時間後に自動失効（古いレビューのクリーンアップ）
- fixer-commitマーカーはワンタイムユース（コミット後即削除）
- PR レビュー + CI が最終的な品質ゲート
- GitHub ブランチ保護がマージ要件を強制

### Pre-commit Hook

Pre-commit hookは単に`/code:review-commit`が実行されたかチェック（フラグファイル）。
ハッシュ検証不要—品質はレビューループで保証される。

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
│   ├── check-code-review.bats       # Hook behavior tests (BATS)
│   └── validate-skills.bats         # Structural validation tests (BATS)
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

### "Review completed with warnings"

Maximum review iterations (5) reached. Issues remain but commit is allowed.
Consider manual review of the warnings.

### Hook not working

1. Ensure jq is installed: `brew install jq`
2. Verify hook path in settings.json
3. Check script permissions: `chmod +x scripts/*.sh`

## License

MIT License - see [LICENSE](./LICENSE)
