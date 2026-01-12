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

1. **独立したGitHubリポジトリ**として存在
2. `.claude-plugin/plugin.json` を含む（Claude Code plugin形式）
3. **MIT License**

## インストール方法

```bash
/plugin marketplace add signalcompose/claude-tools
```
