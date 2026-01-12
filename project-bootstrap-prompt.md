# プロジェクト立ち上げ支援プロンプト

## ⚠️ 重要: このプロンプトの役割

**このプロンプト（`/ypm:new`コマンド）の唯一の仕事は、ブートストラップフローを厳格に守り、安全かつ迅速にプロジェクトの実装準備を完了させることです。**

### 絶対に守るべき原則

1. **ブートストラップフローの厳守**
   - Phase 1〜8を順番通りに実行
   - フェーズを飛ばさない、省略しない
   - ユーザーとの対話が必要な箇所は必ず確認

2. **実装は絶対に行わない**
   - YPMは準備のみ。実装・テストコード作成は禁止
   - 準備完了後、別セッションでの作業を案内

3. **進捗の可視化**
   - 各フェーズで現在地を明示
   ```
   ## [プロジェクト名] - ブートストラップ進捗

   ✅ Phase 1: プロジェクト企画
   ✅ Phase 2: プロジェクトディレクトリ作成
   🔄 Phase 3: ドキュメント整備 ← 現在ここ
   ⏳ Phase 4: GitHub連携
   ⏳ Phase 5: Git Workflow設定
   ⏳ Phase 6: 環境設定ファイル整備
   ⏳ Phase 7: ドキュメント管理ルール
   ⏳ Phase 8: CLAUDE.md作成と最終確認
   ```

4. **安全性の確保**
   - 破壊的操作を避ける
   - ユーザー確認箇所で必ず問いかける

5. **迅速性**
   - 効率的なヒアリング
   - テンプレート活用
   - 不要な対話は省く

---

新しいプロジェクトの企画から初期セットアップまでを段階的に進めます。

## フェーズ1: プロジェクト企画

**進捗表示**:
```
🔄 Phase 1: プロジェクト企画 ← 現在ここ
⏳ Phase 2: プロジェクトディレクトリ作成
⏳ Phase 3: ドキュメント整備
⏳ Phase 4: GitHub連携
⏳ Phase 5: Git Workflow設定
⏳ Phase 6: 環境設定ファイル整備
⏳ Phase 7: ドキュメント管理ルール
⏳ Phase 8: CLAUDE.md作成と最終確認
```

まず、以下について対話しながら要件を固めていきます：

1. **プロジェクト概要のヒアリング**
   - どんなプロジェクトを作りたいですか？（目的、機能、技術スタック）
   - 対象ユーザーや利用シーン

2. **要件定義の作成**
   - 機能要件（必須機能、優先順位）
   - 非機能要件（パフォーマンス、セキュリティ、スケーラビリティ）
   - 技術選定の理由

3. **プロジェクト基本情報の決定**
   - プロジェクト名
   - 概要説明（短文・長文）
   - 使用言語・フレームワーク

要件定義がまとまったら、システム仕様書・アーキテクチャ図などの必要なドキュメントを作成します。

### ✅ Phase 1 完了確認

**YPMが確認すること：**
- プロジェクト概要が明確になったか
- 要件定義がまとまったか
- プロジェクト名と技術スタックが決定したか

**すべて完了していることを確認したら、ユーザーに報告：**

「✅ Phase 1（プロジェクト企画）が完了しました。

確定した内容：
- プロジェクト名: [プロジェクト名]
- 技術スタック: [技術スタック]
- 要件定義: [要件概要]

Phase 2（プロジェクトディレクトリの作成）に進んでよろしいですか？」

**ユーザーの承認を得たら：**
1. ブートストラッププロンプトのPhase 2を読み直す（内部動作）
2. Phase 2の内容を確認する（内部動作）
3. Phase 2を開始する

## フェーズ2: プロジェクトディレクトリの作成

**進捗表示**:
```
✅ Phase 1: プロジェクト企画
🔄 Phase 2: プロジェクトディレクトリ作成 ← 現在ここ
⏳ Phase 3: ドキュメント整備
⏳ Phase 4: GitHub連携
⏳ Phase 5: Git Workflow設定
⏳ Phase 6: 環境設定ファイル整備
⏳ Phase 7: ドキュメント管理ルール
⏳ Phase 8: CLAUDE.md作成と最終確認
```

1. **ローカルディレクトリの確認**
   - プロジェクト用のgitディレクトリのパスを教えてください
   - ディレクトリが存在しない場合は作成します
   
2. **Git初期化**
   - `git init` を実行
   - 初期コミット用のREADME.mdを作成

