# Onboarding Guide

## プロジェクト概要

claude-toolsはSignalComposeが提供するClaude Codeプラグインのマーケットプレイス

## リポジトリ構成

```
claude-tools/
├── marketplace.json    # プラグインカタログ
├── plugins/            # サブモジュール格納
│   └── cvi/           # CVI plugin
├── docs/              # ドキュメント
├── .claude/           # Claude Code設定
└── CLAUDE.md          # プロジェクト設定
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

### サブモジュール更新

```bash
git submodule update --init --recursive
```

## 作業フロー

1. featureブランチを作成
2. 変更を実装
3. コミット（Conventional Commits形式）
4. PR作成
5. マージ

## コミット規約

### フォーマット

```
<type>(<scope>): <subject>  # 英語

<body>  # 日本語
```

### Type一覧

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメント
- `chore`: 雑務（設定変更等）
- `refactor`: リファクタリング

## よくある操作

### プラグイン追加

```bash
git submodule add https://github.com/signalcompose/<plugin>.git plugins/<plugin>
```

### プラグイン更新

```bash
git submodule update --remote plugins/<plugin>
```
