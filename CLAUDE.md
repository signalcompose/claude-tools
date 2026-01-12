# claude-tools - Project Configuration

## プロジェクト概要

SignalComposeが提供するClaude Codeプラグインのマーケットプレイス

| 項目 | 内容 |
|------|------|
| **リポジトリ** | signalcompose/claude-tools |
| **種別** | マーケットプレイス（プラグイン配布） |
| **ライセンス** | MIT |

## 技術スタック

- Git Submodules（プラグイン管理）
- JSON（marketplace.json）
- Markdown（ドキュメント）

## セッション開始時の手順

1. **ドキュメント確認**
   - `docs/INDEX.md` を読む
   - 必要に応じて各ドキュメントを参照

2. **作業ブランチ作成**
   ```bash
   git checkout main
   git pull
   git checkout -b feature/<作業内容>
   ```

## 開発原則

### DDD（Documentation Driven Development）

- ドキュメントが真実の唯一の源
- 仕様変更はドキュメントから

### コミット規約

**タイトル**: 英語（Conventional Commits）
**本文**: 日本語

```
<type>(<scope>): <subject>

<日本語の説明>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**Type一覧**:
- `feat`: 新機能（プラグイン追加等）
- `fix`: 修正
- `docs`: ドキュメント
- `chore`: 設定変更等

## Git Workflow（軽量版）

### ブランチ戦略

- `main`: 本番ブランチ
- `feature/*`: 作業ブランチ

### 作業フロー

1. `main`から`feature/*`ブランチを作成
2. 変更を実装・コミット
3. PR作成 → マージ

### 禁止事項

- ❌ `main`への直接コミット（推奨レベル）
- ❌ Force Push
- ❌ Squashマージ

## よくある操作

### プラグイン追加

```bash
# 1. サブモジュール追加
git submodule add https://github.com/signalcompose/<plugin>.git plugins/<plugin>

# 2. .claude-plugin/marketplace.json更新
# plugins配列に新しいプラグイン情報を追加

# 3. README.md更新
# Available Pluginsテーブルに追加

# 4. コミット
git add .
git commit -m "feat(plugins): add <plugin>"
```

### プラグイン更新

```bash
git submodule update --remote plugins/<plugin>
git add plugins/<plugin>
git commit -m "chore(plugins): update <plugin> to latest"
```

## ディレクトリ構成

```
claude-tools/
├── .claude-plugin/
│   └── marketplace.json    # プラグインカタログ
├── plugins/            # サブモジュール
│   ├── cvi/           # CVI plugin
│   └── ypm/           # YPM plugin
├── docs/              # ドキュメント
│   ├── INDEX.md
│   ├── specifications.md
│   ├── architecture.md
│   ├── development-guide.md
│   └── onboarding.md
├── .claude/           # Claude Code設定
│   └── settings.json
├── .github/           # GitHub設定
│   └── pull_request_template.md
└── CLAUDE.md          # このファイル
```

## 参考リソース

- [docs/INDEX.md](./docs/INDEX.md) - ドキュメント索引
- [README.md](./README.md) - プロジェクト概要
