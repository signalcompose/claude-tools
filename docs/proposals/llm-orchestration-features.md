# LLMオーケストレーション機能提案

> 参考プロジェクト: [opencode](https://github.com/anomalyco/opencode), [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)

## 概要

opencode と oh-my-opencode の分析に基づき、claude-tools の各プラグインに追加できる LLM オーケストレーション機能を提案します。

---

## 参考プロジェクトの主要機能

### opencode

| 機能 | 説明 |
|------|------|
| マルチプロバイダー | Claude, OpenAI, Google, ローカルモデルをシームレスに切り替え |
| 複数エージェント | Build Agent（開発）、Plan Agent（計画）、General Subagent（汎用） |
| クライアント/サーバー設計 | リモート操作対応、モバイルクライアント可能 |
| LSPサポート | 言語サーバープロトコル統合 |

### oh-my-opencode (Sisyphus)

| 機能 | 説明 |
|------|------|
| 専門エージェントチーム | Prometheus（計画）、Oracle（設計）、Frontend Engineer（UI）、Librarian（ドキュメント）、Explore（検索） |
| モデル別タスク委譲 | UI作業→Gemini、戦略→GPT、検索→Haiku |
| バックグラウンド並列実行 | 複数エージェントが同時に作業、コンテキストオーバーヘッド削減 |
| LSP/AST統合 | 確定的リファクタリング（生成のみに依存しない） |
| ultraworkモード | 積極的コンテキスト最適化、人間介入最小化 |

---

## 提案1: orchestrator プラグイン（新規）

### 概要

LLM間のタスク委譲とワークフロー管理を行う中央オーケストレーターを新規作成

### コマンド

| コマンド | 説明 |
|----------|------|
| `/orch:plan <task>` | タスクを分解し、適切なLLM/エージェントに割り当て |
| `/orch:team` | 利用可能なエージェント一覧と現在のステータス |
| `/orch:delegate <agent> <task>` | 特定エージェントにタスクを委譲 |
| `/orch:parallel <task1> <task2> ...` | 複数タスクを並列実行 |
| `/orch:status` | 実行中タスクのステータス確認 |

### アーキテクチャ

```
orchestrator
├── agents/
│   ├── planner.md      # タスク分解・計画（Claude Sonnet）
│   ├── researcher.md   # 調査・情報収集（Gemini/Kiro/Codex連携）
│   ├── coder.md        # コード実装（Claude Opus）
│   ├── reviewer.md     # レビュー（code-review連携）
│   └── explorer.md     # コードベース探索（Haiku）
├── workflows/
│   ├── feature.md      # 機能実装ワークフロー
│   ├── bugfix.md       # バグ修正ワークフロー
│   └── refactor.md     # リファクタリングワークフロー
└── config.yml          # エージェント設定・モデル割り当て
```

### 設定例

```yaml
# ~/.claude/orchestrator/config.yml
agents:
  planner:
    model: claude-sonnet
    role: "タスク分解と計画立案"

  researcher:
    providers:
      - gemini  # Web検索
      - kiro    # AWS関連
      - codex   # OpenAI
    strategy: auto  # タスクに応じて自動選択

  coder:
    model: claude-opus
    role: "実装"

  reviewer:
    plugin: code-review
    role: "品質・セキュリティレビュー"

workflows:
  default: feature
  auto_delegate: true
```

---

## 提案2: gemini プラグイン拡張

### 現状

- Web検索のみ（`/gemini:search`）

### 追加機能

| コマンド | 説明 |
|----------|------|
| `/gemini:frontend <task>` | Gemini 2.5 ProでUI/UXタスクを実行 |
| `/gemini:vision <image> <prompt>` | 画像分析・UI設計レビュー |
| `/gemini:code <file>` | Geminiでコード分析（セカンドオピニオン） |

### 実装例

```markdown
<!-- commands/frontend.md -->
# /gemini:frontend

Gemini 2.5 ProにUI/フロントエンドタスクを委譲

## 使用例

\`\`\`
/gemini:frontend Create a responsive navigation component
/gemini:frontend Review this React component for accessibility
\`\`\`

## 処理フロー

1. コンテキストを収集（関連ファイル、設計ドキュメント）
2. Gemini CLIにタスクを送信（--model gemini-2.5-pro）
3. 結果をClaudeに返し、統合を提案
```

---

## 提案3: codex プラグイン拡張

### 現状

- リサーチ（`/codex:research`）
- コードレビュー（`/codex:review`）

### 追加機能

| コマンド | 説明 |
|----------|------|
| `/codex:architect <topic>` | アーキテクチャ設計相談（Oracle的役割） |
| `/codex:debug <error>` | デバッグ支援（エラー分析） |
| `/codex:compare <question>` | Claude vs Codex の回答比較 |

### 使用例

```bash
# アーキテクチャ相談
/codex:architect How should I structure a microservices auth system?

# デバッグ支援
/codex:debug TypeError: Cannot read property 'map' of undefined

# 回答比較
/codex:compare What's the best way to handle state in React?
```

---

## 提案4: kiro プラグイン拡張

### 現状

- AWSリサーチ（`/kiro:research`）

### 追加機能

| コマンド | 説明 |
|----------|------|
| `/kiro:troubleshoot <error>` | AWSエラーのインタラクティブ診断 |
| `/kiro:optimize <resource>` | コスト/パフォーマンス最適化提案 |
| `/kiro:iac <description>` | Infrastructure as Code生成（CDK/Terraform） |

---

## 提案5: ypm プラグイン拡張

### 現状

- プロジェクト状態管理
- タスク管理（next tasks）

### 追加機能（oh-my-opencodeのPrometheusに相当）

| コマンド | 説明 |
|----------|------|
| `/ypm:decompose <feature>` | フィーチャーをタスクに分解 |
| `/ypm:assign <task> <agent>` | タスクをエージェントに割り当て |
| `/ypm:sprint` | 現在のスプリント概要とタスク進捗 |
| `/ypm:retrospective` | 完了タスクの振り返り生成 |

### タスク分解例

```yaml
# /ypm:decompose "ユーザー認証機能の追加"
feature: ユーザー認証機能
tasks:
  - id: auth-1
    name: 認証アーキテクチャ設計
    agent: codex  # Oracle役
    status: pending

  - id: auth-2
    name: API設計・仕様書作成
    agent: claude
    depends_on: [auth-1]

  - id: auth-3
    name: バックエンド実装
    agent: claude
    depends_on: [auth-2]

  - id: auth-4
    name: フロントエンドUI実装
    agent: gemini  # Frontend Engineer役
    depends_on: [auth-2]

  - id: auth-5
    name: テスト・レビュー
    agent: code-review
    depends_on: [auth-3, auth-4]
```

---

## 提案6: code-review プラグイン拡張

### 現状

- ステージング変更のレビュー
- TruffleHogセキュリティスキャン

### 追加機能

| コマンド | 説明 |
|----------|------|
| `/code:multi-review` | Claude + Codex でダブルレビュー |
| `/code:lsp-check` | LSPを使用した確定的コードチェック |
| `/code:refactor-safe <file>` | AST-basedの安全なリファクタリング |

### ダブルレビュー例

```markdown
# /code:multi-review

1. Claudeでコードレビュー実行
2. Codexでコードレビュー実行
3. 両者の指摘を統合・比較
4. 一致点 = 高優先度の問題
5. 差異点 = 検討が必要な項目
```

---

## 提案7: 共通インフラ

### 7.1 バックグラウンドタスク実行

```yaml
# 全プラグイン共通
background:
  enabled: true
  max_concurrent: 3
  notification:
    on_complete: cvi  # CVI連携で完了通知
    on_error: true
```

### 7.2 コンテキスト共有

```yaml
# ~/.claude/orchestrator/context.yml
shared_context:
  - project_structure  # ディレクトリ構造
  - recent_changes     # 最近のgit変更
  - documentation      # CLAUDE.md, README
  - dependencies       # package.json等
```

### 7.3 モデル選択戦略

```yaml
model_strategy:
  web_search: gemini
  aws_expertise: kiro
  code_generation: claude-opus
  quick_queries: claude-haiku
  architecture: codex
  ui_development: gemini-2.5-pro
```

---

## 実装優先度

### Phase 1: 既存プラグイン拡張（低コスト・高価値）

1. **gemini**: `/gemini:frontend`, `/gemini:vision`
2. **codex**: `/codex:architect`, `/codex:debug`
3. **kiro**: `/kiro:troubleshoot`

### Phase 2: 統合機能（中コスト）

1. **code-review**: `/code:multi-review`
2. **ypm**: `/ypm:decompose`, `/ypm:assign`

### Phase 3: オーケストレーター（高コスト・高価値）

1. **orchestrator**: 新規プラグイン作成
2. バックグラウンドタスク実行基盤
3. 自動タスク委譲ワークフロー

---

## 技術的考慮事項

### コンテキスト分離

既存プラグインは `context: fork` を使用してコンテキスト汚染を防止。
オーケストレーターでも同様に、各エージェントの出力を分離して管理。

### 認証管理

| プラグイン | 認証方式 |
|------------|----------|
| gemini | OAuth (`~/.gemini/`) |
| codex | OAuth/API Key (`~/.codex/`) |
| kiro | AWS Credentials |

### エラーハンドリング

```yaml
fallback_strategy:
  gemini_unavailable: use_claude_websearch
  codex_unavailable: skip_or_claude
  kiro_unavailable: claude_with_aws_docs
```

---

## まとめ

oh-my-opencode の「チームベースエージェント」アプローチを参考に、既存の claude-tools プラグインを強化することで、マルチLLMオーケストレーションを実現できます。

**キーポイント**:
- 各LLMの強みを活かしたタスク委譲
- 既存プラグイン（gemini, codex, kiro）の連携強化
- バックグラウンド並列実行による効率化
- ypmとの統合によるプロジェクト全体の可視化

---

## 参考リンク

- [opencode](https://github.com/anomalyco/opencode) - オープンソースAIコーディングエージェント
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode) - Sisyphusマルチエージェントフレームワーク
