# Marketplace Specifications

## 概要

claude-toolsはClaude Codeプラグインを配布するためのマーケットプレイスリポジトリ

## ファイル配置

```
.claude-plugin/
└── marketplace.json    # マーケットプレイス定義（必須）
```

## marketplace.json 仕様

**配置場所**: `.claude-plugin/marketplace.json`

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "string",           // マーケットプレイス名
  "description": "string",    // 説明
  "owner": {                  // オーナー情報
    "name": "string",
    "email": "string"
  },
  "plugins": [                // プラグイン一覧
    {
      "name": "string",       // プラグイン名
      "description": "string",// 説明
      "source": "string",     // 相対パス（例: ./plugins/cvi）
      "category": "string",   // カテゴリ（例: productivity）
      "homepage": "string"    // ホームページURL
    }
  ]
}
```

## プラグイン要件

各プラグインは以下を満たす必要がある：

1. `.claude-plugin/plugin.json` を含む（Claude Code plugin形式）
2. **MIT License**

**配置方法**:
- **Submodule**: 独立したGitHubリポジトリをサブモジュールとして配置
- **Direct**: マーケットプレイス内に直接配置

## CLI コマンド

> 参照: [Claude Code 公式ドキュメント](https://code.claude.com/docs/en/discover-plugins)

### マーケットプレイス管理

```bash
# マーケットプレイス追加（GitHub リポジトリ）
/plugin marketplace add signalcompose/claude-tools

# マーケットプレイス追加（ローカルディレクトリ）
/plugin marketplace add ./my-marketplace

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

# プラグインアンインストール
/plugin uninstall cvi@claude-tools

# プラグイン無効化（アンインストールせずに無効化）
/plugin disable cvi@claude-tools

# プラグイン有効化
/plugin enable cvi@claude-tools
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
