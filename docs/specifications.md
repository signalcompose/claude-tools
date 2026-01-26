# Marketplace Specifications

> **参照**: [Claude Code 公式ドキュメント](https://code.claude.com/docs/en/plugin-marketplaces)

## 概要

claude-toolsはClaude Codeプラグインを配布するためのマーケットプレイスリポジトリ

## ファイル配置

```
.claude-plugin/
└── marketplace.json    # マーケットプレイス定義（必須）
```

## marketplace.json 仕様

**配置場所**: `.claude-plugin/marketplace.json`

### 必須フィールド

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "string",           // マーケットプレイス識別子（必須）
  "owner": {                  // オーナー情報（必須）
    "name": "string",
    "email": "string"
  },
  "plugins": []               // プラグイン配列（必須）
}
```

### プラグインエントリ

```json
{
  "name": "string",           // プラグイン識別子（必須）
  "description": "string",    // 説明
  "source": "string|object",  // プラグイン取得元（必須）
  "category": "string",       // カテゴリ（例: productivity, developer-tools）
  "homepage": "string",       // ホームページURL
  "keywords": ["string"],     // 検索用キーワード
  "tags": ["string"],         // タグ
  "version": "string",        // バージョン（オプション）
  "author": {                 // 作者情報（オプション）
    "name": "string",
    "email": "string"
  },
  "license": "string",        // ライセンス（例: MIT）
  "strict": true              // plugin.jsonを必須にするか（デフォルト: true）
}
```

### source フィールドの形式

`source` は複数の形式に対応:

**相対パス**（マーケットプレイス内のプラグイン）:
```json
"source": "./plugins/my-plugin"
```

**GitHub リポジトリ**:
```json
"source": {
  "source": "github",
  "repo": "owner/repo",
  "ref": "v1.0.0",     // オプション: ブランチ、タグ、コミット
  "sha": "abc123..."   // オプション: 特定のコミットSHA
}
```

**Git URL**:
```json
"source": {
  "source": "url",
  "url": "https://gitlab.com/team/plugin.git",
  "ref": "main"        // オプション
}
```

---

## plugin.json 仕様

**配置場所**: `.claude-plugin/plugin.json`

> **参照**: [Plugins reference](https://code.claude.com/docs/en/plugins-reference)

### 基本構造

```json
{
  "name": "string",           // プラグイン識別子（必須）
  "description": "string",    // 説明
  "version": "string",        // セマンティックバージョン
  "author": {
    "name": "string",
    "email": "string"
  },
  "repository": "string",     // リポジトリURL
  "homepage": "string",       // ホームページURL
  "license": "string",        // ライセンス（MIT推奨）
  "keywords": ["string"]      // 検索用キーワード
}
```

### 拡張フィールド

```json
{
  "commands": "string|array",    // カスタムコマンドパス
  "agents": "string|array",      // エージェントファイル
  "skills": "string|array",      // スキルディレクトリ
  "hooks": "string|object",      // フック設定
  "mcpServers": "string|object", // MCPサーバー設定
  "lspServers": "string|object"  // LSPサーバー設定
}
```

### フィールド詳細

| フィールド | タイプ | 説明 | 例 |
|-----------|--------|------|-----|
| `name` | string | 一意の識別子（ケバブケース） | `"my-plugin"` |
| `version` | string | セマンティックバージョン | `"1.0.0"` |
| `description` | string | プラグインの説明 | `"Deployment tools"` |
| `author` | object | 作者情報 | `{"name": "Team"}` |
| `homepage` | string | ドキュメントURL | `"https://..."` |
| `repository` | string | リポジトリURL | `"https://github.com/..."` |
| `license` | string | ライセンス | `"MIT"` |
| `keywords` | array | 検索用キーワード | `["deploy", "ci"]` |
| `commands` | string\|array | コマンドパス | `"./commands/"` |
| `agents` | string\|array | エージェントパス | `"./agents/"` |
| `skills` | string\|array | スキルパス | `"./skills/"` |
| `hooks` | string\|object | フック設定 | `"./hooks.json"` |
| `mcpServers` | string\|object | MCP設定 | `"./.mcp.json"` |
| `lspServers` | string\|object | LSP設定 | `"./.lsp.json"` |

### 環境変数

プラグイン内で `${CLAUDE_PLUGIN_ROOT}` を使用してプラグインのルートディレクトリを参照可能

---

## プラグインディレクトリ構成

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json           # 必須：メタデータのみ
├── commands/                  # コマンド（ルートに配置）
│   └── my-command.md
├── agents/                    # エージェント（ルートに配置）
│   └── my-agent.md
├── skills/                    # スキル（ルートに配置）
│   └── my-skill/
│       └── SKILL.md
├── hooks/                     # フック設定（ルートに配置）
│   └── hooks.json
├── .mcp.json                  # MCP設定（ルートに配置）
├── .lsp.json                  # LSP設定（ルートに配置）
├── LICENSE
└── README.md
```

