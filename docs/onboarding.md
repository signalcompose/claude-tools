# Onboarding Guide

新規コントリビューター向けのガイド

## プロジェクト概要

claude-toolsはSignalComposeが提供するClaude Codeプラグインのマーケットプレイス

| 項目 | 内容 |
|------|------|
| リポジトリ | signalcompose/claude-tools |
| 種別 | マーケットプレイス（プラグイン配布） |
| ライセンス | MIT |

## リポジトリ構成

```
claude-tools/
├── .claude-plugin/
│   └── marketplace.json  # プラグインカタログ
├── plugins/              # プラグイン格納
│   ├── cvi/             # 音声通知 (submodule)
│   ├── ypm/             # プロジェクト管理 (submodule)
│   ├── chezmoi/         # dotfiles管理
│   ├── code-review/     # コードレビュー (subtree)
│   ├── utils/           # ユーティリティ
│   ├── codex/           # Codex統合
│   ├── gemini/          # Gemini統合
│   └── kiro/            # Kiro統合
├── docs/                # ドキュメント
│   ├── INDEX.md
│   ├── specifications.md
│   ├── architecture.md
│   ├── development-guide.md
│   ├── onboarding.md
│   └── research/
├── .claude/             # Claude Code設定
├── CLAUDE.md            # プロジェクト設定
└── README.md
```

## 開発環境セットアップ

### 前提条件

- Git
- GitHub CLI (`gh`)
- Claude Code

### クローン

```bash
git clone --recursive https://github.com/signalcompose/claude-tools.git
cd claude-tools
```

### サブモジュール初期化（クローン済みの場合）

```bash
git submodule update --init --recursive
```

## 作業フロー

1. `main` から `feature/*` ブランチを作成
2. 変更を実装
3. コミット（Conventional Commits形式）
4. PR作成
5. レビュー後マージ

```bash
# ブランチ作成
git checkout main
git pull
git checkout -b feature/<作業内容>

# 変更をコミット
git add .
git commit -m "feat(plugins): add new-plugin"

# プッシュ・PR作成
git push -u origin feature/<作業内容>
gh pr create
```

## コミット規約

### フォーマット

```
<type>(<scope>): <subject>  # 英語

<body>  # 日本語（オプション）

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>  # Claude使用時
```

### Type一覧

| Type | 用途 |
|------|------|
| `feat` | 新機能（プラグイン追加等） |
| `fix` | バグ修正 |
| `docs` | ドキュメント |
| `chore` | 雑務（設定変更、依存更新等） |
| `refactor` | リファクタリング |

### 例

```
feat(plugins): add gemini plugin

Gemini CLIを使用したWeb検索機能を追加

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

## よくある操作

### プラグイン追加（サブモジュール）

```bash
git submodule add https://github.com/signalcompose/<plugin>.git plugins/<plugin>
# marketplace.json と README.md を更新
git add .
git commit -m "feat(plugins): add <plugin>"
```

### プラグイン更新（サブモジュール）

```bash
git submodule update --remote plugins/<plugin>
git add plugins/<plugin>
git commit -m "chore(plugins): update <plugin> to latest"
```

### マーケットプレイス検証

```bash
/plugin validate .
```

## ドキュメント一覧

| ドキュメント | 内容 |
|-------------|------|
| [README.md](../README.md) | プロジェクト概要・Quick Start |
| [specifications.md](./specifications.md) | マーケットプレイス・プラグイン仕様 |
| [architecture.md](./architecture.md) | リポジトリ構成・管理方式 |
| [development-guide.md](./development-guide.md) | プラグイン開発ガイド |
| [CLAUDE.md](../CLAUDE.md) | Claude Code用プロジェクト設定 |

## 公式リソース

- [Claude Code プラグイン](https://code.claude.com/docs/en/plugins)
- [プラグイン技術リファレンス](https://code.claude.com/docs/en/plugins-reference)
- [マーケットプレイス](https://code.claude.com/docs/en/plugin-marketplaces)
