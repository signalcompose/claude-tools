# プラン: プラグイン改善 - Sandbox修正とタイムアウト調査

## 背景

chezmoi shell sync checkerのマイグレーション成功後、2つの問題を特定：

### 問題1: clear-plugin-cacheのSandbox失敗
**問題**: `/utils:clear-plugin-cache`コマンドがキャッシュファイル削除時に"Operation not permitted"で失敗
**根本原因**: Bash toolのsandboxが`~/.claude/plugins/cache/*`への書き込み操作をブロック。コマンド定義がClaudeに`dangerouslyDisableSandbox: true`の使用を指示していない
**ユーザーへの影響**: 手動で再試行が必要となり、プラグイン更新ワークフローに摩擦が発生

### 問題2: chezmoi statusのタイムアウトと表示問題
**問題点**:
1. タイムアウト警告`⚠ chezmoi status timed out (>5s)`が頻繁に表示される
2. タイムアウト後、**誤解を招く**`✓ Dotfiles synced`メッセージが表示される（本来は「状態不明」と表示すべき）
3. `chezmoi status`が遅い理由をユーザーが診断できない（1Password API、Age暗号化など）

**根本原因**（調査結果より）:
- テンプレート内の1Password API呼び出し（`{{ onepasswordRead }}`）- 高影響
- Age暗号化のオーバーヘッド - 高影響
- ボトルネックを特定する診断ツールがない
- タイムアウト値（5秒）が設定不可
- タイムアウトフラグが追跡されず、誤った「同期済み」メッセージが表示される

## アプローチ

**両方の問題を1つのPRで実装**（ユーザーの希望：「両方同時」）

### 問題1: クイックフィックス（1ファイル変更）
コマンド定義を更新し、最初からsandboxバイパスを使用するようClaudeに指示

### 問題2: 包括的ソリューション（5ファイル変更）
1. **誤解を招く表示を修正** - タイムアウトフラグを追跡し、「同期済み」ではなく「状態不明」と表示
2. **診断機能を追加** - 新しい`/chezmoi:diagnose-timeout`コマンドで操作タイミングを測定
3. **設定可能化** - 環境変数`CHEZMOI_STATUS_TIMEOUT`でカスタムタイムアウトを設定可能に
4. **ガイダンス提供** - セルフサービス解決のためのトラブルシューティングドキュメント

## 変更ファイル

### 問題1: clear-plugin-cache
- `plugins/utils/commands/clear-plugin-cache.md` - Sandbox要件セクション追加、実行指示を更新

### 問題2: chezmoiタイムアウト
**変更ファイル**:
- `plugins/chezmoi/scripts/shell-check.zsh` - タイムアウト表示バグ修正、タイムアウトを設定可能化
- `plugins/chezmoi/README.md` - タイムアウト設定をドキュメント化

**新規ファイル**:
- `plugins/chezmoi/commands/diagnose-timeout.md` - 診断コマンド定義
- `plugins/chezmoi/scripts/diagnose-timeout.sh` - タイミング測定スクリプト
- `plugins/chezmoi/docs/troubleshooting-timeout.md` - 包括的トラブルシューティングガイド

## 重要な変更の詳細

### 変更1: タイムアウト表示バグ修正（shell-check.zsh）

**現在のバグ動作**（118-119行、126行、144-146行）:
```zsh
elif [[ $chezmoi_exit -eq 124 ]]; then
  print -P "%F{yellow}⚠%f chezmoi status timed out (>5s)"
  # has_local_changesが設定されない - falseのまま
fi

# 後で...
if $has_remote_updates || $has_local_changes || $fetch_failed || $network_offline; then
  # 詳細ステータス表示
else
  print -P "%F{green}✓%f Dotfiles synced"  # ← タイムアウト時は誤り！
fi
```

**修正後の動作**:
```zsh
# 56行目: タイムアウトフラグを追加
local has_status_timeout=false

# 118-120行目: タイムアウト時にフラグを設定
elif [[ $chezmoi_exit -eq 124 ]]; then
  print -P "%F{yellow}⚠%f chezmoi status timed out (>${timeout_seconds}s)"
  print -P "   → Run: %F{green}/chezmoi:diagnose-timeout%f to investigate"
  has_status_timeout=true

# 126行目: 条件にタイムアウトを含める
if $has_remote_updates || $has_local_changes || $fetch_failed || $network_offline || $has_status_timeout; then
  # ... 既存のメッセージ ...

  # 143行目: タイムアウト専用メッセージを追加
  $has_status_timeout && {
    print -P "  %F{yellow}⚠%f Sync status unknown (timeout)"
    print -P "    → Increase timeout: %F{green}export CHEZMOI_STATUS_TIMEOUT=10%f"
  }
else
  print -P "%F{green}✓%f Dotfiles synced"  # 実際に同期済みの時のみ表示
fi
```

