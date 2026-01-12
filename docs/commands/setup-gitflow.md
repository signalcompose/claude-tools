# Git Flow Setup Command

このプロジェクトにGit Flowワークフローを設定します。

## 実行内容

以下の手順を自動的に実行します：

1. **リポジトリ登録チェック**
   - GitHubリポジトリに登録されているか確認
   - 未登録の場合、リポジトリを作成

2. **ブランチ構成**
   - `main`ブランチ（本番用）
   - `develop`ブランチ（開発用、デフォルト）

3. **ブランチ保護**
   - mainブランチへの直プッシュを禁止
   - Pull Requestによるマージのみ許可

4. **セキュリティ設定**
   - フォークからのPRでworkflow実行に承認を必須化
   - CODEOWNERSファイル作成
   - Secretsへのアクセス制限
   - 自動マージ無効化

5. **レビュー設定**
   - 開発体制に応じたレビュワー数設定

---

## 手順

### STEP 0: プロジェクトタイプの確認

まず、ユーザーにプロジェクトタイプを質問し、適切なセキュリティ設定を推奨します。

**質問**: このプロジェクトはどのタイプですか？

1. **個人プロジェクト（フォーク受け入れなし）**
   - 一人で開発
   - 外部からのコントリビューションを受け付けない

2. **小規模OSS（信頼できるコントリビューター中心）**
   - 少数の信頼できるコントリビューター
   - フォークからのPRを受け入れる

3. **大規模OSS / セキュリティクリティカル**
   - 多数の外部コントリビューター
   - CI/CDでsecretsを使用
   - セキュリティが重要

#### プロジェクトタイプ別の推奨設定

| 設定項目 | 個人 | 小規模OSS | 大規模OSS |
|---------|------|-----------|-----------|
| **リポジトリ可視性** | Private | Public | Public |
| **Secret Scanning** | ❌ 不要 | ✅ 推奨 | ✅ 必須 |
| **CODEOWNERS** | ❌ 不要 | ✅ 推奨 | ✅ 必須 |
| **developブランチ保護** | ⚠️ 任意 | ✅ 推奨 | ✅ 必須 |
| **enforce_admins** | false | false | true/false |
| **フォークPR制限** | ❌ 不要 | ⚠️ 任意 | ✅ 推奨 |
| **自動マージ無効** | ❌ 不要 | ❌ 不要 | ⚠️ 任意 |

**重要**:
- **Secret Scanning**はPublicリポジトリでのみ無料で利用可能
- **個人プロジェクト（Private）**: 最小限の設定で十分
- **OSS（Public）**: CODEOWNERS + Secret Scanningを推奨
- **大規模OSS**: 全ての設定を有効化することを推奨

**ブランチ保護の推奨設定**:
- `enforce_admins=false`: 管理者はレビューなしでマージ可能（柔軟性重視、推奨）
- `enforce_admins=true`: 管理者も含めて全員がレビュー必須（厳格性重視）

ユーザーの選択に応じて、推奨設定を提案し、個別にカスタマイズできるようにします。

---

### STEP 1: リポジトリ登録確認

まず、現在のプロジェクトがGitHubリポジトリに登録されているか確認します。

```bash
# リモートリポジトリの確認
git remote -v

# GitHubリポジトリ情報の取得
gh repo view --json nameWithOwner,isPrivate 2>/dev/null
```

**既存リポジトリが見つかった場合**:
- ユーザーに確認し、既存設定を上書きするかスキップするか選択

**リポジトリが未登録の場合**:
- 次のステップに進む

---

### STEP 2: リポジトリ作成（未登録の場合のみ）

#### 2.1 ユーザー/組織の確認

```bash
# 現在のGitHubユーザーを確認
gh auth status

# 所属組織を確認
gh api user/orgs --jq '.[].login'
```

#### 2.2 リポジトリ情報の収集

