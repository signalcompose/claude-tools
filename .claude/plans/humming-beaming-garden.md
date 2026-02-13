# fixerエージェントのコミット問題への対処

## Context

### 問題の背景

現在の`/code:review-commit`ワークフローでは、fixerエージェントがコミットする際に問題が発生します：

**現在の動作**:
1. ユーザーが`/code:review-commit`を実行
2. reviewerが問題を発見
3. **fixerが修正してコミットしようとする**
4. PreToolUseフック（`check-code-review.sh`）がコミットをブロック（レビュー承認フラグなし）
5. **デッドロック発生**（fixerはレビュー承認フラグを作成できない）

**ユーザーのワークフロー**:
- **feature ブランチ**: 主な開発場所（コードを変更する場所）
- **main/develop**: 直プッシュ禁止（緊急時を除く）、PRでのみマージ
- **レビューチーム**: fixerエージェントがレビュー反復中に修正をコミット

### Codex調査結果

業界標準のベストプラクティス：

1. **Pre-commitフックを全ブランチに適用**: feature, main, develop すべて
2. **自動fixerエージェントのコミット**: 通常のコミットと同じ検証を受けるべき
3. **ブランチ保護**: GitHubのブランチ保護ルールで main/develop を保護（サーバーサイド）
4. **フックバイパス**: feature ブランチでの `--no-verify` は反復中に許容（PR レビュー + CI が安全網）
5. **反復的レビュー**: 各コミットが同じ pre-commit 検証を通過

### 意図する結果

- fixerエージェントがレビュー中にコミットできる
- コード品質を維持（PRレビュー + CI）
- 業界標準のベストプラクティスに準拠
- シンプルで保守しやすい実装

## 実装アプローチ

### 推奨: Option C - Context-Aware Hook with Team Detection

**核心原理**: PreToolUseフックがレビューチームのコンテキストを検出し、fixerエージェントのコミットを自動承認する。

**検出戦略**: 多層コンテキスト検出

```bash
# Layer 1: review-in-progressマーカー
REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"

# Layer 2: エージェントロール（環境変数）
CLAUDE_AGENT_ROLE="${CLAUDE_AGENT_ROLE:-}"

# Layer 3: 決定ロジック
IF review_flag_exists:
  → ALLOW (フラグ削除、コミット許可)
ELIF review_in_progress AND agent_role="fixer":
  → ALLOW (fixer作業中、レビュー進行中)
ELIF review_in_progress AND NOT agent_role="fixer":
  → BLOCK (レビュー中の手動コミット不可)
ELSE:
  → BLOCK (レビュー未完了、指示表示)
```

**セキュリティ考慮**:
- マーカータイムアウト（1時間）: 古いマーカーの自動クリーンアップ
- PR レビュー + CI: 最終的な安全網
- クライアントサイドフック: 常に `--no-verify` でバイパス可能（緊急時用）

## 実装手順

### Phase 1: review-in-progressマーカーの追加

**ファイル**: `plugins/code/skills/review-commit/SKILL.md`

**変更箇所**: Step 3（反復レビューループ）の前に追加

```markdown
## Step 3: Create Review-In-Progress Marker

**Execute before starting review loop**:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"

mkdir -p /tmp/claude
touch "$REVIEW_MARKER"
echo "Review started at $(date)" > "$REVIEW_MARKER"
```

This marker signals to the pre-commit hook that a review team is actively working.
```

**変更箇所**: Step 4（承認フラグ作成）の後に追加

```markdown
**After creating approval flag, remove review-in-progress marker**:

```bash
# Remove review-in-progress marker (review complete)
rm -f "$REVIEW_MARKER"
```
```

### Phase 2: check-code-review.shの論理修正

**ファイル**: `plugins/code/scripts/check-code-review.sh`

**変更箇所**: Line 43の後（フラグチェックの前）に以下を追加

```bash
# Calculate review-in-progress marker path
REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"

# Detect agent role (set by Team Lead when spawning agents)
AGENT_ROLE="${CLAUDE_AGENT_ROLE:-}"

