# Development Guide

## 開発原則

- **DDD**: ドキュメント駆動開発 - 仕様変更はドキュメントから
- **DRY**: 重複を避ける - 共通設定は一箇所で管理

## プラグイン追加手順

### 1. プラグインリポジトリの準備

プラグインは独立したリポジトリとして存在する必要がある

```bash
# 例: signalcompose/new-plugin
```

### 2. サブモジュールとして追加

```bash
git submodule add https://github.com/signalcompose/<plugin>.git plugins/<plugin>
```

### 3. marketplace.json を更新

```json
{
  "plugins": [
    // 既存のプラグイン...
    {
      "name": "<plugin>",
      "description": "説明",
      "path": "./plugins/<plugin>",
      "keywords": ["keyword1", "keyword2"]
    }
  ]
}
```

### 4. README.md を更新

プラグイン一覧テーブルに新しいプラグインを追加

### 5. コミット・プッシュ

```bash
git add .
git commit -m "feat(plugins): add <plugin>"
git push
```

## プラグイン更新手順

```bash
# 特定プラグインを最新に更新
git submodule update --remote plugins/<plugin>

# コミット
git add plugins/<plugin>
git commit -m "chore(plugins): update <plugin> to latest"
git push
```

## テスト

プラグイン追加後、以下を確認：

1. `marketplace.json` が有効なJSON
2. サブモジュールが正しく参照されている
3. `/plugin add signalcompose/claude-tools` でインストール可能