以下の情報をユーザーに確認：
- **リポジトリ名**: デフォルトはディレクトリ名
- **可視性**:
  - **Private**: 個人プロジェクト、非公開開発（推奨）
  - **Public**: OSSプロジェクト、外部コントリビューション受け入れ
- **作成先**: 個人アカウントまたは組織

#### 2.3 リポジトリ作成

```bash
# Gitリポジトリ初期化（未初期化の場合）
if [ ! -d .git ]; then
  git init
  git add .
  git commit -m "Initial commit"
fi

# GitHubリポジトリ作成
gh repo create <REPO_NAME> --private --source=. --remote=origin --push
```

---

### STEP 3: ブランチ構成

#### 3.1 developブランチ作成

```bash
# mainブランチが存在することを確認
git checkout -b main 2>/dev/null || git checkout main

# 初回コミット（まだない場合）
if [ -z "$(git log -1 2>/dev/null)" ]; then
  echo "# $(basename $(pwd))" > README.md
  git add README.md
  git commit -m "Initial commit"
  git push -u origin main
fi

# developブランチ作成
git checkout -b develop
git push -u origin develop
```

#### 3.2 デフォルトブランチ変更

```bash
# developをデフォルトブランチに設定
gh repo edit --default-branch develop
```

---

### STEP 4: ブランチ保護設定

#### 4.1 開発体制の確認とレビュー設定

ユーザーに開発体制を確認：

**一人開発（Solo Development）の推奨設定**:
- `enforce_admins: false` - 管理者バイパス可能
- `required_approving_review_count: 1` - セルフレビュー推奨（バイパス可能）
- `required_linear_history: false` - **Git Flow対応（マージコミット許可）**

**チーム開発（Team Development）の推奨設定**:
- `enforce_admins: true` - 管理者も含めて全員ルール適用
- `required_approving_review_count: 1` - 最低1人のレビュー必須
- `required_linear_history: false` - **Git Flow対応（マージコミット許可）**

#### 4.2 段階的移行の考え方

**現在と将来を見据えた設定**:

1. **ソロ開発フェーズ（初期）**
   - レビュー設定: `required_approving_review_count: 1`
   - Admin権限: `enforce_admins: false`でバイパス可能
   - 効果: Adminはレビューなしでマージ可能、柔軟な開発

2. **チーム参加時（移行期）**
   - 設定変更なしで新メンバーは自動的にレビュー必須
   - Admin以外: 1名の承認が必要
   - Admin: 引き続きバイパス可能

3. **完全チーム開発（最終形）**
   - `enforce_admins: true`に変更
   - 全員（Adminを含む）がレビュー必須
   - より厳格なコード品質管理

**🚨 重要: required_linear_history について**

- ❌ **`required_linear_history: true` は Git Flow と互換性がありません**
  - Squashマージまたはrebaseマージのみ許可
  - マージコミットが禁止される
  - develop→mainのマージでコンフリクトが発生
  - Git Flowの履歴が破壊される

- ✅ **`required_linear_history: false` を必ず使用**
  - マージコミット（Create a merge commit）を許可
  - Git Flowの履歴を保持
  - develop と main の分岐を正しく管理

#### 4.3 mainブランチ保護

**一人開発の場合**:
```bash
# mainブランチ保護設定
gh api repos/:owner/:repo/branches/main/protection -X PUT --input - <<EOF
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false
}
EOF
```

**チーム開発の場合**:
```bash
# mainブランチ保護設定
gh api repos/:owner/:repo/branches/main/protection -X PUT --input - <<EOF
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false
}
EOF
```

#### 4.4 developブランチ保護

**一人開発の場合**:
```bash
# developブランチ保護設定（mainと同じ設定）
gh api repos/:owner/:repo/branches/develop/protection -X PUT --input - <<EOF
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false
}
EOF
```

**チーム開発の場合**:
```bash
# developブランチ保護設定（mainと同じ設定）
gh api repos/:owner/:repo/branches/develop/protection -X PUT --input - <<EOF
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "required_linear_history": false,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "block_creations": false,
  "required_conversation_resolution": false
}
EOF
```

