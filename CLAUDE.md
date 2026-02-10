# claude-tools - Project Configuration

## プロジェクト概要

SignalComposeが提供するClaude Codeプラグインのマーケットプレイス

| 項目 | 内容 |
|------|------|
| **リポジトリ** | signalcompose/claude-tools |
| **種別** | マーケットプレイス（プラグイン配布） |
| **ライセンス** | MIT |

## 技術スタック

- Git Subtrees（プラグイン管理）
- JSON（marketplace.json）
- Markdown（ドキュメント）

## セッション開始時の手順

1. **ドキュメント確認**
   - `docs/INDEX.md` を読む
   - 必要に応じて各ドキュメントを参照

2. **作業ブランチ作成**
   ```bash
   git checkout main
   git pull
   git checkout -b feature/<作業内容>
   ```

## 開発原則

### DDD（Documentation Driven Development）

- ドキュメントが真実の唯一の源
- 仕様変更はドキュメントから

### コミット規約

**タイトル**: 英語（Conventional Commits）
**本文**: 日本語

```
<type>(<scope>): <subject>

<日本語の説明>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

**Type一覧**:
- `feat`: 新機能（プラグイン追加等）
- `fix`: 修正
- `docs`: ドキュメント
- `chore`: 設定変更等

## Git Workflow（軽量版）

### ブランチ戦略

- `main`: 本番ブランチ
- `feature/*`: 作業ブランチ

### 作業フロー

1. `main`から`feature/*`ブランチを作成
2. 変更を実装・コミット
3. PR作成 → マージ

### 禁止事項

- ❌ `main`への直接コミット（推奨レベル）
- ❌ Force Push
- ❌ Squashマージ

### バージョン管理ルール

**Hash-based Versioning**:
- プラグインはGit commit hashで自動管理（Anthropic公式と同様）
- `plugin.json`にversionフィールドは不要
- Claude Codeがインストール時にcommit SHAを記録

**利点**:
- 手動バージョン更新のオーバーヘッド削減
- 頻繁な修正に対応しやすい
- 正確なコード追跡が可能

**PRマージ後**:
- Subtree管理プラグインは各リポジトリに変更を反映

```bash
# CVI
git subtree push --prefix=plugins/cvi https://github.com/signalcompose/cvi.git main

# YPM
git subtree push --prefix=plugins/ypm https://github.com/signalcompose/ypm.git main
```

**Subtree管理プラグイン一覧**:
| Plugin | Repository |
|--------|------------|
| cvi | signalcompose/cvi |
| ypm | signalcompose/ypm |

## よくある操作

### プラグイン追加（Subtree）

```bash
# 1. Subtree追加
git subtree add --prefix=plugins/<plugin> https://github.com/signalcompose/<plugin>.git main --squash

# 2. .claude-plugin/marketplace.json更新
# plugins配列に新しいプラグイン情報を追加

# 3. README.md更新
# Available Pluginsテーブルに追加

# 4. コミット
git add .
git commit -m "feat(plugins): add <plugin>"
```

### プラグイン更新（Subtree）

```bash
git subtree pull --prefix=plugins/<plugin> https://github.com/signalcompose/<plugin>.git main --squash
git commit -m "chore(plugins): update <plugin> from upstream"
```

### Subtree差分確認（上流との比較）

**⚠️ 重要: FETCH_HEAD上書きに注意**

複数リポジトリを連続でfetchすると、FETCH_HEADが上書きされる。
**必ず各fetchの直後に比較を行うこと。**

```bash
# ✅ 正しい手順: 各プラグインを個別に確認
# 変数を使用（Subtree管理プラグイン一覧を参照）
PLUGIN=<plugin-name>
REPO=signalcompose/<plugin-name>

git fetch https://github.com/${REPO}.git main
git diff HEAD:plugins/${PLUGIN} FETCH_HEAD --stat  # ← 即座に比較
```

```bash
# ❌ 間違った手順: 連続fetchでFETCH_HEADが上書きされる
git fetch https://github.com/signalcompose/plugin-a.git main
git fetch https://github.com/signalcompose/plugin-b.git main  # FETCH_HEAD上書き!
git diff HEAD:plugins/plugin-a FETCH_HEAD  # AとBを比較してしまう（誤報の原因）
```

**代替手段: GitHub APIで確認（推奨）**

```bash
# README.mdの内容を直接確認（FETCH_HEAD問題を回避）
REPO=signalcompose/<plugin-name>
gh api repos/${REPO}/contents/README.md --jq '.content' | base64 -d | head -5
```

**全Subtreeプラグインの一括確認スクリプト例**

```bash
# Subtree管理プラグイン一覧からループ処理
for plugin in cvi ypm; do
  echo "=== Checking ${plugin} ==="
  git fetch https://github.com/signalcompose/${plugin}.git main 2>/dev/null
  git diff HEAD:plugins/${plugin} FETCH_HEAD --stat 2>/dev/null || echo "No diff"
done
```

## ディレクトリ構成

```
claude-tools/
├── .claude-plugin/
│   └── marketplace.json    # プラグインカタログ
├── plugins/            # Subtree/Direct
│   ├── cvi/           # CVI plugin (subtree)
│   ├── ypm/           # YPM plugin (subtree)
│   ├── chezmoi/       # chezmoi plugin
│   ├── code/          # code plugin
│   ├── utils/         # utils plugin
│   ├── codex/         # codex plugin
│   ├── gemini/        # gemini plugin
│   └── kiro/          # kiro plugin
├── docs/              # ドキュメント
│   ├── INDEX.md
│   ├── specifications.md
│   ├── architecture.md
│   ├── development-guide.md
│   └── onboarding.md
├── .claude/           # Claude Code設定
│   ├── settings.json
│   └── skills/        # プロジェクト専用スキル
├── .github/           # GitHub設定
│   └── pull_request_template.md
└── CLAUDE.md          # このファイル
```

## スキル開発ガイダンス

### 参考情報

| 情報源 | URL/場所 | 用途 |
|--------|----------|------|
| Anthropic公式ガイド | [The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf) | 設計原則・ベストプラクティス |
| 既存スキル実装 | `plugins/*/skills/*/SKILL.md` | 実装パターンの参考 |

### コマンド vs スキル の使い分け

| 用途 | 使うべきもの | 理由 |
|------|-------------|------|
| スクリプト実行 | **コマンド** | `!`で即時実行、`${CLAUDE_PLUGIN_ROOT}`展開 |
| 専門知識提供 | **スキル** | Claudeへのガイドライン |
| 両方必要 | **コマンド + スキル参照** | コマンドからスキルを参照 |

### `${CLAUDE_PLUGIN_ROOT}` 環境変数

**確認済み動作（2026-02-02）**:
- コマンド内の `!` 構文で `${CLAUDE_PLUGIN_ROOT}` が正しく展開される
- 展開先: `~/.claude/plugins/cache/<marketplace>/<plugin>/<commit-hash>/`
- 例: `/Users/yamato/.claude/plugins/cache/claude-tools/code/7d9cd8ee6154`

**使用例**:
```markdown
# コマンド内で使用
Check: !`echo "CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}"`
Script: !`bash ${CLAUDE_PLUGIN_ROOT}/scripts/my-script.sh`
```

**注意**: コードブロック形式（```bash）では展開されない。`!` 構文が必須。

### 主要ベストプラクティス

1. **Progressive Disclosure**: frontmatter（常時読込）→ 本文（必要時）→ references/（詳細）
2. **決定論的検証**: クリティカルなチェックはスクリプトで実装（言語指示より確実）
3. **スクリプトバンドル**: 重要な処理は外部スクリプト化し、SKILL.mdから呼び出す
4. **エージェント委譲**: MANDATORYと明記し、正確なagent名とパラメータを指定
5. **コマンドで`!`実行**: `` !`bash ${CLAUDE_PLUGIN_ROOT}/scripts/xxx.sh` ``

## 参考リソース

- [docs/INDEX.md](./docs/INDEX.md) - ドキュメント索引
- [README.md](./README.md) - プロジェクト概要
