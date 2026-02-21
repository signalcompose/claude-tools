# code - Claude Code Plugin

Code quality tools and autonomous development lifecycle for Claude Code.

## Features

- **Dev Cycle**: 自律型の開発ライフサイクル（実装→監査→PR作成→振り返り）を1コマンドで実行
- **Sprint Implementation**: 並列チームエージェントによる計画駆動の実装スプリント
- **Compliance Audit**: DDD/TDD/DRY/ISSUE/PROCESS の5原則コンプライアンス監査
- **Team-based Code Review**: 反復的、自動修正レビューループ
- **Shipping PR**: コードレビュー＋修正ループ＋PR作成を自律実行
- **Retrospective**: 2エージェント並列分析（監査＋研究）による振り返り
- **PR Team Review**: 4つの専門エージェントによる並行PRレビュー + CI統合
- **Refactoring Team**: 分析→ユーザー承認→実行のリファクタリングワークフロー
- **Quality Assurance**: critical/important問題の完全解決を保証
- **PR Creation Gate**: PR作成前にレビュー実行をチェック（PreToolUseフック）
- **Dev Environment Setup**: 7項目の環境チェック＋自動修正

## Requirements

- macOS or Linux
- Node.js >= 20.0.0
- Git installed and configured
- GitHub MCP Server (required for dev-cycle workflows)
- jq (optional, for better JSON parsing in hooks)

## Installation

```
/plugin marketplace add signalcompose/claude-tools
/plugin install code@claude-tools
```

## Commands & Skills

### Dev Cycle（自律開発ライフサイクル）

| Command/Skill | Description |
|---------------|-------------|
| `/code:dev-cycle` | 全サイクル自律実行（sprint → audit → ship → retrospective） |
| `/code:sprint-impl` | 計画駆動の実装スプリント（並列チームエージェント） |
| `/code:audit-compliance` | 5原則コンプライアンス監査 |
| `/code:shipping-pr` | コードレビュー＋修正ループ＋コミット＋PR作成 |
| `/code:retrospective` | 2エージェント並列分析による振り返り |
| `/code:setup-dev-env` | 開発環境チェック（7項目）＋自動修正 |

### Code Quality（コード品質）

| Command/Skill | Description |
|---------------|-------------|
| `/code:review-commit` | Review staged changes and approve for commit |
| `/code:pr-review-team` | Team-based PR review with specialized agents |
| `/code:refactor-team` | Team-based code refactoring with analysis |
| `/code:trufflehog-scan` | Run TruffleHog security scan on current project |

## Usage

### Dev Cycle（全サイクル実行）

```
/code:dev-cycle docs/plans/phase-3-plan.md
```

4つのステージを自律的に連続実行:

1. **Sprint**: プラン解析→Issue作成→仕様書作成→並列チーム実装→テスト→ビルド検証
2. **Audit**: DDD/TDD/DRY/ISSUE/PROCESS の5原則監査
3. **Ship**: コードレビュー（自動修正ループ）→コミット→Push→PR作成
4. **Retrospective**: 2エージェント並列分析→改善適用→メトリクス記録

入力ソース:
- プランファイルパス: `docs/plans/phase-3-plan.md`
- GitHub Issue URL: `https://github.com/owner/repo/issues/42`
- インライン説明: `ユーザー認証機能を追加する`
- 空（`docs/plans/` から次のフェーズを自動検出）

**詳細ガイド**: [Dev Cycle Guide](../../docs/dev-cycle-guide.md)

### 個別ステージの実行

```bash
# 実装スプリントのみ
/code:sprint-impl docs/plans/phase-3-plan.md

# 監査のみ
/code:audit-compliance

# PR作成のみ
/code:shipping-pr

# 振り返りのみ
/code:retrospective
```

### 環境セットアップ

```bash
# チェックのみ
/code:setup-dev-env

# 自動修正付き
/code:setup-dev-env --fix
```

7項目をチェック: Node.js、依存パッケージ、ビルド、Git状態、GitHub MCP、コードレビュースキル、パーミッション

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