**注**: main/develop両方に同じレビュー設定を適用することで、一貫性のある開発フローを実現します。

#### 4.5 リポジトリレベルのマージ設定（必須）

**⚠️ 重要**: ブランチ保護だけでなく、リポジトリレベルでもSquashマージを無効化

```bash
# Squashマージとリベースマージを無効化
gh api repos/:owner/:repo \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -f allow_squash_merge=false \
  -f allow_rebase_merge=false
```

**理由**:
- ブランチ保護（`required_linear_history`）は「履歴を直線にするか」の設定
- リポジトリ設定（`allow_squash_merge`）は「どのマージ方法を許可するか」の設定
- 両方設定しないと、PRマージ時にSquashが選択できてしまう
- **Git Flowでは必ずマージコミットのみ許可する**

**Git Flowベストプラクティス**:
- main/develop両方を保護することで、誤った直プッシュを防ぎます
- 両ブランチで `required_linear_history: false` を設定し、マージコミットを許可
- リポジトリレベルでSquash/Rebaseマージを無効化し、マージコミットのみ許可

**🚨 Git Workflow 絶対禁止事項**:
- ❌ **main → develop への逆流**（最重要）
- ❌ **main・developブランチへの直接コミット**
- ❌ **Squashマージ**（Git Flow履歴が破壊される）
- ❌ **ISSUE番号のないブランチ名**

**重要**: developからmainへの直接PRは**リリース時のみ許可**。
逆方向（main → develop）は**絶対禁止**。

---

### STEP 5: セキュリティ設定

ユーザーが選択したプロジェクトタイプに応じて、以下のセキュリティ設定を適用します。

**適用する設定**:
- STEP 0で選択したプロジェクトタイプに基づく推奨設定
- ユーザーが個別にカスタマイズ可能

---

#### 5.1 フォークPR制限（小規模OSS/大規模OSSの場合）

```bash
# Actions設定: フォークPRでの承認を必須化
gh api repos/:owner/:repo/actions/permissions \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -f enabled=true \
  -f allowed_actions=all

gh api repos/:owner/:repo \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -f allow_forking=true \
  -f allow_auto_merge=false
```

#### 5.2 CODEOWNERS作成（小規模OSS/大規模OSSの場合）

```bash
# .github/CODEOWNERSファイル作成
mkdir -p .github
cat > .github/CODEOWNERS <<'EOF'
# CODEOWNERS
# 重要ファイルの変更には承認が必要

# グローバル設定
* @<OWNER>

# GitHub設定ファイル
/.github/ @<OWNER>

# CI/CD設定
/.github/workflows/ @<OWNER>

# 依存関係
/package.json @<OWNER>
/package-lock.json @<OWNER>
/go.mod @<OWNER>
/go.sum @<OWNER>
/requirements.txt @<OWNER>
/Pipfile @<OWNER>
/Gemfile @<OWNER>

# セキュリティ設定
/.gitignore @<OWNER>
EOF

git add .github/CODEOWNERS
git commit -m "Add CODEOWNERS for security"
git push
```

**注**: `<OWNER>`はリポジトリオーナーのGitHubユーザー名に置き換えます。

#### 5.3 Secret Scanning有効化（全プロジェクト推奨）

**Public リポジトリの場合のみ設定可能**:

```bash
# Secret Scanningを有効化（Publicリポジトリのみ）
gh api repos/:owner/:repo \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -f security_and_analysis='{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}'
```

**注意**:
- Secret Scanningは**Publicリポジトリでのみ無料**で利用可能
- Privateリポジトリでは有料プラン（GitHub Advanced Security）が必要
- Push Protectionを有効にすることで、秘密情報の誤コミットを防止

#### 5.4 フォークPR Workflow制限（組織リポジトリの場合）

