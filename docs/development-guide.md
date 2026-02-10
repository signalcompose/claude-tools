# Development Guide

> **参照**: [Claude Code プラグイン開発ガイド](https://code.claude.com/docs/en/plugins)

## 開発原則

- **DDD**: ドキュメント駆動開発 - 仕様変更はドキュメントから
- **DRY**: 重複を避ける - 共通設定は一箇所で管理

---

## プラグインの基本構成

各プラグインは以下の構成に従う:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json           # 必須：メタデータのみ
├── commands/                  # コマンド（ルートに配置）
│   ├── status.md
│   └── run.md
├── agents/                    # エージェント（ルートに配置）
│   └── my-agent.md
├── skills/                    # スキル（ルートに配置）
│   └── my-skill/
│       └── SKILL.md
├── LICENSE                    # MIT推奨
└── README.md
```

**重要**: `.claude-plugin/` には `plugin.json` のみ配置。コマンドやスキルは**プラグインルート**に配置

### plugin.json 例

```json
{
  "name": "my-plugin",
  "description": "My awesome plugin",
  "author": {
    "name": "SignalCompose"
  },
  "repository": "https://github.com/signalcompose/my-plugin",
  "license": "MIT",
  "keywords": ["example", "demo"]
}
```

---

## プラグイン追加手順

### 方式1: Subtreeとして追加（推奨）

独立したリポジトリを持つプラグインに適している。双方向の同期が可能。

#### 1. プラグインリポジトリの準備

```bash
# 例: signalcompose/new-plugin
# リポジトリにはplugin.jsonとcommandsを含める
```

#### 2. Subtreeとして追加

```bash
git subtree add --prefix=plugins/<plugin> https://github.com/signalcompose/<plugin>.git main --squash
```

#### 3. marketplace.json を更新

```json
{
  "plugins": [
    {
      "name": "<plugin>",
      "description": "説明",
      "source": "./plugins/<plugin>",
      "category": "productivity",
      "homepage": "https://github.com/signalcompose/<plugin>"
    }
  ]
}
```

#### 4. README.md を更新

プラグイン一覧テーブルに新しいプラグインを追加

#### 5. コミット・プッシュ

```bash
git add .
git commit -m "feat(plugins): add <plugin>"
git push
```

### 方式2: 直接配置

マーケットプレイス内に直接プラグインを作成する場合。

#### 1. プラグインディレクトリ作成

```bash
mkdir -p plugins/<plugin>/.claude-plugin
mkdir -p plugins/<plugin>/commands
```

#### 2. plugin.json 作成

```bash
cat > plugins/<plugin>/.claude-plugin/plugin.json << 'EOF'
{
  "name": "<plugin>",
  "description": "説明",
  "author": { "name": "SignalCompose" },
  "license": "MIT"
}
EOF
```

#### 3. コマンド作成

```bash
cat > plugins/<plugin>/commands/my-command.md << 'EOF'
---
description: コマンドの説明
---

# コマンド実装

実行内容をここに記述
EOF
```

#### 4. marketplace.json と README.md を更新

```json
{
  "name": "<plugin>",
  "description": "説明",
  "source": "./plugins/<plugin>",
  "category": "developer-tools"
}
```

---

## プラグイン更新手順

### Subtreeの更新

```bash
# 外部リポジトリから取り込み
git subtree pull --prefix=plugins/<plugin> https://github.com/signalcompose/<plugin>.git main

# マーケットプレイスの変更を外部リポジトリに反映
git subtree push --prefix=plugins/<plugin> https://github.com/signalcompose/<plugin>.git main
```

---

## コマンドの書き方

### 基本構造

```markdown
---
description: コマンドの説明（/pluginのリストに表示される）
---

# コマンドタイトル

Claudeへの指示をここに記述。Markdownで記述可能。

## 手順

1. まず〜を確認
2. 次に〜を実行
3. 最後に〜を報告
```

### 環境変数の使用

```markdown
プラグインのルートは `${CLAUDE_PLUGIN_ROOT}` で参照可能。

例: `${CLAUDE_PLUGIN_ROOT}/scripts/my-script.sh`
```

---

## 検証

プラグイン追加後、以下を確認：

### ローカル検証

```bash
# マーケットプレイス検証
/plugin validate .

# または CLI から
claude plugin validate .
```

### 動作確認

1. `marketplace.json` が有効なJSON
2. 各プラグインの `plugin.json` が存在
3. commands ディレクトリがプラグインルートに配置されている
4. `/plugin marketplace add ./` でローカルインストール可能
5. コマンドが正しく動作する

---

## トラブルシューティング

### プラグインが認識されない

- `.claude-plugin/plugin.json` が存在するか確認
- JSON構文エラーがないか確認
- marketplace.jsonの`source`パスが正しいか確認

### コマンドが表示されない

- `commands/` ディレクトリがプラグインルートにあるか確認
- `.claude-plugin/` 内に置いていないか確認
- Markdownのfrontmatter（`---`で囲まれた部分）が正しいか確認

### 更新が反映されない

- キャッシュをクリア: `/utils:clear-plugin-cache <plugin>`
- Claude Codeを再起動

---

## マーケットプレイス全体のテスト手順

### テストフレームワーク概要

マーケットプレイスのブランチをPR・マージする前に、全プラグインの品質を保証するためのE2Eテストフレームワークを使用します。

### 推奨ワークフロー

#### Phase 1: 静的検証（30-45分、自動化可能）

マニフェスト、ファイル構造、サンドボックス互換性などを自動で検証。

**実行方法**:
```bash
# 各検証スクリプトを順次実行
# 詳細は docs/testing/e2e-test-results-YYYY-MM-DD.md 参照
```

**検証項目**:
1. marketplace.json の構文検証
2. 全プラグインの plugin.json 検証
3. ファイル構造の整合性
4. コマンド/スキルの構文チェック
5. Hooks設定の検証
6. サンドボックス互換性スキャン
7. コマンド名の衝突検出

#### Phase 2: 手動テスト（2-3時間）

実際にプラグインを実行して動作を確認。

**テストガイド**:
- `docs/testing/manual-test-guide-code.md` - codeプラグイン詳細テスト
- `docs/testing/manual-test-guide-cvi.md` - cviプラグイン詳細テスト
- `docs/testing/manual-test-guide-unchanged-plugins.md` - 未変更プラグインのスモークテスト
- `docs/testing/manual-test-guide-plugin-interactions.md` - プラグイン間相互作用テスト

**テストカテゴリ**:
1. **変更されたプラグインの詳細テスト**: 新機能、アーキテクチャ変更の確認
2. **未変更プラグインのスモークテスト**: 基本コマンドの動作確認
3. **プラグイン間相互作用の確認**: Hook共存、連携動作の確認

#### Phase 2補助: インタラクティブプラグインテスト（推奨）

**新機能**: `/plugin-test` スキル（プロジェクト専用）を使用した対話型テスト

```
/plugin-test <plugin-name>
```

**特徴**:
- Phase 1相当の自動検証を即座に実行
- プラグイン種別を自動検出（Hook-based, Voice/Audio, Team/Agent, Utility）
- ステップバイステップで手動テストをガイド
- テスト結果のサマリーを自動生成

**所要時間**: 手動テスト時間を約50%削減（3時間 → 1.5時間）

**使用例**:
```
/plugin-test code
/plugin-test cvi
/plugin-test ypm
```

**詳細**: `.claude/skills/plugin-test/SKILL.md`

---

#### Phase 3: 結果記録（30分）

テスト結果をチェックリスト形式で記録。

**記録先**: `docs/testing/e2e-test-results-YYYY-MM-DD.md`

**記録内容**:
- Phase 1の自動検証結果
- Phase 2の手動テスト結果
- 発見された問題（Critical/Important/Minor）
- マージ可否判定

### 所要時間見積もり

- **完全テスト（従来）**: 3-4時間（Phase 1-3すべて）
- **完全テスト（plugin-test使用）**: 2-2.5時間（Phase 1-3すべて、50%削減）
- **最小限テスト**: 1-1.5時間（変更プラグイン + plugin-test）

### テスト結果の活用

1. **PRマージ判定**: Critical/Important問題がなければマージ可
2. **品質トレンド追跡**: 過去のテスト結果と比較
3. **再利用**: 次回のプラグイン開発でも同じフレームワークを使用

### 参考ドキュメント

- `docs/testing/e2e-test-results-YYYY-MM-DD.md` - テスト結果テンプレート
- `docs/testing/manual-test-guide-*.md` - 各種手動テストガイド

---

## 公式リソース

- [Create plugins](https://code.claude.com/docs/en/plugins)
- [Plugins reference](https://code.claude.com/docs/en/plugins-reference)
- [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