### 無限ループ防止（review-commit）

`/code:review-commit` は最大5回のレビュー反復（`/code:shipping-pr` のレビューループは最大3回）。5回の反復後も問題が残る場合：
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
│   └── plugin.json              # Plugin metadata
├── commands/
│   ├── dev-cycle.md             # Dev cycle command
│   ├── sprint-impl.md           # Sprint implementation command
│   ├── audit-compliance.md      # Compliance audit command
│   ├── shipping-pr.md           # Shipping PR command
│   ├── retrospective.md         # Retrospective command
│   ├── setup-dev-env.md         # Dev environment setup command
│   ├── review-commit.md         # Commit review command
│   ├── pr-review-team.md        # PR team review command
│   ├── refactor-team.md         # Refactoring team command
│   └── trufflehog-scan.md       # Security scan command
├── skills/
│   ├── dev-cycle/
│   │   ├── SKILL.md             # Dev cycle orchestration skill
│   │   └── references/
│   │       ├── main-agent-guide.md
│   │       ├── prohibitions.md
│   │       └── package-security-audit.md
│   ├── sprint-impl/
│   │   ├── SKILL.md             # Sprint implementation skill
│   │   └── references/
│   │       └── agent-prompt-template.md
│   ├── audit-compliance/
│   │   ├── SKILL.md             # Compliance audit skill
│   │   └── templates/
│   │       └── audit-report.md
│   ├── shipping-pr/
│   │   ├── SKILL.md             # Shipping PR skill
│   │   └── templates/
│   │       ├── commit-format.md
│   │       └── pr-body.md
│   ├── retrospective/
│   │   ├── SKILL.md             # Retrospective skill
│   │   └── references/
│   │       ├── auditor-prompt.md
│   │       ├── learnings-pdca.md    # Learnings PDCA procedures
│   │       └── researcher-prompt.md
│   ├── setup-dev-env/
│   │   ├── SKILL.md             # Dev environment setup skill
│   │   └── references/
│   │       ├── expected-permissions.md
│   │       └── github-mcp-guide.md
│   ├── review-commit/
│   │   ├── SKILL.md             # Review skill definition
│   │   └── references/
│   │       └── review-criteria.md
│   ├── pr-review-team/
│   │   ├── SKILL.md             # PR review team skill
│   │   └── references/
│   │       ├── ci-integration.md
│   │       └── security-checklist.md
│   ├── refactor-team/
│   │   ├── SKILL.md             # Refactoring team skill
│   │   └── references/
│   │       └── analysis-criteria.md
│   └── _shared/
│       ├── output-rules.md      # Shared output formatting rules
│       └── serena-integration.md # Context saving patterns
├── scripts/
│   ├── check-pr-review-gate.sh       # PreToolUse hook
│   ├── dev-cycle-guard.sh            # UserPromptSubmit hook (dev-cycle reminder)
│   ├── dev-cycle-stop.sh             # Stop hook (auto-chain stages)
│   ├── enforce-code-review-rules.sh  # UserPromptSubmit hook
│   └── validate-audit-metrics.sh     # Audit metrics validation
├── tests/
│   ├── check-code-review.bats       # PR review gate hook tests (BATS)
│   └── validate-skills.bats         # Structural validation tests (BATS)
├── hooks/
│   └── hooks.json            # Hook configuration
├── .claude/
│   └── settings.json         # Plugin permissions
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

### Dev Cycle が途中で停止した

`.claude/dev-cycle.state.json` を確認し、該当ステージのスキルを直接実行:

```bash
# 状態確認
cat .claude/dev-cycle.state.json

# 例: audit ステージから再開
/code:audit-compliance
```

### Setup check で FAIL が出る

```bash
# 自動修正を試す
/code:setup-dev-env --fix
```

自動修正できない項目（GitHub MCP等）は、表示されるガイダンスに従って手動で設定してください。

## License

MIT License - see [LICENSE](./LICENSE)
