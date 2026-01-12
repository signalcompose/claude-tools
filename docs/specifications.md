# Marketplace Specifications

## 概要

claude-toolsはClaude Codeプラグインを配布するためのマーケットプレイスリポジトリ

## marketplace.json 仕様

```json
{
  "name": "string",           // マーケットプレイス名
  "description": "string",    // 説明
  "version": "string",        // バージョン（semver）
  "plugins": [                // プラグイン一覧
    {
      "name": "string",       // プラグイン名（サブモジュールディレクトリ名）
      "description": "string",// 説明
      "path": "string",       // 相対パス（例: ./plugins/cvi）
      "keywords": ["string"]  // 検索用キーワード
    }
  ]
}
```

## プラグイン要件

各プラグインは以下を満たす必要がある：

1. **独立したGitHubリポジトリ**として存在
2. **plugin.json**を含む（Claude Code plugin形式）
3. **MIT License**

## インストール方法

```bash
/plugin add signalcompose/claude-tools
```
