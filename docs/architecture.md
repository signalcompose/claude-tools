# Architecture

## リポジトリ構成

```
claude-tools/
├── .claude-plugin/
│   └── marketplace.json    # プラグインカタログ（必須）
├── plugins/
│   ├── cvi/               # Git submodule → signalcompose/cvi
│   ├── ypm/               # Git submodule → signalcompose/ypm
│   ├── chezmoi/           # Direct（マーケットプレイス内配置）
│   ├── code-review/       # Subtree → signalcompose/cvi
│   ├── utils/             # Direct
│   ├── codex/             # Direct
│   ├── gemini/            # Direct
│   └── kiro/              # Direct
├── docs/
│   ├── INDEX.md
│   ├── specifications.md
│   ├── architecture.md
│   ├── development-guide.md
│   ├── onboarding.md
│   └── research/
├── .claude/               # Claude Code設定
│   └── settings.json
├── CLAUDE.md
└── README.md
```

## プラグイン一覧

| プラグイン | 管理方式 | リポジトリ/配置 | 説明 |
|-----------|---------|----------------|------|
| cvi | Submodule | signalcompose/cvi | 音声通知 |
| ypm | Submodule | signalcompose/ypm | プロジェクト管理 |
| chezmoi | Direct | plugins/chezmoi | dotfiles管理 |
| code | Subtree | plugins/code-review | コードレビュー |
| utils | Direct | plugins/utils | ユーティリティ |
| codex | Direct | plugins/codex | Codex統合 |
| gemini | Direct | plugins/gemini | Gemini統合 |
| kiro | Direct | plugins/kiro | Kiro統合 |

## プラグイン管理方式

### Git Submodule

独立したリポジトリを参照。外部開発者との共同開発に適している。

```bash
# 追加
git submodule add https://github.com/signalcompose/<plugin>.git plugins/<plugin>

# 更新
git submodule update --remote plugins/<plugin>

# クローン時
git clone --recursive https://github.com/signalcompose/claude-tools.git
```

**使用プラグイン**: cvi, ypm

### Git Subtree

外部リポジトリのコードを直接取り込み。双方向の変更反映が可能。

```bash
# プル（外部→マーケットプレイス）
git subtree pull --prefix=plugins/<plugin> https://github.com/signalcompose/<plugin>.git main

# プッシュ（マーケットプレイス→外部）
git subtree push --prefix=plugins/<plugin> https://github.com/signalcompose/<plugin>.git main
```

**使用プラグイン**: code-review

### Direct（直接配置）

マーケットプレイス内に直接配置。シンプルだが独立管理はできない。

**使用プラグイン**: chezmoi, utils, codex, gemini, kiro

## データフロー

```
User → /plugin marketplace add signalcompose/claude-tools
         ↓
Claude Code → Clone repository (with submodules)
         ↓
.claude-plugin/marketplace.json → Discover available plugins
         ↓
plugins/* → Load plugin configurations
         ↓
User → /plugin install <plugin>@claude-tools
         ↓
Claude Code → Copy plugin to cache, register commands
```

## キャッシュ構造

Claude Codeはインストールしたプラグインをキャッシュに保存:

```
~/.claude/plugin-cache/
└── <marketplace-name>/
    └── <plugin-name>/
        ├── .claude-plugin/
        │   └── plugin.json
        ├── commands/
        └── ...
```

> **注意**: マーケットプレイス更新後はキャッシュクリアが必要な場合がある（既知のバグ）

## 設定スコープ

プラグインは3つのスコープでインストール可能:

| スコープ | 保存先 | 共有 |
|---------|--------|------|
| user | `~/.claude/settings.json` | 個人 |
| project | `.claude/settings.json` | チーム |
| local | `.claude/settings.local.json` | ローカルのみ |