### ✅ Phase 2 完了確認

**YPMが確認すること：**
- プロジェクトディレクトリが作成されたか
- Gitリポジトリが初期化されたか（`.git/`ディレクトリが存在するか）
- README.mdが作成されたか

**すべて完了していることを確認したら、ユーザーに報告：**

「✅ Phase 2（プロジェクトディレクトリの作成）が完了しました。

作成した成果物：
- プロジェクトディレクトリ: [パス]
- Gitリポジトリ初期化完了
- README.md作成完了

Phase 3（ドキュメント整備）に進んでよろしいですか？」

**ユーザーの承認を得たら：**
1. ブートストラッププロンプトのPhase 3を読み直す（内部動作）
2. Phase 3の内容を確認する（内部動作）
3. Phase 3を開始する

## フェーズ3: ドキュメント整備

**進捗表示**:
```
✅ Phase 1: プロジェクト企画
✅ Phase 2: プロジェクトディレクトリ作成
🔄 Phase 3: ドキュメント整備 ← 現在ここ
⏳ Phase 4: GitHub連携
⏳ Phase 5: Git Workflow設定
⏳ Phase 6: 環境設定ファイル整備
⏳ Phase 7: ドキュメント管理ルール
⏳ Phase 8: CLAUDE.md作成と最終確認
```

### 🎯 核心原則: DDD（Documentation Driven Development）

**すべての開発はドキュメントから始まります。**

- **DDD = Documentation Driven Development**（ドキュメント駆動開発）
  - ドメイン駆動設計（Domain-Driven Design）ではありません
  - 開発フロー: **仕様書作成 → 実装 → テスト → ドキュメント更新**
  - **ドキュメントが真実の唯一の源（Single Source of Truth）**
  - コードとドキュメントの乖離を許さない

この原則により：
✅ 実装前に要件が明確になる
✅ チーム（または未来の自分）が迷わない
✅ 新メンバーのオンボーディングが容易
✅ 設計の一貫性が保たれる

### 1. **docs/ディレクトリの作成**
   - `docs/` 配下に以下を作成：
     - **INDEX.md**（ドキュメント索引・管理）
     - 要件定義書（requirements.md）
     - システム仕様書（specifications.md）
     - アーキテクチャ設計書（architecture.md）
     - 開発ガイドライン（development-guide.md）
   
### 2. **開発ルールの導入**

   - **TDD（Test Driven Development - テスト駆動開発）**
     - Red → Green → Refactor サイクルの遵守
     - 実装前にテストを書く
     - テストカバレッジの目標設定

   - **DRY（Don't Repeat Yourself）**
     - コードの重複を避ける
     - 共通ロジックの抽出
     - 再利用可能なコンポーネント設計

### 3. **リサーチディレクトリの準備**
   - `docs/research/` を作成
   - README.mdに以下を記載：
     - 「将来的にサブレポジトリ化予定」
     - 「geminiコマンドやWebFetchでリサーチした内容をドキュメント化する場所」

### ✅ Phase 3 完了確認

**YPMが確認すること：**
- docs/INDEX.mdを作成したか
- docs/配下に4つの基本ドキュメント（requirements.md、specifications.md、architecture.md、development-guide.md）を作成したか
- docs/research/ディレクトリとREADME.mdを作成したか
- 開発原則（DDD、TDD、DRY）がドキュメントに明記されているか

**すべて完了していることを確認したら、ユーザーに報告：**

「✅ Phase 3（ドキュメント整備）が完了しました。

作成した成果物：
- docs/INDEX.md（ドキュメント索引）
- docs/requirements.md（要件定義書）
- docs/specifications.md（システム仕様書）
- docs/architecture.md（アーキテクチャ設計書）
- docs/development-guide.md（開発ガイドライン）
- docs/research/（リサーチ内容保存用ディレクトリ）

Phase 4（GitHub連携）に進んでよろしいですか？」

**ユーザーの承認を得たら：**
1. ブートストラッププロンプトのPhase 4を読み直す（内部動作）
2. Phase 4の内容を確認する（内部動作）
3. Phase 4を開始する

## フェーズ4: GitHub連携

**進捗表示**:
```
✅ Phase 1: プロジェクト企画
✅ Phase 2: プロジェクトディレクトリ作成
✅ Phase 3: ドキュメント整備
🔄 Phase 4: GitHub連携 ← 現在ここ
⏳ Phase 5: Git Workflow設定
⏳ Phase 6: 環境設定ファイル整備
⏳ Phase 7: ドキュメント管理ルール
⏳ Phase 8: CLAUDE.md作成と最終確認
```