### 変更2: タイムアウトを設定可能化（shell-check.zsh）

**104-111行目**:
```zsh
# 現状: ハードコードされた5秒
local -a chezmoi_status_cmd=(chezmoi status)
if command -v timeout &>/dev/null; then
  chezmoi_status_cmd=(timeout 5 chezmoi status)

# 修正後: 環境変数から読み込み
local timeout_seconds=${CHEZMOI_STATUS_TIMEOUT:-5}
local -a chezmoi_status_cmd=(chezmoi status)
if command -v timeout &>/dev/null; then
  chezmoi_status_cmd=(timeout $timeout_seconds chezmoi status)
```

### 変更3: Sandboxバイパス指示（clear-plugin-cache.md）

**17行目の後に追加**:
```markdown
## Sandbox要件

**重要**: このコマンドはプラグインキャッシュファイルの削除のためsandboxバイパスが必要です。

`dangerouslyDisableSandbox: true`で実行する理由:
- 操作: `~/.claude/plugins/cache/`内のディレクトリを削除
- Sandbox制限: デフォルトでは書き込み操作がブロックされる
- 安全な操作: ユーザーが開始したキャッシュクリーンアップ、システム変更のリスクなし
```

**20-24行目を置き換え**:
```markdown
以下のBashコマンドを**即座に実行**してください:

**重要**: ファイル削除のため`dangerouslyDisableSandbox: true`を使用してください。

Bash toolで実行:
- **コマンド**: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/clear-plugin-cache.sh "$ARGUMENTS"`
- **dangerouslyDisableSandbox**: `true`（必須）
```

## 新規ファイルの内容

### diagnose-timeout.md
以下を測定する診断コマンド:
- `chezmoi status`の全体タイミング
- テンプレート展開（1Password/Age のオーバーヘッド）
- Git操作のタイミング
- ネットワーク接続性

### diagnose-timeout.sh
`time`コマンドを使用して各操作を測定し、ボトルネックを特定するBashスクリプト。

### troubleshooting-timeout.md
以下をカバーする包括的ガイド:
- 一般的な原因（1Password API、Age暗号化、Git、ネットワーク）
- 各原因の解決策
- 設定例（`CHEZMOI_STATUS_TIMEOUT`）
- タイムアウトが正常な場合と懸念される場合

## 検証手順

### 問題1の検証
```bash
# sandboxバイパスでclear-plugin-cacheをテスト
/utils:clear-plugin-cache chezmoi

# 期待される結果: sandboxエラーなし、キャッシュが正常に削除される
# 検証: Claudeが自動的にdangerouslyDisableSandboxを使用することを確認
```

### 問題2の検証

**テスト1: タイムアウト表示修正**
```bash
# タイムアウトをシミュレート（chezmoiテンプレートにsleepを追加）
# 新しいターミナルを開き、Enterを押す
# 期待される結果: "✓ Dotfiles synced"ではなく"⚠ Sync status unknown (timeout)"
```

**テスト2: 設定可能なタイムアウト**
```bash
# カスタムタイムアウトを設定
export CHEZMOI_STATUS_TIMEOUT=10

# 新しいターミナルを開き、Enterを押す
# 期待される結果: 警告に">5s"ではなく">10s"が表示される
```

**テスト3: 診断コマンド**
```bash
/chezmoi:diagnose-timeout

# 期待される結果: タイミング内訳を表示し、ボトルネック（1Password/Age等）を特定
```

**テスト4: 通常動作**
```bash
# 実際に同期済みの場合（タイムアウトなし）に✓ Dotfiles syncedが表示されることを確認
```

## 実装優先順位

両方の問題を1つのPRで実装（ユーザーの選択に従う）:
1. featureブランチを作成: `fix/plugin-improvements-sandbox-timeout`
2. 問題1を実装（1ファイル）
3. 問題2を実装（5ファイル）
4. すべての検証手順をテスト
5. `/code:review-commit`でコードレビュー
6. PRを作成、マージ
7. マーケットプレイス更新、キャッシュクリア、再起動
