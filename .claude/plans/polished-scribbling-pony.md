# clear-plugin-cache スクリプトに `-y/--yes` オプションを追加

## 背景

`clear-plugin-cache.sh` スクリプトは、現在 `--all` モード使用時に対話的な確認を要求します。これは自動化されたワークフローや Claude Code の Bash ツール（非対話的環境）経由での使用時に摩擦を生み出します。ユーザーは現在、`yes` コマンドをパイプで渡すことで回避していますが、これは煩雑です。

**問題点**: `/utils:clear-plugin-cache --all` を実行するたびに、スクリプトは警告を表示し、`read -p` によるユーザー確認を待ちます。非対話的環境（Claude Code の Bash ツールなど）では、これによりスクリプトがエラーコード 1 で終了します。

**解決策**: 一般的な Unix ツール（`apt`, `yum`, `rm -i` など）と同様に、確認プロンプトをスキップする `-y/--yes` オプションを追加します。

## 実装計画

### 1. 確認スキップ変数の追加

**ファイル**: `plugins/utils/scripts/clear-plugin-cache.sh`
**場所**: 13行目（`DRY_RUN=false` の後）

確認をスキップするかどうかを追跡する新しい変数を追加：

```bash
SKIP_CONFIRMATION=false
```

### 2. オプション解析の追加

**ファイル**: `plugins/utils/scripts/clear-plugin-cache.sh`
**場所**: 66-69行目（`--dry-run` case の後）

オプション解析の while ループに新しい case を追加：

```bash
-y|--yes)
    SKIP_CONFIRMATION=true
    shift
    ;;
```

### 3. 確認ロジックの更新

**ファイル**: `plugins/utils/scripts/clear-plugin-cache.sh`
**場所**: 144行目

確認条件を修正して、`DRY_RUN` と `SKIP_CONFIRMATION` の両方をチェックするように変更：

**現在**:
```bash
if [[ "$DRY_RUN" == false ]]; then
```

**変更後**:
```bash
if [[ "$DRY_RUN" == false ]] && [[ "$SKIP_CONFIRMATION" == false ]]; then
```

### 4. 使用方法ドキュメントの更新

**ファイル**: `plugins/utils/scripts/clear-plugin-cache.sh`
**場所**: 40-44行目

使用方法ヘルプに新しいオプションを追加：

**現在**:
```
Options:
  --marketplace <name>     Marketplace name (default: claude-tools)
  --all                    Clear all plugin caches for the marketplace
  --dry-run                Show what would be deleted without deleting
  -h, --help               Show this help message
```

**変更後**:
```
Options:
  --marketplace <name>     Marketplace name (default: claude-tools)
  --all                    Clear all plugin caches for the marketplace
  --dry-run                Show what would be deleted without deleting
  -y, --yes                Skip confirmation prompt
  -h, --help               Show this help message
```

### 5. 使用例の更新

**ファイル**: `plugins/utils/scripts/clear-plugin-cache.sh`
**場所**: 46-50行目

新しいオプションを使用する例を追加：

```
Examples:
  clear-plugin-cache cvi
  clear-plugin-cache cvi --dry-run
  clear-plugin-cache plugin --marketplace other-market
  clear-plugin-cache --all --marketplace claude-tools
  clear-plugin-cache --all --marketplace claude-tools -y
```

### 6. コマンドスキルドキュメントの更新

**ファイル**: `plugins/utils/commands/clear-plugin-cache/COMMAND.md`
**場所**: 使用方法セクション

コマンドテンプレートを以下から：
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/clear-plugin-cache.sh --all --marketplace claude-tools
```

以下に変更：
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/clear-plugin-cache.sh "$ARGUMENTS"
```

これにより、ユーザーが `--all --marketplace claude-tools -y` を渡すことができ、`yes` パイプの回避策なしで動作するようになります。

また、引数テーブルに以下を追加：

| Argument | Description |
|----------|-------------|
| `plugin-name` | クリアするプラグイン名 |
| `--marketplace <name>` | マーケットプレイス名を指定（デフォルト: claude-tools） |
| `--all` | 指定されたマーケットプレイスの全プラグインキャッシュをクリア |
| `-y, --yes` | 確認プロンプトをスキップ |
| `--dry-run` | 削除せずに、削除される内容を表示 |

### 7. グローバルCLAUDE.mdへのルール追加

**ファイル**: `~/.claude/CLAUDE.md`
**場所**: 適切なセクション（Plan mode または Development Work Best Practices）

プランモード時の言語設定ルールを追加：

```markdown
## Plan Mode

### プラン作成時の言語

**重要**: プランファイル（`.claude/plans/*.md`）は常に日本語で記述すること。

**理由**:
- プロジェクトメンバーが日本語で作業している
- プランは実装の詳細を含むため、日本語の方が理解しやすい
- グローバル設定で「Always respond in japanese」が設定されている

**例外**:
- 英語圏のプロジェクトで作業する場合は英語を使用
```

## 重要なファイル

- `plugins/utils/scripts/clear-plugin-cache.sh` - メインスクリプト実装
- `plugins/utils/commands/clear-plugin-cache/COMMAND.md` - コマンドドキュメント
- `~/.claude/CLAUDE.md` - グローバル設定（Plan mode ルール追加）

## 検証計画

### 1. 確認スキップのテスト

```bash
# 確認なしで削除されるべき
bash plugins/utils/scripts/clear-plugin-cache.sh --all --marketplace claude-tools -y
```

期待される動作: 確認プロンプトなし、キャッシュが直接削除される。

### 2. デフォルト動作のテスト（確認が必要）

```bash
# 確認プロンプトが表示されるべき
bash plugins/utils/scripts/clear-plugin-cache.sh --all --marketplace claude-tools
```

期待される動作: 警告メッセージが表示され、プロンプトが表示される。ユーザーは 'y' を入力する必要がある。

### 3. 長い形式のテスト

```bash
# --yes でも動作するべき
bash plugins/utils/scripts/clear-plugin-cache.sh --all --marketplace claude-tools --yes
```

期待される動作: `-y` と同じ、確認プロンプトなし。

### 4. ドライランのテスト（確認をスキップするべき）

```bash
# -y なしでもプロンプトを表示しないべき
bash plugins/utils/scripts/clear-plugin-cache.sh --all --marketplace claude-tools --dry-run
```

期待される動作: プロンプトなし（dry-run は既に確認をスキップ）、削除される内容を表示。

### 5. コマンドスキル経由のテスト

```
/utils:clear-plugin-cache --all --marketplace claude-tools -y
```

期待される動作: `yes` パイプの回避策なしで動作する。

### 6. ヘルプメッセージのテスト

```bash
bash plugins/utils/scripts/clear-plugin-cache.sh --help
```

期待される動作: 更新された使用方法が表示され、`-y, --yes` オプションがリストされる。

## 実装メモ

- `-y/--yes` オプションは Unix の慣習に従っています（`apt -y`, `yum -y`, `rm -i` と同様）
- このオプションは `--all` モードでのみ関連します（単一プラグイン削除では確認プロンプトは表示されません）
- このオプションは `--dry-run` と併用可能です（ただし dry-run は既に確認をスキップします）
- 実装は最小限で非侵襲的です（実際のロジック変更は3行のみ）