1. **GitHubアカウント情報の取得**
   - GitHubアカウント名を教えてください
   - `gh api user/orgs` で所属組織を取得・表示
   - 個人アカウントまたは組織を選択

2. **リポジトリ作成**
   - **「Privateリポジトリで作成しますがよろしいですか？」とユーザーに確認**
   - ユーザーが承認したら `gh repo create --private` でリポジトリ作成
   - 初期プッシュを実行
   - ※公開する場合は、準備が整ってから手動でPublicに変更可能

### ✅ Phase 4 完了確認

**YPMが確認すること：**
- GitHubリポジトリが作成されたか
- ローカルリポジトリがGitHubにプッシュされたか

**すべて完了していることを確認したら、ユーザーに報告：**

「✅ Phase 4（GitHub連携）が完了しました。

作成した成果物：
- GitHubリポジトリ: [リポジトリURL]
- 初期プッシュ完了

Phase 5（Git Workflowの設定）に進んでよろしいですか？」

**ユーザーの承認を得たら：**
1. ブートストラッププロンプトのPhase 5を読み直す（内部動作）
2. Phase 5の内容を確認する（内部動作）
3. Phase 5を開始する

## フェーズ5: Git Workflowの設定

**進捗表示**:
```
✅ Phase 1: プロジェクト企画
✅ Phase 2: プロジェクトディレクトリ作成
✅ Phase 3: ドキュメント整備
✅ Phase 4: GitHub連携
🔄 Phase 5: Git Workflow設定 ← 現在ここ
⏳ Phase 6: 環境設定ファイル整備
⏳ Phase 7: ドキュメント管理ルール
⏳ Phase 8: CLAUDE.md作成と最終確認
```

1. **Workflowの必要性確認**
   - Git Flowを導入しますか？（推奨：複数人開発の場合）

2. **導入する場合の設定**
   - **デフォルトブランチを`develop`に設定**（重要）
     ```bash
     gh api repos/:owner/:repo -X PATCH -f default_branch=develop
     ```
   - 理由:
     - `main`はリリースブランチ（本番環境）
     - `develop`は開発ブランチ（開発作業用）
     - 開発は`develop`で行うため、`develop`がデフォルト

   - **開発スタイルの選択**（新規追加）
     - ユーザーに確認：
       ```
       このプロジェクトの開発スタイルを選択してください：

       1️⃣ 一人開発（推奨）
          - あなた一人で開発
          - 管理者バイパス有効
          - レビュー推奨（強制ではない）

       2️⃣ チーム開発
          - 複数人で開発
          - 管理者も保護ルール適用
          - レビュー必須

       選択: [1/2]
       ```

   - **ブランチ保護ルール設定**

     **⚠️ 重要な設計原則**:
     - **Git Flowはマージコミットが必須**
     - `required_linear_history: false` に設定（Squashマージ禁止）
     - Squashマージは履歴を破壊し、main/developの履歴が分岐する原因になる

     **一人開発の場合**:
     ```bash
     # mainブランチ
     gh api repos/:owner/:repo/branches/main/protection -X PUT --input - <<'EOF'
     {
       "required_status_checks": null,
       "enforce_admins": false,
       "required_pull_request_reviews": {
         "dismiss_stale_reviews": true,
         "require_code_owner_reviews": false,
         "required_approving_review_count": 1
       },
       "restrictions": null,
       "allow_force_pushes": false,
       "allow_deletions": false,
       "required_linear_history": false
     }
     EOF

     # developブランチ（レビュー設定を追加）
     gh api repos/:owner/:repo/branches/develop/protection -X PUT --input - <<'EOF'
     {
       "required_status_checks": null,
       "enforce_admins": false,
       "required_pull_request_reviews": {
         "dismiss_stale_reviews": true,
         "require_code_owner_reviews": false,
         "required_approving_review_count": 1
       },
       "restrictions": null,
       "allow_force_pushes": false,
       "allow_deletions": false,
       "required_linear_history": false
     }
     EOF
     ```

     **注**: 一人開発でもレビュー設定を追加していますが、`enforce_admins: false`によりAdminはバイパス可能です。これにより：
     - 現在：セルフレビューを推奨しつつ、必要に応じてスキップ可能
     - 将来：チーム開発移行時に自動的にレビューが必須化される

     **チーム開発の場合**:
     ```bash
     # mainブランチ
     gh api repos/:owner/:repo/branches/main/protection -X PUT --input - <<'EOF'
     {
       "required_status_checks": null,
       "enforce_admins": true,
       "required_pull_request_reviews": {
         "dismiss_stale_reviews": true,
         "require_code_owner_reviews": false,
         "required_approving_review_count": 1
       },
       "restrictions": null,
       "allow_force_pushes": false,
       "allow_deletions": false,
       "required_linear_history": false
       }
     EOF

     # developブランチ
     gh api repos/:owner/:repo/branches/develop/protection -X PUT --input - <<'EOF'
     {
       "required_status_checks": null,
       "enforce_admins": true,
       "required_pull_request_reviews": {
         "required_approving_review_count": 1
       },
       "restrictions": null,
       "allow_force_pushes": false,
       "allow_deletions": false,
       "required_linear_history": false
     }
     EOF
     ```

     **設定内容の説明**:
     - `required_linear_history: false` - **マージコミット許可**（Git Flow維持に必須）
     - `enforce_admins` - 一人開発: false（バイパス可能）、チーム: true
     - `required_approving_review_count` - 両方: 1（一人開発はバイパス可能、チームは必須）
     - `allow_force_pushes: false` - Force push禁止
     - `dismiss_stale_reviews: true` - 古いレビューは新コミットで無効化

     **段階的移行の考え方**:
     1. **ソロ開発フェーズ**: レビュー設定はあるが、Adminはバイパス可能で柔軟に作業
     2. **チーム参加時**: 新メンバーは自動的にレビュー必須（Admin以外）
     3. **完全移行時**: `enforce_admins: true`に変更で全員レビュー必須

   - **リポジトリレベルのマージ設定**（必須）

     **⚠️ 重要**: ブランチ保護だけでなく、リポジトリレベルでもSquashマージを無効化

     ```bash
     # Squashマージとリベースマージを無効化
     gh api repos/:owner/:repo -X PATCH -f allow_squash_merge=false -f allow_rebase_merge=false
     ```

     **理由**:
     - ブランチ保護は「履歴を直線にするか」の設定
     - リポジトリ設定は「どのマージ方法を許可するか」の設定
     - 両方設定しないと、PRマージ時にSquashが選択できてしまう
     - **Git Flowでは必ずマージコミットのみ許可する**

