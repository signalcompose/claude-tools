# Dev Cycle Guide — 自律開発サイクルとパーミッションの考え方

> **Last Updated**: 2026-02-21
> **Audience**: Claude Code ユーザー（code プラグイン利用者）
> **Plugin**: `code@claude-tools`

---

## Table of Contents

1. [Dev Cycle とは](#dev-cycle-とは)
2. [なぜ Dev Cycle が必要か](#なぜ-dev-cycle-が必要か)
3. [4つのステージ](#4つのステージ)
4. [使い方](#使い方)
5. [パーミッションの設計思想](#パーミッションの設計思想)
6. [パーミッション設定ガイド](#パーミッション設定ガイド)
7. [ガードレールと禁止事項](#ガードレールと禁止事項)
8. [コンテキスト断絶からの復旧](#コンテキスト断絶からの復旧)
9. [環境セットアップ](#環境セットアップ)
10. [FAQ](#faq)

---

## Dev Cycle とは

Dev Cycle は、Claude Code の `code` プラグインが提供する **自律型の開発ライフサイクルオーケストレーター** です。

1つのコマンドで「実装 → 監査 → コードレビュー＋PR作成 → 振り返り」の4ステージを **ユーザーの介入なしに** 連続実行します。

```
/code:dev-cycle docs/plans/phase-3-plan.md
```

これだけで、プラン読み込みからPR作成、振り返りまでが自動で進みます。

### 何ができるのか

| ステージ | スキル | 何をするか |
|---------|--------|-----------|
| Sprint | `code:sprint-impl` | プラン解析、GitHub Issue作成、仕様書作成、並列チームエージェント実装、テスト、ビルド検証 |
| Audit | `code:audit-compliance` | DDD/TDD/DRY/ISSUE/PROCESS の5原則コンプライアンス監査 |
| Ship | `code:shipping-pr` | コードレビュー（自動修正ループ）、コミット、プッシュ、PR作成 |
| Retrospective | `code:retrospective` | 2エージェント並列分析（監査＋研究）、改善適用、メトリクス記録 |

---

## なぜ Dev Cycle が必要か

### 問題: 手動ワークフローの脆弱性

Claude Code で開発する際、「実装してコミットしてPR作成して」という作業を手動で行うと、以下の問題が発生しやすい:

- **コードレビューのスキップ** — 急いでいると `git push` + PR作成を直接実行してしまう
- **仕様書の欠落** — DDD（Documentation Driven Development）が守られない
- **テスト不足** — 実装後にテストを書き忘れる、またはカバレッジが不十分
- **プロセス違反の見落とし** — 振り返りがないため同じ失敗を繰り返す

### 解決: 自動化されたガードレール

Dev Cycle はこれらの問題を **プロセスとして自動的に防止** します:

- Sprint でDDD仕様書の作成を **必須ゲート** として強制
- Ship で **自動コードレビュー** を必須とし、レビューをパスしないとPR作成できない
- Audit で5原則のコンプライアンスをチェックし、HIGH影響の違反は **ブロッカー** として扱う
- Retrospective で定量的な振り返りを自動実行

---

## 4つのステージ

### Stage 1: Sprint Implementation（実装スプリント）

**スキル**: `/code:sprint-impl`

スプリントは11フェーズに分かれています:

| Phase | 内容 | 特記事項 |
|-------|------|---------|
| 0 | Serena コンテキスト読み込み | オプション |
| 1 | プロジェクトコンテキスト収集 | CLAUDE.md、docs/INDEX.md、package.json |
| 2 | 依存パッケージ確認 | `npm install` |
| 3 | GitHub Issue 作成 | 親Issue + サブIssue |
| 4 | タスク依存関係分析 | 順次 vs 並列の判定 |
| **4.5** | **DDD仕様書作成（必須ゲート）** | **`docs/specs/` に仕様書がなければ停止** |
| 5 | 順次基盤実装 | 型定義、共通インターフェース |
| 6 | 並列チーム実装 | Task toolでエージェント並列起動 |
| 7 | 統合検証 | tsc, vitest, eslint |
| 7.5 | コンプライアンスゲート | DDD/TDD/DRY/ISSUE 事前チェック |
| 8 | カバレッジ確認 | 閾値（デフォルト80%）チェック |
| 9 | サマリーレポート | - |

**重要**: Phase 4.5 は **強制ゲート** です。仕様書が存在しないと実装に進めません。これにより「コードを先に書いて後でドキュメントを書く」という悪習慣を構造的に防止します。

### Stage 2: Compliance Audit（コンプライアンス監査）

**スキル**: `/code:audit-compliance`

5つの原則についてコンプライアンスを検証:

| 原則 | チェック内容 | 影響度 |
|------|------------|--------|
| DDD | `docs/specs/` に仕様書が存在するか、実装前にコミットされたか | HIGH |
| TDD | テストファーストのコミットパターンが存在するか | MEDIUM |
| DRY | 意味のあるコード重複がないか | LOW-MEDIUM |
| ISSUE | GitHub Issueが実装前に作成されたか | LOW |
| PROCESS | コードレビューとシッピングの正式ワークフローが守られたか | HIGH |

**HIGH 影響の違反はブロッカー**: 修正しないと次のステージに進めません。1回だけ自動修復を試み、それでもFAILなら停止します。

### Stage 3: Ship PR（コードレビュー＋PR作成）

**スキル**: `/code:shipping-pr`

```
Pre-flight → 変更分析 → ステージング → コードレビュー → 修正ループ → コミット → Push → PR作成
```

**コードレビュー修正ループ**:
1. `pr-review-toolkit:code-reviewer` エージェントがレビュー
2. critical/important の問題が見つかれば自動修正
3. 再テスト + 再レビュー
4. 問題ゼロになるまで繰り返し（最大3回）

**重要**: コードレビューは **人間のレビューの代わり** ではなく、**PR作成前の品質ゲート** です。PRが作成された後、人間のレビューも引き続き重要です。

### Stage 4: Retrospective（振り返り）

**スキル**: `/code:retrospective`

2つのエージェントが **並列で** 分析:

| エージェント | 役割 | 出力 |
|-------------|------|------|
| Auditor | 5原則コンプライアンス再検証 | PASS/PARTIAL/FAIL + エビデンス |
| Researcher | コード品質・アーキテクチャ分析 | 強み/弱み/推奨事項/メトリクス |

分析結果に基づいて:
- コード修正があれば適用＋コミット
- SKILL.md の改善が必要なら更新
- プロセスの教訓を MEMORY.md に記録
- メトリクスを `docs/research/workflow-recording.md` に追加

---

## 使い方

### 前提条件

```bash
# 1. マーケットプレイス追加
/plugin marketplace add signalcompose/claude-tools

# 2. code プラグインインストール
/plugin install code@claude-tools

# 3. 環境チェック（推奨）
/code:setup-dev-env
```

### 基本的な使い方

```bash
# プランファイルを指定して全サイクル実行
/code:dev-cycle docs/plans/phase-3-plan.md

# GitHub Issue を指定
/code:dev-cycle https://github.com/owner/repo/issues/42

# インライン説明
/code:dev-cycle ユーザー認証機能を追加する

# 自動検出（docs/plans/ から次のフェーズを検出）
/code:dev-cycle
```

### 個別ステージの実行

各ステージは独立して実行可能です:

```bash
# スプリントのみ
/code:sprint-impl docs/plans/phase-3-plan.md

# 監査のみ
/code:audit-compliance

# PRシッピングのみ
/code:shipping-pr

# 振り返りのみ
/code:retrospective
```

### 実行前のチェック

```bash
# 環境チェック（読み取り専用）
/code:setup-dev-env

# 自動修正付き
/code:setup-dev-env --fix
```

---

## パーミッションの設計思想

### 基本原則: 「前に進むことを許可し、破壊を防ぐ」

Dev Cycle のパーミッション設計は、以下の考え方に基づいています:

```
許可するもの = プロジェクトの責務の範囲内での改善・変更
拒否するもの = プロジェクトの責務の範囲外の破壊的変更
```

#### 具体的に何を許可し、何を拒否するか

**✅ 許可（allow）— 読み取りと安全な操作**

| パーミッション | 理由 |
|--------------|------|
| `Read(*)` | コードを読むことは常に安全 |
| `Glob(*)` | ファイル検索は常に安全 |
| `Grep(*)` | テキスト検索は常に安全 |
| `Bash(git diff *)` | 差分の確認は安全 |
| `Bash(git status *)` | 状態の確認は安全 |
| `Bash(git log *)` | 履歴の確認は安全 |
| `Bash(gh pr view *)` | PR閲覧は安全 |
| `Bash(gh pr checks *)` | CI結果確認は安全 |

**理由**: 情報の読み取りはいかなる場合も安全です。コードを壊すことはなく、プロジェクトの状態を理解するために必要です。

**⚠️ 確認（ask）— 変更を伴うが必要な操作**

| パーミッション | 理由 |
|--------------|------|
| `Bash(git add :*)` | ステージングは変更だが、コミット前に確認可能 |
| `Bash(git commit :*)` | コミットは履歴に残るが、`git revert` で戻せる |
| `Bash(git push :*)` | リモートに送るが、通常のpushは安全 |
| `Bash(git branch :*)` | ブランチ作成は安全だが、削除は注意が必要 |
| `Bash(gh issue :*)` | Issue作成は外部への変更 |
| `Bash(gh pr :*)` | PR作成は外部への変更 |
| `Edit(**)` | ファイル編集はコアの操作 |

**理由**: これらは開発に不可欠な操作ですが、何が行われるかをユーザーが確認できるようにします。Sandbox モードを有効にすれば自動許可も可能です（後述）。

**❌ 拒否（deny）— 常に禁止する破壊的操作**

| パーミッション | 理由 |
|--------------|------|
| `Read(./.env)` | 環境変数に秘密情報が含まれている可能性 |
| `Read(./.env.*)` | 環境変数の派生ファイルも同様 |
| `Bash(rm -rf :*)` | 再帰的削除は取り返しがつかない |
| `Bash(rm -r :*)` | 同上 |
| `Bash(git push --force :*)` | 履歴の上書きは取り返しがつかない |
| `Bash(git push -f :*)` | 同上 |
| `Bash(git reset --hard :*)` | 作業中の変更が失われる |
| `Bash(gh repo delete :*)` | リポジトリ削除は取り返しがつかない |
| `Bash(sudo :*)` | 管理者権限は危険 |

**理由**: これらの操作はどのような状況でも自動実行すべきではありません。Dev Cycle の自律実行中であっても、これらは **絶対に実行されません**。

### 3層のガードレール構造

```
┌─────────────────────────────────────────────┐
│  Layer 1: Claude Code のパーミッションシステム   │
│  (.claude/settings.json — allow/ask/deny)     │
├─────────────────────────────────────────────┤
│  Layer 2: Dev Cycle のプロセスガードレール      │
│  (スキル内のゲート、Hook、状態管理)              │
├─────────────────────────────────────────────┤
│  Layer 3: コードレビュー＋監査                  │
│  (自動レビュー、5原則監査、振り返り)             │
└─────────────────────────────────────────────┘
```

**Layer 1** はシステムレベルの防御線。何が実行可能で何が不可能かを定義します。

**Layer 2** はプロセスレベルの防御線。許可された操作であっても、正しい順序・正しいプロセスで行われることを保証します（例: コードレビューなしのPR作成の禁止）。

**Layer 3** は品質レベルの防御線。プロセスを通過したコードが実際に品質基準を満たしているかを検証します。

### Sandbox モード

Dev Cycle を快適に使うための推奨設定:

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true
  }
}
```

**Sandbox の効果**:
- Bash コマンドがサンドボックス内で実行される（ファイルシステムの分離）
- `autoAllowBashIfSandboxed: true` により、`ask` パーミッションの操作が自動承認される
- **deny のパーミッションは Sandbox モードでも依然として拒否される**

これにより、Dev Cycle の自律実行中に毎回「git add を許可しますか？」のような確認が出ることなく、スムーズに4ステージが完了します。

### プロジェクトの責務の範囲

「プロジェクトの責務の範囲内」とは具体的に:

**範囲内（許可される改善・変更）**:
- ソースコードの追加・修正・リファクタリング
- テストの追加・修正
- ドキュメントの追加・更新
- 依存パッケージの追加・更新
- ブランチの作成・コミット・プッシュ
- Issue/PR の作成

**範囲外（許可されない破壊的変更）**:
- 環境変数や秘密情報の読み取り
- ファイルの再帰的削除
- Git履歴の強制書き換え
- リポジトリの削除
- システム管理者権限の使用
- CI/CDパイプラインの直接操作

---

## パーミッション設定ガイド

### 必要なパーミッション一覧

#### `.claude/settings.local.json`（ユーザーローカル設定）

```json
{
  "permissions": {
    "allow": [
      "Bash(git add :*)",
      "Bash(git commit :*)",
      "Bash(git status :*)",
      "Bash(git diff :*)",
      "Bash(git log :*)",
      "Bash(git branch :*)",
      "Bash(git push :*)",
      "Bash(git checkout :*)",
      "Bash(gh issue :*)",
      "Bash(gh pr :*)",
      "mcp__github__get_me",
      "mcp__github__list_issues",
      "mcp__github__list_branches",
      "mcp__github__list_pull_requests",
      "mcp__github__get_file_contents",
      "mcp__github__list_commits",
      "mcp__github__issue_write",
      "mcp__github__issue_read",
      "mcp__github__pull_request_read",
      "mcp__github__create_pull_request",
      "mcp__github__update_pull_request"
    ]
  },
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true
  }
}
```

#### GitHub MCP の設定

Dev Cycle は GitHub 操作に **GitHub MCP Server** を使用します。`.mcp.json` を設定してください:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<your-token>"
      }
    }
  }
}
```

**必要な GitHub Token スコープ**: `repo`, `read:org`

### 設定の確認方法

```bash
# 環境チェックコマンドで一括確認
/code:setup-dev-env

# 自動修正付き
/code:setup-dev-env --fix
```

`setup-dev-env` は以下の7項目をチェックします:

| # | チェック | 内容 |
|---|---------|------|
| 1 | Node.js | バージョン >= 20.0.0 |
| 2 | Dependencies | `node_modules/` が存在し最新か |
| 3 | Build | `dist/` が存在するか |
| 4 | Git State | `main` ブランチでないか、remote 設定があるか |
| 5 | GitHub MCP | MCP Server が応答するか |
| 6 | Code Review Skill | `review-commit` スキルが利用可能か |
| 7 | Permissions | 必要なパーミッションが設定されているか |

---

## ガードレールと禁止事項

### Dev Cycle の絶対禁止事項

Dev Cycle の実行中、以下の操作は **いかなる状況でも禁止** されています:

#### 1. レビュー承認フラグの手動作成

```bash
# ❌ 禁止
echo "$HASH" > /tmp/claude/review-approved-xxx

# ✅ 正しい方法
# pr-review-toolkit:code-reviewer エージェントが自動作成
```

**なぜ**: レビュープロセスを迂回することは、品質保証の根幹を破壊します。

#### 2. メインエージェントによる手動コードレビュー

```
❌ メインエージェントがdiffを読んで「問題なし」と判断する
✅ 必ず pr-review-toolkit:code-reviewer エージェントに委譲する
```

**なぜ**: レビューの客観性を確保するため。実装者とレビュアーは別のコンテキストである必要があります。

#### 3. shipping-pr スキルのスキップ

```bash
# ❌ 禁止
git push origin feature/xxx && gh pr create

# ✅ 正しい方法
/code:shipping-pr
```

**なぜ**: `shipping-pr` にはコードレビュー、修正ループ、承認フラグ作成が含まれています。直接pushすると全てのガードレールを迂回します。

#### 4. Pre-commit hook の回避

```bash
# ❌ 禁止
git commit --no-verify

# ✅ 正しい方法
# hookがブロックした場合、根本原因を修正して再試行
```

**なぜ**: Hook はプロジェクトの品質基準を強制するために存在します。回避は基準の無視を意味します。

#### 5. 設定言語以外での応答

```
❌ ユーザーが日本語設定なのに英語で応答する
✅ ユーザーの設定言語に従う
```

### Hook によるプロセス強制

Dev Cycle は **Claude Code の Hook システム** を活用して、プロセスの強制を行います:

| Hook | タイプ | 動作 |
|------|--------|------|
| `dev-cycle-stop.sh` | Stop | サイクル完了前のClaudeの停止を防止し、次のステージへの遷移を指示 |
| `check-pr-review-gate.sh` | PreToolUse | `gh pr create` をブロックし、レビュー承認フラグの存在を確認 |

**Stop Hook の仕組み**:

Dev Cycle 実行中、`.claude/dev-cycle.state.json` に現在のステージが記録されます:

```json
{"stage": "sprint"}  // → 次は audit
{"stage": "audit"}   // → 次は ship
{"stage": "ship"}    // → 次は retrospective
```

Claude が途中で停止しようとすると、Stop Hook がこのファイルを読み取り、次のステージを実行するよう指示します。全4ステージが完了した時点でファイルが削除され、正常終了します。

---

## コンテキスト断絶からの復旧

Dev Cycle は長時間実行されるため、Claude Code のコンテキストウィンドウが尽きる場合があります。各ステージは **自己完結型** で設計されているため、途中から再開できます。

### 状態の判断方法

| 状態 | 検出方法 | 再開コマンド |
|------|---------|------------|
| Sprint未完了 | 新規ソースファイルなし、テスト失敗 | `/code:sprint-impl $ARGUMENTS` |
| Sprint完了、未監査 | ソース＋テストあり、監査レポートなし | `/code:audit-compliance` |
| 監査完了、未出荷 | 監査PASS、PRなし | `/code:shipping-pr` |
| 出荷完了、振り返りなし | PRあり、retroコミットなし | `/code:retrospective` |
| 全完了 | retroコミットがgit logに存在 | 不要 |

### 復旧手順

```bash
# 1. 現在の状態を確認
git diff --stat $(git merge-base HEAD main)...HEAD
git log --oneline -5

# 2. 状態ファイルを確認
cat .claude/dev-cycle.state.json

# 3. 該当するステージを直接実行
/code:audit-compliance  # 例: Sprint完了後の場合
```

---

## 環境セットアップ

### 初回セットアップ手順

```bash
# 1. マーケットプレイスとプラグインのインストール
/plugin marketplace add signalcompose/claude-tools
/plugin install code@claude-tools

# 2. GitHub MCP の設定（.mcp.json を作成）
# 上記「GitHub MCP の設定」セクションを参照

# 3. パーミッションの設定（.claude/settings.local.json を作成）
# 上記「パーミッション設定ガイド」セクションを参照

# 4. 環境チェック
/code:setup-dev-env --fix

# 5. 作業ブランチの作成
git checkout -b feature/your-feature-name
```

### セッション開始時のチェック

新しいセッションを開始するたびに、以下を実行することを推奨します:

```bash
/code:setup-dev-env
```

これにより、Node.js バージョン、依存パッケージ、ビルド状態、Git状態、GitHub MCP、パーミッションが一括で確認されます。

---

## FAQ

### Q: Dev Cycle はどのようなプロジェクトで使えますか？

Node.js/TypeScript プロジェクトを主な対象としています（`npm`, `vitest`, `tsc`, `eslint` を使用）。ただし、Sprint のフェーズ構造やAuditの原則チェックは言語非依存の概念であり、スキルのカスタマイズにより他の技術スタックにも適用可能です。

### Q: 全サイクルを実行せず、一部だけ使えますか？

はい。各スキルは独立して実行可能です:
- `/code:sprint-impl` — 実装のみ
- `/code:audit-compliance` — 監査のみ
- `/code:shipping-pr` — PR作成のみ
- `/code:retrospective` — 振り返りのみ

### Q: Sandbox を有効にしないと使えませんか？

Sandbox なしでも使えますが、`ask` パーミッションの操作のたびに確認ダイアログが表示されます。4ステージの自律実行中にこれが繰り返し発生すると、自律性が大きく損なわれます。快適な利用には `sandbox.enabled: true` + `autoAllowBashIfSandboxed: true` を推奨します。

### Q: コードレビューで問題が見つかり続けたらどうなりますか？

Ship ステージのコードレビュー修正ループは **最大3回** です。3回の修正後も critical/important な問題が残る場合、Dev Cycle は停止し、残りの問題を報告します。この場合は手動で修正を行い、再度 `/code:shipping-pr` を実行してください。

### Q: コンテキストが尽きた場合、最初からやり直しですか？

いいえ。各ステージは自己完結型で設計されているため、途中から再開できます。`.claude/dev-cycle.state.json` に現在のステージが記録されているので、該当するスキルを直接呼び出すだけです。詳しくは「コンテキスト断絶からの復旧」セクションを参照してください。

### Q: `deny` に設定した操作を Dev Cycle が実行しようとすることはありますか？

ありません。`deny` のパーミッションは Layer 1 のシステムレベルで拒否されるため、Dev Cycle のどのステージからも実行不可能です。Sandbox モードであっても `deny` は有効です。

### Q: GitHub MCP の代わりに `gh` CLI を使えますか？

Dev Cycle のスキル内では GitHub MCP Server の使用が推奨されています。ただし、一部の操作（`gh pr view` 等の読み取り操作）は `gh` CLI でも可能です。Issue作成やPR作成は MCP を使うことで、より構造化されたデータのやり取りが可能になります。

---

## 関連ドキュメント

- [README.md](../README.md) — プロジェクト概要
- [plugins/code/README.md](../plugins/code/README.md) — code プラグインの全機能リファレンス
- [specifications.md](./specifications.md) — マーケットプレイス・プラグイン仕様
- [development-guide.md](./development-guide.md) — プラグイン開発ガイド