**重要**: `.claude-plugin/` には `plugin.json` のみ配置。commands, agents, skills等は**プラグインルート**に配置

---

## プラグイン要件

各プラグインは以下を満たす必要がある：

1. `.claude-plugin/plugin.json` を含む（Claude Code plugin形式）
2. **MIT License**（推奨）

**配置方法**:
- **Submodule**: 独立したGitHubリポジトリをサブモジュールとして配置
- **Subtree**: Git subtreeとして管理
- **Direct**: マーケットプレイス内に直接配置

---

## CLI コマンド

> **参照**: [Discover plugins](https://code.claude.com/docs/en/discover-plugins)

### マーケットプレイス管理

```bash
# マーケットプレイス追加（GitHub リポジトリ）
/plugin marketplace add signalcompose/claude-tools

# マーケットプレイス追加（ローカルディレクトリ）
/plugin marketplace add ./my-marketplace

# マーケットプレイス追加（Git URL）
/plugin marketplace add https://gitlab.com/team/plugins.git

# マーケットプレイス追加（リモートURL）
/plugin marketplace add https://example.com/marketplace.json

# マーケットプレイス一覧
/plugin marketplace list

# マーケットプレイス更新
/plugin marketplace update claude-tools

# マーケットプレイス削除
/plugin marketplace remove claude-tools
```

### プラグイン管理

```bash
# プラグインインストール（形式: plugin-name@marketplace-name）
/plugin install cvi@claude-tools

# スコープ指定でインストール
/plugin install cvi@claude-tools --scope project  # チーム共有
/plugin install cvi@claude-tools --scope user     # ユーザー設定（デフォルト）
/plugin install cvi@claude-tools --scope local    # ローカル設定

# プラグインアンインストール
/plugin uninstall cvi@claude-tools

# プラグイン無効化（アンインストールせずに無効化）
/plugin disable cvi@claude-tools

# プラグイン有効化
/plugin enable cvi@claude-tools

# プラグイン更新
/plugin update cvi@claude-tools
```

### 検証

```bash
# マーケットプレイス検証
/plugin validate .

# CLI から検証
claude plugin validate .
```

### インタラクティブUI

```bash
# プラグイン管理UI起動
/plugin
```

タブ:
- **Discover**: 利用可能なプラグインを閲覧
- **Installed**: インストール済みプラグインを管理
- **Marketplaces**: マーケットプレイスを管理
- **Errors**: プラグイン読み込みエラーを表示

---

## 公式ドキュメントリンク

| ドキュメント | URL |
|-------------|-----|
| プラグイン作成ガイド | https://code.claude.com/docs/en/plugins |
| プラグイン技術リファレンス | https://code.claude.com/docs/en/plugins-reference |
| マーケットプレイス作成 | https://code.claude.com/docs/en/plugin-marketplaces |
| プラグイン検出・インストール | https://code.claude.com/docs/en/discover-plugins |