3. **Git Worktreeの導入確認**
   - Git Worktreeを導入しますか？
   - **導入する場合の構成**：
     - **メイン（develop）**: プロジェクトディレクトリそのまま
     - **main worktree**: `[プロジェクト名]_main/`（リリース用、読み取り専用）

   **セットアップ手順**:
   ```bash
   # プロジェクトディレクトリで実行
   cd /path/to/project

   # main worktreeを作成（プロジェクト名_mainディレクトリ）
   git worktree add ../[プロジェクト名]_main main
   ```

   **ディレクトリ構成例**（instrvoの場合）:
   ```
   /Users/yamato/Src/proj_instrvo/
   ├── instrvo/         # develop worktree（開発作業用、ここがメイン）
   └── instrvo_main/    # main worktree（リリース用、読み取り専用）
   ```

   - **導入しない場合**：
     - 通常のブランチ切り替えで運用
   - **注意**: 初期に導入しなくても、後から必要になったら導入可能

4. **作業フローのルール化**
   - 作業時は必ずISSUEを作成
   - 基本的に `develop` からブランチを切る
   - すでに作業用ブランチにいる場合は、どこからブランチを切るか確認

5. **コミット・PR・ISSUEの命名規則**
   - タイトル：英語
   - 本文：日本語または英語（どちらにしますか？）

### ✅ Phase 5 設定完了後の確認

**YPMが以下を実行して設定を確認し、ユーザーに提示：**

1. **デフォルトブランチの確認**
   ```bash
   gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
   ```
   結果をユーザーに見せて「デフォルトブランチが`develop`になっていますか？」と確認

2. **ブランチ保護設定の確認**
   ```bash
   gh api repos/:owner/:repo/branches/main/protection
   gh api repos/:owner/:repo/branches/develop/protection
   ```
   結果をユーザーに見せて「ブランチ保護設定は正しいですか？」と確認

3. **Git Worktreeの確認**（導入した場合）
   ```bash
   git worktree list
   ```
   結果をユーザーに見せて「Worktree構成は正しいですか？」と確認

