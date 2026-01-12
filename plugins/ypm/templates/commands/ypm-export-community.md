# /ypm:export-community - Export Private Repository to Public Community Version

このコマンドは、privateリポジトリからpublicコミュニティ版へexportします。

初回実行時は対話形式でセットアップを行い、2回目以降は自動的にexportを実行します。

## あなたの役割

以下の手順を**厳密に**実行してください：

---

### STEP 0: 言語検出

ユーザーの最近のメッセージから使用言語を検出し、以降のAskUserQuestionで使用します。

**検出ルール**:
- ユーザーの直近のメッセージに日本語キーワード（「です」「ます」「を」「が」「は」「に」「の」等）が含まれる → **日本語**
- 上記以外（英語のみ） → **英語**
- デフォルト: **日本語**

検出した言語を内部メモし、以降のSTEP 3とSTEP 4-2のAskUserQuestionで使用してください。

---

### STEP 1: 現在のディレクトリとブランチを確認

```bash
pwd
git branch --show-current
```

現在のディレクトリを確認し、ユーザーに報告してください。

---

### STEP 2: 設定ファイルの存在チェック

```bash
ls -la .export-config.yml 2>/dev/null || echo "NOT_FOUND"
```

**判定**:
- `.export-config.yml`が**存在する** → **STEP 4へスキップ**
- `.export-config.yml`が**存在しない** → **STEP 3へ進む**

---

### STEP 3: インタラクティブセットアップ（初回のみ）

**AskUserQuestionツール**を使用して、以下の情報を収集してください：

#### Question 1: Repository Configuration

**STEP 0で検出した言語に応じて、以下のいずれかを使用してください**:

##### 日本語版

**質問内容**:
```
Private repositoryとPublic repositoryの設定を行います。
```

**選択肢**:
1. **Private repo path**:
   - Label: "現在のディレクトリを使用"
   - Description: "現在のディレクトリをprivate repoとして使用します ({{current_dir}})"

2. **Private repo path (custom)**:
   - Label: "カスタムパスを指定"
   - Description: "別のパスを指定します（例: Git worktreeのmainブランチ）"

3. **Public repo (new)**:
   - Label: "新規public repositoryを作成"
   - Description: "新しいpublic GitHubリポジトリを自動作成します"

4. **Public repo (existing)**:
   - Label: "既存のリポジトリを使用"
   - Description: "既存のpublic repository URLを指定します"

##### 英語版

**Question**:
```
Configure Private and Public repository settings.
```

**Options**:
1. **Private repo path**:
   - Label: "Use current directory"
   - Description: "Use current directory as private repo ({{current_dir}})"

2. **Private repo path (custom)**:
   - Label: "Specify custom path"
   - Description: "Specify different path (e.g., for Git worktree main branch)"

3. **Public repo (new)**:
   - Label: "Create new public repository"
   - Description: "Automatically create a new public GitHub repository"

4. **Public repo (existing)**:
   - Label: "Use existing repository"
   - Description: "Specify an existing public repository URL"

---

**収集する情報**:
- Private repo path（カレントディレクトリまたはカスタムパス）
- Public repo URL（新規作成の場合はowner/name、既存の場合はURL）

#### Question 2: Files to Exclude

**STEP 0で検出した言語に応じて、以下のいずれかを使用してください**:

##### 日本語版

**質問内容**:
```
Public版から除外するファイルを選択してください。
推奨される除外ファイルがデフォルトで選択されています。
```

**選択肢（multiSelect: true）**:
1. **CLAUDE.md**:
   - Label: "CLAUDE.md"
   - Description: "個人用Claude Code設定ファイル（推奨）"

2. **config.yml**:
   - Label: "config.yml"
   - Description: "ローカルパスを含む個人設定（推奨）"

3. **PROJECT_STATUS.md**:
   - Label: "PROJECT_STATUS.md"
   - Description: "個人のプロジェクト管理データ（推奨）"

