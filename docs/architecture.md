# Architecture

## リポジトリ構成

```
claude-tools/
├── marketplace.json        # プラグインカタログ（メタデータ）
├── plugins/
│   ├── cvi/               # Git submodule → signalcompose/cvi
│   └── ypm/               # Git submodule → signalcompose/ypm (coming soon)
├── docs/
│   ├── INDEX.md
│   ├── specifications.md
│   ├── architecture.md
│   └── development-guide.md
├── CLAUDE.md
└── README.md
```

## サブモジュール戦略

### なぜサブモジュールか

1. **独立した開発** - 各プラグインは独自のリポジトリで管理
2. **バージョン管理** - マーケットプレイスは特定のコミットを参照
3. **シンプルな配布** - 1つのリポジトリで複数プラグインをインストール可能

### サブモジュール管理

```bash
# 追加
git submodule add https://github.com/signalcompose/<plugin>.git plugins/<plugin>

# 更新
git submodule update --remote plugins/<plugin>

# クローン時
git clone --recursive https://github.com/signalcompose/claude-tools.git
```

## データフロー

```
User → /plugin add signalcompose/claude-tools
         ↓
Claude Code → Clone repository (with submodules)
         ↓
marketplace.json → Discover available plugins
         ↓
plugins/* → Load plugin configurations
```