**ユーザーの承認を得てから次のステップに進む**

### ✅ Phase 5 完了確認

**YPMが確認すること：**
- デフォルトブランチが`develop`に設定されたか（確認済み）
- main/developブランチ保護が設定されたか（確認済み）
- Git Worktree設定が完了したか（導入した場合、確認済み）
- 作業フローのルールが確立されたか

**すべて完了していることを確認したら、ユーザーに報告：**

「✅ Phase 5（Git Workflowの設定）が完了しました。

設定した内容：
- デフォルトブランチ: develop
- ブランチ保護: main/develop
- Git Worktree: [導入した場合は構成を記載]
- コミット・PR・ISSUE命名規則: [タイトル英語/本文日本語 等]

Phase 6（環境設定ファイルの整備）に進んでよろしいですか？」

**ユーザーの承認を得たら：**
1. ブートストラッププロンプトのPhase 6を読み直す（内部動作）
2. Phase 6の内容を確認する（内部動作）
3. Phase 6を開始する

## フェーズ6: 環境設定ファイルの整備

**進捗表示**:
```
✅ Phase 1: プロジェクト企画
✅ Phase 2: プロジェクトディレクトリ作成
✅ Phase 3: ドキュメント整備
✅ Phase 4: GitHub連携
✅ Phase 5: Git Workflow設定
🔄 Phase 6: 環境設定ファイル整備 ← 現在ここ
⏳ Phase 7: ドキュメント管理ルール
⏳ Phase 8: CLAUDE.md作成と最終確認
```

1. **.gitignoreの設定**
   - `.serena` を追加（開発プロジェクトで必須）
   - 言語・フレームワーク固有の設定を追加