**重要**: この設定は組織レベルの設定で、リポジトリAPIでは設定できません。

組織の管理者に以下の設定を依頼してください：
1. 組織の **Settings** > **Actions** > **General**
2. **Fork pull request workflows from outside collaborators** セクション
3. ☑ **"Require approval for all outside collaborators"** を選択

これにより、フォークからのPRでWorkflowを実行する前に承認が必要になります。

**個人リポジトリの場合**: この設定は不要です（フォークPRはデフォルトでSecretにアクセスできません）

#### 5.5 自動マージ無効化（大規模OSSの場合のみ）

```bash
# 自動マージを無効化
gh api repos/:owner/:repo \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -f allow_auto_merge=false
```

---

### STEP 6: 確認

セットアップ完了後、以下を確認：

```bash
# ブランチ確認
git branch -a

# デフォルトブランチ確認
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'

# ブランチ保護確認
gh api repos/:owner/:repo/branches/main/protection

# マージ設定確認
gh api repos/:owner/:repo --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge}'

# リポジトリ設定確認
gh repo view --json allowAutoMerge,allowForking
```

---

## 完了メッセージ

セットアップが完了したら、以下の情報を表示：

```
✅ Git Flowセットアップ完了

【ブランチ構成】
- main: 本番環境用（保護済み）
- develop: 開発環境用（デフォルト、保護済み）

【ブランチ保護】
- main/developへの直プッシュ禁止
- Pull Requestによるマージのみ許可
- マージコミット必須（Squashマージ禁止）
- レビュー設定: 1名の承認必要
- 管理者権限:
  - Solo開発: Adminはレビューをバイパス可能（柔軟性重視）
  - Team開発: 全員がレビュー必須（厳格性重視）
- required_linear_history: false（Git Flow対応）

【段階的移行サポート】
- 現在: ソロ開発でも将来を見据えた設定
- 将来: チーム参加時に自動的にレビュー適用
- 移行時: `enforce_admins`を変更するだけで完全移行

【マージ設定】
- allow_squash_merge: false（Squashマージ無効）
- allow_rebase_merge: false（Rebaseマージ無効）
- allow_merge_commit: true（マージコミットのみ許可）

【セキュリティ設定】
<適用された設定をリスト表示>
例:
✓ CODEOWNERS設定（重要ファイルの保護）
✓ Secret Scanning有効化（Publicリポジトリのみ）
✓ Secret Scanning Push Protection有効化
✓ フォーク許可: 有効（OSS協業可能）
✓ 自動マージ: 無効（大規模OSSの場合）
（その他、プロジェクトタイプに応じて表示）

【🚨 Git Workflow 絶対禁止事項】
❌ main → develop への逆流（最重要）
❌ main・developブランチへの直接コミット
❌ Squashマージ（Git Flow履歴が破壊される）
❌ ISSUE番号のないブランチ名

【次のステップ】
1. 新機能開発: `git checkout -b feature/<機能名>` from develop
2. 変更をコミット & プッシュ
3. Pull Requestを作成（develop ← feature）
4. レビュー後、developにマージ（**マージコミット使用**）
5. 本番リリース時: Pull Requestを作成（main ← develop）← **直接PRでOK**
6. リリース後、タグ付け: `git tag v1.0.0`

【重要】
- developからmainへの直接PRは**リリース時のみ許可**
- 逆方向（main → develop）は**絶対禁止**
- マージ時は必ず「Create a merge commit」を選択
```

---

## トラブルシューティング

### gh コマンドが見つからない

```bash
# GitHub CLIのインストール
brew install gh

# 認証
gh auth login
```

### ブランチ保護設定に失敗

- リポジトリのAdmin権限が必要です
- Organizationの場合、Organization設定で権限を確認してください

### CODEOWNERSが機能しない

- ブランチ保護設定で "Require review from Code Owners" を有効化してください
- Settings > Branches > Branch protection rules > main

---

## 参考資料

- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)
- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