4. **docs/research/**:
   - Label: "docs/research/"
   - Description: "内部リサーチドキュメント（推奨）"

5. **Additional files**:
   - Label: "その他のファイル"
   - Description: "追加の除外ファイルを次のステップで指定"

##### 英語版

**Question**:
```
Select files to exclude from public version.
Recommended exclusions are pre-selected.
```

**Options (multiSelect: true)**:
1. **CLAUDE.md**:
   - Label: "CLAUDE.md"
   - Description: "Personal Claude Code configuration (recommended)"

2. **config.yml**:
   - Label: "config.yml"
   - Description: "Personal configuration with local paths (recommended)"

3. **PROJECT_STATUS.md**:
   - Label: "PROJECT_STATUS.md"
   - Description: "Personal project management data (recommended)"

4. **docs/research/**:
   - Label: "docs/research/"
   - Description: "Internal research documents (recommended)"

5. **Additional files**:
   - Label: "Other files"
   - Description: "Specify additional files in the next step"

---

**追加除外ファイル**（Otherを選択した場合）:
- ユーザーに追加の除外ファイルをカンマ区切りで入力してもらう

#### Question 3: Commit Message Sanitization

**STEP 0で検出した言語に応じて、以下のいずれかを使用してください**:

##### 日本語版

**質問内容**:
```
コミットメッセージから削除したい機密キーワードがあれば指定してください。
（例: プロジェクト名、内部コードネーム等）
```

**選択肢**:
1. **No sanitization**:
   - Label: "スキップ"
   - Description: "サニタイズする機密キーワードはありません"

2. **Add keywords**:
   - Label: "キーワードを追加"
   - Description: "削除する機密キーワードを指定します"

##### 英語版

**Question**:
```
Specify sensitive keywords to remove from commit messages.
(e.g., project names, internal code names, etc.)
```

**Options**:
1. **No sanitization**:
   - Label: "Skip"
   - Description: "No sensitive keywords to sanitize"

2. **Add keywords**:
   - Label: "Add keywords"
   - Description: "Specify sensitive keywords to redact"

---

**収集する情報**:
- 機密キーワードのリスト（カンマ区切り）

---

#### STEP 3-2: .export-config.yml を作成

**重要**: データを正規化してから、YAMLを生成してください。

##### データ正規化

収集した情報を以下のように変換：

1. **Private repo path**:
   - 末尾のスラッシュを削除（あれば）
   - 例: `/path/to/repo/` → `/path/to/repo`

2. **Public repo URL**:
   - `owner/name`形式の場合 → `https://github.com/owner/name.git`に変換
   - 既に完全URLの場合 → そのまま使用
   - 例: `signalcompose/MaxMCP` → `https://github.com/signalcompose/MaxMCP.git`

##### YAML生成

**Writeツール**を使用して、正規化した情報から`.export-config.yml`を生成してください。

**フォーマット**:
```yaml
# Export Configuration for [プロジェクト名]
# Generated: [今日の日付: 2025-11-12]

export:
  # Private repository path (absolute path)
  private_repo: "[正規化したprivate_repo_path]"

  # Public repository URL
  public_repo_url: "[正規化したpublic_repo_url（完全URL形式）]"

  # Files and directories to exclude from export
  exclude_paths:
    - CLAUDE.md           # Personal configuration
    - config.yml          # Personal paths
    - PROJECT_STATUS.md   # Personal project data
    - docs/research/      # Internal research documents
    [追加の除外ファイルがあればここに追加]

  # Commit message sanitization patterns
  sanitize_patterns:
    [機密キーワードがある場合]
    - pattern: "[keyword1|keyword2|keyword3]"
      replace: "[redacted]"
    [機密キーワードがない場合]
    # No sanitization patterns specified
```

**作成後**:
- `.export-config.yml`が作成されたことをユーザーに報告
- 内容を確認してもらう
- **STEP 4へ進む**

---

### STEP 4: Export実行

**.export-config.yml**が存在する場合、以下を実行：

#### STEP 4-1: 設定内容の確認

```bash
yq eval '.export' .export-config.yml
```

設定内容をユーザーに提示してください。

#### STEP 4-2: Public Repository存在チェック

**Bash**で以下を実行：

```bash
REPO_NAME=$(yq eval '.export.public_repo_url' .export-config.yml | sed -E 's/.*github\.com[:/](.*)\.git/\1/')
ACTUAL_REPO=$(gh repo view "$REPO_NAME" --json name,owner --jq '"\(.owner.login)/\(.name)"' 2>/dev/null || echo "")

if [ -z "$ACTUAL_REPO" ] || [ "$ACTUAL_REPO" != "$REPO_NAME" ]; then
  echo "NEEDS_CREATE"
else
  echo "EXISTS"
fi
```

**結果に応じて分岐**:

---

##### A. リポジトリが存在しない場合（NEEDS_CREATE）

**AskUserQuestionツール**でリポジトリ作成を確認。**STEP 0で検出した言語に応じて、以下のいずれかを使用してください**:

###### 日本語版

**質問内容**:
```
Public repository '$REPO_NAME' が存在しません。
新規作成してexportを実行しますか？
```

**選択肢**:
1. **Yes, create and export**:
   - Label: "作成してexportを実行"
   - Description: "Public repositoryを自動作成し、mainブランチを初期化してからexportを実行します"

2. **No, cancel**:
   - Label: "キャンセル"
   - Description: "リポジトリを作成せずにキャンセルします"

###### 英語版

**Question**:
```
Public repository '$REPO_NAME' does not exist.
Create new repository and proceed with export?
```

**Options**:
1. **Yes, create and export**:
   - Label: "Create and export"
   - Description: "Automatically create public repository, initialize main branch, and execute export"

2. **No, cancel**:
   - Label: "Cancel"
   - Description: "Cancel without creating repository"

---

**ユーザーが "Yes" を選択**:
→ STEP 4-3へ進む（`AUTO_CREATE_REPO=yes`でスクリプト実行）

**ユーザーが "No" を選択**:
→ 終了、ユーザーに手動作成を案内

---

##### B. リポジトリが存在する場合（EXISTS）

ユーザーに以下を確認：
```
以下の設定でpublic版へexportします：

- Private repo: [private_repo の値]
- Public repo: [public_repo_url の値] (既存)
- 除外ファイル: [exclude_paths のリスト]

このexportを実行しますか？
```

**承認されたら** → STEP 4-3へ進む

---

#### STEP 4-3: スクリプト実行

**リポジトリが存在しない場合**（AUTO_CREATE_REPO=yes）:
```bash
AUTO_CREATE_REPO=yes ~/.claude/scripts/export-to-community.sh
```

**リポジトリが存在する場合**:
```bash
~/.claude/scripts/export-to-community.sh
```

**スクリプトの動作**:
1. リポジトリが存在しない場合のみ:
   - Public repository自動作成
   - mainブランチ初期化（README付き）
   - ブランチ保護設定
2. Git履歴書き換え（機密ファイル除外）
3. PRの自動作成
4. TruffleHogセキュリティスキャン

---

### STEP 5: 結果報告

スクリプト実行後：
1. 実行結果を確認
2. PR URLをユーザーに報告
3. TruffleHogセキュリティスキャン結果を報告
4. **PRのマージについては必ずユーザーに確認すること**
5. マージ承認を得た場合のみ、マージを実行

---

## 重要な注意事項

### GitHub CLI (gh) コマンドの安全性確認（絶対必須）

**このコマンド実行中にghコマンドを使用する際は、必ず以下を確認すること：**

#### 問題

upstream設定があるプロジェクト（private fork等）では、ghコマンドがupstreamをデフォルトリポジトリとして使用する場合があります。これにより、誤ったリポジトリにPR/Issueを作成してしまう可能性があります。

#### 🚨 絶対ルール

**ghコマンド実行前に、必ず現在のリポジトリとghのデフォルトリポジトリが一致しているか確認すること。**

#### 安全確認手順

ghコマンドを実行する前に、以下の確認を必ず行ってください：

```bash
# 現在のリポジトリ（originから取得）
CURRENT_REPO=$(git remote get-url origin | sed -E 's/.*github\.com[:/](.*)(\.git)?/\1/')

# ghのデフォルトリポジトリ
GH_DEFAULT_REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)

# 一致チェック
if [ "$CURRENT_REPO" != "$GH_DEFAULT_REPO" ]; then
  echo "⚠️  警告: リポジトリ不一致を検出"
  echo "  現在の作業リポジトリ: $CURRENT_REPO"
  echo "  gh のデフォルト: $GH_DEFAULT_REPO"
  echo ""
  echo "以下のように -R フラグで明示的に指定してください："
  echo "  gh pr create -R $CURRENT_REPO --base develop --head feature/xxx"
  exit 1
fi

echo "✅ リポジトリ一致確認: $CURRENT_REPO"
```

確認が取れたら、安全のため`-R`フラグを使用してghコマンドを実行：

```bash
gh pr create -R "$CURRENT_REPO" --base develop --head feature/xxx
```

### その他の注意事項

- **PRマージは必ずユーザーの承認を得てから実行**（絶対禁止事項）
- 依存ツール: `git-filter-repo`, `yq`, `gh` (GitHub CLI), `trufflehog`
- GitHub権限が必要（repository作成、branch protection設定）
- 初回セットアップは対話形式で丁寧に進める
- 2回目以降は設定ファイルを読み込んで即座に実行