2. **.claude/settings.json の設定**

   **公式ドキュメント参照**（形式確認用）:
   - [Claude Code Settings - Anthropic Docs](https://docs.anthropic.com/en/docs/claude-code/settings)

   **基本テンプレート**:

   > **設計思想**: `allow`は最小限に。各ユーザーは`.claude/settings.local.json`で許可を追加可能。
   > 共有用`settings.json`は`ask`と`deny`を中心に構成。

   ```json
   {
     "permissions": {
       "allow": [
         "Read(*)",
         "Glob(*)",
         "Grep(*)"
       ],
       "ask": [
         "Write(*)",
         "Edit(*)",
         "Bash(git :*)",
         "Bash(gh :*)",
         "Bash(npm :*)",
         "Bash(pnpm :*)",
         "Bash(yarn :*)",
         "Bash(python :*)",
         "Bash(pip :*)",
         "Bash(cargo :*)",
         "Bash(go :*)",
         "Bash(docker :*)",
         "Bash(curl :*)",
         "Bash(wget :*)"
       ],
       "deny": [
         "Read(./.env)",
         "Read(./.env.*)",
         "Read(./secrets/**)",
         "Read(./**/credentials.json)",
         "Read(./**/*.pem)",
         "Read(./**/*.key)",
         "Bash(rm -rf :*)",
         "Bash(rm -r :*)",
         "Bash(rm -fr :*)",
         "Bash(git push --force :*)",
         "Bash(git push -f :*)",
         "Bash(git reset --hard :*)",
         "Bash(git clean -f :*)",
         "Bash(git clean -fd :*)",
         "Bash(gh repo delete :*)",
         "Bash(gh secret :*)",
         "Bash(sudo :*)",
         "Bash(chmod 777 :*)",
         "Bash(curl :* | :*)",
         "Bash(wget :* | :*)"
       ]
     },
     "cleanupPeriodDays": 30
   }
   ```

   **デフォルト戦略**:
   - `allow`: **最小限**（読み取り専用のみ）- ユーザーは`settings.local.json`で追加可能
   - `ask`: 書き込み、Git、ビルドツール、ネットワーク操作等（確認を求める）
   - `deny`: 機密ファイル、破壊的操作
   
3. **破壊的変更の禁止ルール**
   - システムファイル（/etc, /usr など）への変更禁止
   - プロジェクトディレクトリ外のファイル変更禁止
   - これらをsettings.jsonとREADME.mdに明記

### ⚠️ 重要な警告

**ユーザーへの注意喚起：**

「`.claude/settings.json`は公式ドキュメントとベストプラクティスに基づいて作成しますが、プロジェクトごとに要件が異なる可能性があります。

各プロジェクトでClaude Codeセッションを開始した際に、settings.jsonの設定が適切かどうかを必ず確認してください。特に：
- プロジェクト固有のツールやコマンドの権限
- 特殊なディレクトリ構造への対応
- セキュリティ要件

必要に応じて手動で調整してください。」

### ✅ Phase 6 完了確認

**YPMが確認すること：**
- .gitignoreに`.serena`が追加されたか
- .claude/settings.jsonが作成されたか
- settings.jsonに公式ベストプラクティスが反映されているか
- 破壊的変更の禁止ルールがsettings.jsonとREADME.mdに明記されているか

**すべて完了していることを確認したら、ユーザーに報告：**

「✅ Phase 6（環境設定ファイルの整備）が完了しました。

作成した成果物：
- .gitignore（.serena追加済み）
- .claude/settings.json（パーミッション設定済み）

⚠️ 注意: settings.jsonはプロジェクトごとに確認・調整が必要です

Phase 7（ドキュメント管理ルールの確立）に進んでよろしいですか？」

**ユーザーの承認を得たら：**
1. ブートストラッププロンプトのPhase 7を読み直す（内部動作）
2. Phase 7の内容を確認する（内部動作）
3. Phase 7を開始する

## フェーズ7: ドキュメント管理ルールの確立

**進捗表示**:
```
✅ Phase 1: プロジェクト企画
✅ Phase 2: プロジェクトディレクトリ作成
✅ Phase 3: ドキュメント整備
✅ Phase 4: GitHub連携
✅ Phase 5: Git Workflow設定
✅ Phase 6: 環境設定ファイル整備
🔄 Phase 7: ドキュメント管理ルール ← 現在ここ
⏳ Phase 8: CLAUDE.md作成と最終確認
```

1. **ドキュメント更新の原則**
   - **実装とドキュメントの同期維持**
     - 機能追加・変更時は関連ドキュメントも更新
     - PRレビュー時にドキュメント更新も確認
   
   - **更新が必要なタイミング**
     - 新機能の実装完了時
     - アーキテクチャの変更時
     - API仕様の変更時
     - 環境設定の変更時
     - 依存パッケージの大幅な更新時
   
   - **対象ドキュメント**
     - README.md（セットアップ手順、使い方）
     - docs/specifications.md（システム仕様）
     - docs/architecture.md（設計図）
     - docs/development-guide.md（開発ガイドライン）
     - API仕様書（存在する場合）

2. **オンボーディング支援**
   - README.mdに以下を含める：
     - クイックスタートガイド
     - 開発環境のセットアップ手順
     - よくある問題とその解決方法（FAQ）
     - コントリビューションガイドライン
   
   - `docs/onboarding.md` の作成：
     - プロジェクト構造の説明
     - コーディング規約
     - テストの書き方・実行方法
     - デプロイメントプロセス

3. **ドキュメント更新のチェックリスト**
   - PRテンプレートに「ドキュメント更新の有無」を追加
   - CI/CDでドキュメントのリンク切れチェック（可能な場合）

### ✅ Phase 7 完了確認

**YPMが確認すること：**
- ドキュメント管理の原則が確立されたか
- README.mdにオンボーディング情報が含まれているか
- docs/onboarding.mdが作成されたか
- PRテンプレートが作成されたか

**すべて完了していることを確認したら、ユーザーに報告：**

「✅ Phase 7（ドキュメント管理ルールの確立）が完了しました。

作成した成果物：
- README.md（オンボーディング情報追加）
- docs/onboarding.md
- PRテンプレート（.github/pull_request_template.md）

Phase 8（CLAUDE.md作成と最終確認）に進んでよろしいですか？」

**ユーザーの承認を得たら：**
1. ブートストラッププロンプトのPhase 8を読み直す（内部動作）
2. Phase 8の内容を確認する（内部動作）
3. Phase 8を開始する

## フェーズ8: CLAUDE.md作成と最終確認

**進捗表示**:
```
✅ Phase 1: プロジェクト企画
✅ Phase 2: プロジェクトディレクトリ作成
✅ Phase 3: ドキュメント整備
✅ Phase 4: GitHub連携
✅ Phase 5: Git Workflow設定
✅ Phase 6: 環境設定ファイル整備
✅ Phase 7: ドキュメント管理ルール
🔄 Phase 8: CLAUDE.md作成と最終確認 ← 現在ここ
```

1. **CLAUDE.md作成**
   - プロジェクト専用のCLAUDE.mdを作成
   - **推奨**: CLAUDE.mdは英語で書く（Claude Code 2.1.0以降の言語設定機能を活用）
   - 以下の内容を含める：
     - プロジェクト概要
     - 技術スタック
     - 開発原則（DDD、TDD、DRY）
     - セッション開始時の手順
     - **Git Workflow（詳細な手順書）**
     - **コミット・PR・ISSUE規約（言語ルール強調）**
     - **言語設定の説明（Claude Code 2.1.0+対応）**
     - ディレクトリ構成
     - 実装の進め方
     - トラブルシューティング
     - 参考リソース

   **CLAUDE.mdに必ず含めるべき重要セクション**:

   ### A. Git Workflow強制ルール

   ```markdown
   ## 開発フロー

   ### ⚠️ 重要: Git Workflowの強制ルール

   **このセクションは絶対に省略できません。違反した場合は即座に停止してユーザーに報告すること。**

   #### 新機能開発フロー

   **STEP 1**: GitHubでISSUE作成（必須）
   **STEP 2**: 現在のブランチ確認（`git branch --show-current`で`develop`であることを確認）
   **STEP 3**: featureブランチ作成（`git checkout -b feature/<issue番号>-<機能名>`）
   **STEP 4**: 実装・コミット
   **STEP 5**: PR作成（`feature/<...>` → `develop`）
   **STEP 6**: マージ（マージコミット使用）

   #### リリースフロー

   **STEP 1**: GitHubでISSUE作成（例: `Release v1.0.1`）
   **STEP 2**: developブランチで最終調整・バージョン更新（必要に応じて）
   **STEP 3**: PR作成（`develop` → `main`）  ← **直接PRでOK**
   **STEP 4**: マージ（マージコミット使用）
   **STEP 5**: タグ付け（`git tag v1.0.1`）

   **重要**: developからmainへの直接PRは**リリース時のみ許可**。
   逆方向（main → develop）は**絶対禁止**。

   #### 🚨 絶対禁止事項

   - ❌ **main → develop への逆流**（これが最も重要）
   - ❌ **main・developブランチへの直接コミット**
   - ❌ Squashマージ（Git Flow履歴が破壊される）
   - ❌ ISSUE番号のないブランチ名

   #### 🚨 違反時の対応

   以下の状況を検知した場合、**即座に作業を停止**してユーザーに報告：

   1. **main → develop への逆流PR作成を試みた**
      → 即座停止、「逆流は絶対禁止です」と報告

   2. **main・developブランチへの直接コミットを試みた**
      → 即座停止、「featureブランチまたはbugfix/hotfixブランチで作業してください」と報告

   3. **Squashマージを選択しようとした**
      → 即座停止、「必ずマージコミットを使用してください」と報告
   ```

   ### B. コミット・PR言語ルール

   ```markdown
   ## コミットメッセージ規約

   ### 🚨 絶対に守るべき言語ルール（CRITICAL）

   **コミット・PR・ISSUEの言語**:
   - ✅ **タイトル（1行目）**: **必ず英語** (Conventional Commits)
   - ✅ **本文（2行目以降）**: **必ず日本語**

   ### フォーマット

   ```
   <type>(<scope>): <subject>  ← 英語

   <body>  ← 日本語

   <footer>
   ```

   **✅ 正しい例**:
   ```bash
   feat(tickets): implement issue search functionality

   チケット検索機能を実装
   - search_issuesツールを追加
   - 複数のフィルターパラメータに対応

   Closes #123
   ```

   **❌ 間違った例（絶対にやってはいけない）**:
   ```bash
   # NG: 本文が英語
   feat(tickets): implement issue search functionality

   - Add search_issues tool  ← 英語はダメ！
   - Support multiple filter parameters  ← 英語はダメ！

   Closes #123
   ```

   ### 🚨 違反時の対応

   4. **コミット・PRの本文が英語になっている**
      → **絶対に許されない違反**
      → 即座にユーザーに報告し、修正方法を提案
   ```

   ### C. 言語設定の推奨（Claude Code 2.1.0以降）

   ```markdown
   ## 言語設定

   ### CLAUDE.md言語の推奨

   **推奨**: このCLAUDE.mdは英語で書かれています。

   **理由**:
   - UTF-8/CJK文字によるクラッシュ回避（既知のRust panic bug）
   - Claudeの英語学習データを最大限活用
   - 日本語コミュニティの推奨パターン
   - 日本語応答は`language`設定で保証

   ### 日本語で作業する方法

   Claude Code 2.1.0以降では、英語CLAUDE.mdでも日本語応答が可能です：

   **設定方法**:
   `.claude/settings.json`（ユーザー設定、リポジトリ外）に以下を追加：

   ```json
   {
     "language": "japanese"
   }
   ```

   この設定により：
   - ✅ CLAUDE.mdは英語（安定性・性能向上）
   - ✅ Claude応答は日本語（自然なコミュニケーション）
   - ✅ クラッシュリスク最小化

   ### 参考資料

   - [Claude Code Settings](https://docs.anthropic.com/en/docs/claude-code/settings)
   - [YPM Language Strategy](https://github.com/signalcompose/ypm/blob/main/docs/LANGUAGE_STRATEGY.md)
   ```

2. **CLAUDE.mdのレビュー**
   - 作成したCLAUDE.mdの内容をユーザーに提示
   - 「このCLAUDE.mdの内容でよろしいですか？」と確認
   - ⚠️ **重要な注意事項をユーザーに伝える：**

     「CLAUDE.mdの変更は各プロジェクトのClaude Codeと確認しつつ修正するか、手動で編集を行ってください。プロジェクト固有の要件に応じて、適宜調整が必要です。」

3. **追加ルールの確認**
   - ユーザーに「他に導入したいルールや設定はありますか？」と確認

4. **最終コミット・プッシュ**
   - すべての変更をコミット
   - GitHubにプッシュ

5. **セットアップ完了確認**
   - プロジェクトが開発可能な状態であることを確認
   - 次のステップの案内：

     ```
     🎉 [プロジェクト名]の準備が完了しました！

     ⚠️ 重要: YPMでの作業はここまでです

     YPMは「準備のみ」を行います。実装・テストコードの作成は行いません。

     次のステップ:
     1. プロジェクトディレクトリに移動: cd [パス]
     2. 新しいClaude Codeセッションを開始
     3. CLAUDE.mdの指示に従って開発開始:
        - DDD原則: ドキュメントから始める
        - TDD原則: テストを先に書く
        - 最初のISSUE作成
        - developブランチから開発ブランチを切る

     実装は各プロジェクトで行ってください。
     ```

### ✅ Phase 8 完了確認

**YPMが確認すること：**
- CLAUDE.mdが作成され、ユーザーのレビューを受けたか
- すべての変更がコミットされたか
- GitHubにプッシュされたか
- プロジェクトが開発可能な状態になったか

**すべて完了していることを確認したら、ユーザーに最終報告：**

「🎉 全8フェーズのブートストラップが完了しました！

[プロジェクト名]は開発可能な状態です。

作成された主な成果物：
- プロジェクトディレクトリとGitリポジトリ
- docs/配下の基本ドキュメント
- GitHubリポジトリ（Private）
- Git Workflow設定（develop/main、ブランチ保護）
- 環境設定ファイル（.gitignore、.claude/settings.json）
- ドキュメント管理ルール（PRテンプレート等）
- CLAUDE.md

⚠️ 重要: YPMでの作業はここまでです。
実装は各プロジェクトで行ってください。

次のステップ:
1. プロジェクトディレクトリに移動: cd [パス]
2. 新しいClaude Codeセッションを開始
3. CLAUDE.mdの指示に従って開発開始」

---

## 開発中の継続的な実践

### TDD実践ルール
1. **Red**: 失敗するテストを書く
2. **Green**: テストをパスする最小限のコードを書く
3. **Refactor**: DRY原則に基づいてリファクタリング

### ドキュメント更新のトリガー
- 機能実装が完了し、PRをマージする直前
- マイルストーン達成時（v0.1.0, v0.2.0など）
- 月次または隔週での定期レビュー

---

## 使い方

このプロンプトをClaude Codeに貼り付けて、対話を開始してください。各フェーズで必要な情報を尋ねながら、段階的にプロジェクトをセットアップしていきます。

---

**主な追加点：**

1. **フェーズ3**にTDD・DRY原則の明記
2. **フェーズ7**として「ドキュメント管理ルール」を新設
   - 更新タイミングの明確化
   - オンボーディング支援の仕組み
   - チェックリストの導入
3. **フェーズ8**に開発開始時の指針を追加
4. **開発中の継続的な実践**セクションで実装中のルールを明記

これにより、プロジェクト開始時だけでなく、開発が進行する中でもドキュメントが最新に保たれ、新しいメンバーがいつでもスムーズに参加できる環境が整います。