# Safety: Check review marker age (prevent stale markers)
if [[ -f "$REVIEW_MARKER" ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS
        MARKER_AGE=$(($(date +%s) - $(stat -f %m "$REVIEW_MARKER")))
    else
        # Linux
        MARKER_AGE=$(($(date +%s) - $(stat -c %Y "$REVIEW_MARKER")))
    fi
    MAX_AGE=$((60 * 60))  # 1 hour

    if [[ $MARKER_AGE -gt $MAX_AGE ]]; then
        echo "⚠️  Review marker is stale (${MARKER_AGE}s old), removing..." >&2
        rm -f "$REVIEW_MARKER"
    fi
fi

# Detect fixer agent commits during active review
if [[ -f "$REVIEW_MARKER" ]]; then
    # Review is in progress
    if [[ "$AGENT_ROLE" == "fixer" || "$AGENT_ROLE" == "code-fixer" ]]; then
        # Fixer agent committing during review - allow
        echo "📝 Review in progress: allowing fixer agent commit" >&2
        exit 0
    else
        # Manual commit during review - block
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "⛔ Review In Progress - Manual Commits Blocked" >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        echo "" >&2
        echo "A code review is currently in progress." >&2
        echo "Please wait for the review team to complete." >&2
        echo "" >&2
        echo "The fixer agent is working on resolving issues." >&2
        echo "Manual commits during review could cause conflicts." >&2
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
        exit 2
    fi
fi
```

### Phase 3: エージェントロール環境変数の設定

**ファイル**: `plugins/code/skills/review-commit/SKILL.md`

**変更箇所**: Step 2（レビューチーム作成）を更新

```markdown
## Step 2: Create Review Team

**MANDATORY**: Spawn a review team with the Task tool.

**Fixer Agent Configuration**:
Set environment variable `CLAUDE_AGENT_ROLE=fixer` when spawning the fixer agent:

```python
# Example (pseudocode)
Task(
  subagent_type="general-purpose",
  name="fixer",
  env={"CLAUDE_AGENT_ROLE": "fixer"},  # ← Key configuration
  prompt="Fix all Critical and Important issues..."
)
```

This allows the pre-commit hook to identify fixer agent commits.

Team structure:
```
Team Lead (yourself)
├─ Reviewer (code-reviewer agent)
└─ Fixer (general-purpose agent, with CLAUDE_AGENT_ROLE=fixer)
```
```

**注**: Task toolが環境変数をサポートしていない場合、fixerエージェントのプロンプトに以下を追加：

```markdown
**Before committing, set the environment variable**:
```bash
export CLAUDE_AGENT_ROLE=fixer
git commit -m "fix(review): resolve issue #1"
```
```

### Phase 4: スキル完了ロジックの更新

**ファイル**: `plugins/code/skills/review-commit/SKILL.md`

**変更箇所**: Step 5（シャットダウン）の前に追加

```markdown
## Step 5: Cleanup

**Execute after approval flag creation**:

```bash
# Remove review-in-progress marker
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_HASH=$(echo "$REPO_ROOT" | shasum -a 256 | cut -c1-16)
REVIEW_MARKER="/tmp/claude/review-in-progress-${REPO_HASH}"
rm -f "$REVIEW_MARKER"

# Unset agent role (if set via environment)
unset CLAUDE_AGENT_ROLE
```
```

### Phase 5: ドキュメント更新

**ファイル**: `plugins/code/README.md`

**追加箇所**: "Usage" セクションに以下を追加

```markdown
### Fixer Agent Commits

During the review process, the fixer agent may commit multiple times to resolve issues:

1. **Review-in-progress marker** created at start
2. Fixer agent identified via `CLAUDE_AGENT_ROLE=fixer` environment variable
3. Fixer commits automatically allowed (pre-commit hook detects review context)
4. Each fix triggers re-review until quality standards met
5. Marker removed after final approval

**Safety measures**:
- Marker auto-expires after 1 hour (stale review cleanup)
- PR review + CI provide final quality gates
- GitHub branch protection enforces merge requirements
```

## Critical Files

### 変更するファイル

1. **`plugins/code/scripts/check-code-review.sh`**
   - review-in-progress検出ロジック追加
   - エージェントロール検出追加
   - 古いマーカークリーンアップ追加

2. **`plugins/code/skills/review-commit/SKILL.md`**
   - review-in-progressマーカー作成/削除
   - エージェントロール設定の説明
   - クリーンアップステップ追加

3. **`plugins/code/README.md`**
   - fixerエージェントコミット動作の説明追加

## Verification

### テスト手順

**Test 1: 通常のコミット（レビューなし）**
```bash
echo "test" >> test.txt
git add test.txt
git commit -m "test: manual commit"
# 期待: BLOCKED（フラグなし、マーカーなし）
```

**Test 2: レビュー中の手動コミット**
```bash
# レビュー開始（マーカー作成）
touch /tmp/claude/review-in-progress-${REPO_HASH}

echo "test" >> test.txt
git add test.txt
git commit -m "test: manual commit"
# 期待: BLOCKED（マーカー存在、fixerロールなし）
```

**Test 3: レビュー中のfixerコミット**
```bash
# レビュー開始
touch /tmp/claude/review-in-progress-${REPO_HASH}

# fixerロール設定
export CLAUDE_AGENT_ROLE=fixer

echo "fixed" >> test.txt
git add test.txt
git commit -m "fix(review): resolve issue"
# 期待: ALLOWED（マーカー存在、fixerロール検出）
```

**Test 4: レビュー完了後のコミット**
```bash
# レビュー完了（承認フラグ作成、マーカー削除）
touch /tmp/claude/review-approved-${REPO_HASH}
rm -f /tmp/claude/review-in-progress-${REPO_HASH}

echo "feature" >> test.txt
git add test.txt
git commit -m "feat: new feature"
# 期待: ALLOWED（フラグ消費）
```

**Test 5: 古いマーカークリーンアップ**
```bash
# 1時間以上前のマーカー作成
touch -t 202601010000 /tmp/claude/review-in-progress-${REPO_HASH}

echo "test" >> test.txt
git add test.txt
git commit -m "test: commit"
# 期待: BLOCKED（マーカー削除、通常ブロック）
```

**Test 6: 完全なレビューワークフロー**
```bash
# 1. 変更作成
echo "new feature" >> src/app.ts
git add src/app.ts

# 2. レビュー実行
/code:review-commit
# - review-in-progressマーカー作成
# - reviewer + fixer起動
# - fixerがコミット（自動許可）
# - 承認フラグ作成
# - マーカー削除

# 3. コミット
git commit -m "feat: new feature"
# 期待: ALLOWED（フラグ消費）
```

### 緊急時のバイパス

```bash
# フックをバイパス（緊急修正時のみ）
git commit --no-verify -m "hotfix: critical production issue"
# 期待: ALLOWED（フックバイパス）
# 注: GitHub branch protectionで保護されたブランチへのプッシュは依然としてブロックされる
```

## ロールバック計画

実装に問題が発生した場合：

1. **check-code-review.sh を元に戻す**: 元のブロック動作を復元
2. **SKILL.md を元に戻す**: マーカー作成ロジックを削除
3. **手動クリーンアップ**: `rm -f /tmp/claude/review-in-progress-*`

**フォールバック設定**:
```bash
# コードレビューフックを一時的に無効化
SKIP_CODE_REVIEW=1 git commit -m "message"
```

## 実装後のタスク

### 完了後

1. テスト環境で全6テストケースを実施
2. 完全なレビューワークフローを実行して動作確認
3. ドキュメント更新を確認
4. プラグインキャッシュクリア + Claude Code再起動

### 成功時

1. Serenaメモリを更新（解決策の記録）
2. CLAUDE.mdにフックバイパスポリシーを追記（任意）

### 失敗時

1. ロールバック計画を実行
2. 失敗原因を分析・記録
3. 代替アプローチ（Option BまたはOption A）を検討
