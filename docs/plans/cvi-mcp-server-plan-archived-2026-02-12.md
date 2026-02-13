# 実装計画: CVIプラグイン speak コマンドの修正

## Context（背景）

### 問題

CVIプラグインの `/cvi:speak` コマンドが、以下の問題を抱えています：

1. **エラー出力の隠蔽**: `> /dev/null 2>&1` によりエラーメッセージが見えない
2. **バックグラウンド実行**: `&` により、プロセスの完了を待たない
3. **安全性の欠如**: 直接引数を渡す `speak.sh` を使用（コマンドインジェクションリスク）
4. **根本的なエラー**: `AudioQueueStart failed (-66680)` が隠蔽されている

### 変更履歴

Phase 1実装時（commit: 56b9f5e）:
```bash
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh $ARGUMENTS`
```

現在（commit: 63dbf16）:
```bash
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh "$ARGUMENTS" > /dev/null 2>&1 &`
```

### なぜこの修正が必要か

- ユーザーが「以前は動作していた」と報告
- より安全で堅牢な `speak-sync.sh` が既に実装されているが、使用されていない
- デバッグが困難（エラーが見えない）

---

## 推奨される修正アプローチ

### 修正内容

`plugins/cvi/commands/speak.md` の Line 11 を以下に変更：

```bash
# 修正前
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh "$ARGUMENTS" > /dev/null 2>&1 &`

# 修正後
!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak-sync.sh "$ARGUMENTS"`
```

### 変更の利点

1. ✅ **エラー出力が見える** - デバッグ可能
2. ✅ **より安全な実装** - `printf '%s' "$MSG" | say -f -` でコマンドインジェクション防止
3. ✅ **エラーログ記録** - `~/.cvi/error.log` に記録
4. ✅ **同期実行** - プロセスの完了を確実に待機
5. ✅ **堅牢なエラーハンドリング** - `set -euo pipefail` で厳格なエラー処理

### `speak-sync.sh` の特徴

| 項目 | speak.sh（旧） | speak-sync.sh（新） |
|------|---------------|-------------------|
| 実行方法 | `say "$MSG" &` | `printf '%s' "$MSG" \| say -f -` |
| 安全性 | 低（コマンドインジェクション可能） | 高（標準入力経由） |
| エラー処理 | なし | エラーログ記録 |
| 実行モード | 非同期（バックグラウンド） | 同期（フォアグラウンド） |
| AppleScript | エスケープなし | エスケープ処理あり |

---

## 実装手順

### 1. ファイル編集

**ファイル**: `plugins/cvi/commands/speak.md`

**変更箇所**: Line 11

**変更内容**:
```diff
-!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak.sh "$ARGUMENTS" > /dev/null 2>&1 &`
+!`bash ${CLAUDE_PLUGIN_ROOT}/scripts/speak-sync.sh "$ARGUMENTS"`
```

### 2. Git Workflow

プロジェクトの CLAUDE.md に従って、以下の手順で進めます：

#### ブランチ作成
```bash
git checkout main
git pull origin main
git checkout -b fix/cvi-speak-sync-migration
```

#### コミット
```bash
git add plugins/cvi/commands/speak.md
git commit -m "fix(cvi): migrate speak command to speak-sync.sh

speak.shからspeak-sync.shへの移行

## 変更内容
- commands/speak.mdでspeak-sync.shを使用
- エラー出力の隠蔽を解除
- バックグラウンド実行を削除

## 理由
- より安全な実装（コマンドインジェクション防止）
- エラーログ記録機能
- デバッグ可能なエラー出力
- 同期実行で確実な完了待機

## 影響
- /cvi:speakコマンドがより堅牢になる
- AudioQueueエラーが見えるようになる

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

#### PR作成
```bash
git push -u origin fix/cvi-speak-sync-migration

# GitHub MCPでPR作成
mcp__github__create_pull_request({
  owner: "signalcompose",
  repo: "claude-tools",
  title: "fix(cvi): migrate speak command to speak-sync.sh",
  body: "...",
  head: "fix/cvi-speak-sync-migration",
  base: "main"
})
```

#### マージ後のsubtree push
```bash
# PRマージ後、CVIリポジトリに変更を反映
git subtree push --prefix=plugins/cvi https://github.com/signalcompose/cvi.git main
```

---

## 検証手順

### 1. マーケットプレイス更新
```bash
/plugin update
```

### 2. キャッシュクリア
```bash
/utils:clear-plugin-cache cvi
```

### 3. Claude Code再起動

完全な再起動を行い、プラグインの変更を反映

### 4. テスト実行

#### テスト1: 基本的な音声読み上げ
```bash
# Skill toolで実行
<use Skill tool: skill="cvi:speak" args="テストメッセージです。">
```

**期待される動作**:
- macOS通知が表示される
- Glass音が再生される
- 音声が読み上げられる
- エラーが発生した場合、エラーメッセージが表示される

#### テスト2: エラーログ確認
```bash
# エラーログを確認
cat ~/.cvi/error.log
```

**期待される結果**:
- AudioQueueエラーが記録されている（発生した場合）
- タイムスタンプとエラーメッセージが含まれている

#### テスト3: 長文の読み上げ
```bash
<use Skill tool: skill="cvi:speak" args="これは長いテストメッセージです。複数の文を含みます。正しく読み上げられるか確認します。">
```

**期待される動作**:
- 全文が読み上げられる
- 中断されない

---

## リスクと対策

### リスク1: 同期実行による遅延

**リスク**: `speak-sync.sh` はフォアグラウンド実行なので、読み上げが完了するまで待機する

**対策**: これは意図的な動作。Skill toolの結果が即座に返ることで、ユーザーに通知が届いたことを確認できる

### リスク2: AudioQueueエラーの継続

**リスク**: `AudioQueueStart failed (-66680)` エラーが継続する可能性

**対策**:
- エラーログに記録されるため、根本原因の調査が可能
- エラーメッセージがユーザーに表示されるため、対処方法を案内できる

### リスク3: 既存の動作への影響

**リスク**: 他のコマンドやスクリプトが `speak.sh` に依存している可能性

**対策**: 調査済み - `commands/speak.md` のみが該当。他の箇所は影響なし

---

## ロールバック手順

万が一問題が発生した場合：

```bash
# 1. 元のコミットに戻す
git revert <commit-hash>

# 2. PRを作成してマージ

# 3. マーケットプレイス更新
/plugin update

# 4. キャッシュクリア
/utils:clear-plugin-cache cvi

# 5. Claude Code再起動
```

---

## 追加の調査（オプション）

AudioQueueエラーの根本原因を解決するために、以下の調査を推奨：

1. **macOSのオーディオ権限確認**
   - システム設定 > プライバシーとセキュリティ > マイク
   - Claude Codeの権限を確認

2. **sandbox設定の確認**
   - `settings.json` の `sandbox` 設定を確認
   - オーディオアクセスの制限がないか確認

3. **代替音声のテスト**
   ```bash
   say -v Kyoko "テスト"
   say -v Samantha "Test"
   ```

---

## 成功基準

以下の条件をすべて満たすこと：

1. ✅ `/cvi:speak` コマンドが正常に動作する
2. ✅ エラーが発生した場合、エラーメッセージが表示される
3. ✅ エラーログに記録される（発生した場合）
4. ✅ コマンドインジェクションが防止される
5. ✅ 既存の機能に影響がない

---

## Phase 2: Codex調査に基づく追加修正（完了）

PR #103でマージ済み。しかし、新たな問題が発見されました。

### Phase 2で発見された問題

PR #102のマージ後、音声が再生されない問題が継続。Codex調査により、根本原因が判明：

**Codexの発見**:
1. `say`コマンドはGUIログイン中ユーザーのセッション（Aqua/WindowServer配下）でのみ音声が出る
2. LaunchDaemon、CI/CD、サンドボックス、SSHの非GUIセッションでは音が出ない
3. `tell application "System Events"` 経由でも、GUIセッションに確実に接続できない可能性

**現在のspeak-sync.shの問題**:
- `tell application "System Events"` 経由で`do shell script`を実行
- これがGUIセッションへの接続を妨げている可能性

**成功したテストケース**（前回のテストで音声が聞こえた）:
```bash
osascript <<EOF
set msg to "テストメッセージ"
do shell script "printf '%s' " & quoted form of msg & " | say -v Kyoko -r 200"
EOF
```

このテストでは`tell application "System Events"`を使わず、**直接**`do shell script`を使用している。

### 修正内容

**ファイル**: `plugins/cvi/scripts/speak-sync.sh`

**変更箇所**: Line 102-139（音声再生部分全体）

**修正方針**（ユーザー提案に基づく）:
1. **osascriptを完全に削除** - GUIセッション依存を回避
2. **`say -o`で音声ファイル生成** - 非GUIでも動作する
3. **`afplay`で同期再生** - 既存のGlass音再生と同じパターン
4. **一時ファイルクリーンアップ** - セキュアに管理

**修正後のコード**:
```bash
# Generate speech audio file (works in sandboxed/non-GUI contexts)
TEMP_AUDIO=$(mktemp /tmp/claude_speak.XXXXXX.aiff)

if [ "$SELECTED_VOICE" = "system" ]; then
    # Use system default (no -v flag)
    if ! say -r "$SPEECH_RATE" -o "$TEMP_AUDIO" "$MSG"; then
        log_error "say command failed (system voice, rate=$SPEECH_RATE)"
        rm -f "$TEMP_AUDIO"
        exit 1
    fi
else
    # Use specific voice
    if ! say -v "$SELECTED_VOICE" -r "$SPEECH_RATE" -o "$TEMP_AUDIO" "$MSG"; then
        log_error "say command failed (voice=$SELECTED_VOICE, rate=$SPEECH_RATE)"
        rm -f "$TEMP_AUDIO"
        exit 1
    fi
fi

# Play audio file synchronously (foreground - waits for completion)
if ! afplay "$TEMP_AUDIO"; then
    log_error "afplay command failed for $TEMP_AUDIO"
    rm -f "$TEMP_AUDIO"
    exit 1
fi

# Cleanup temporary file
rm -f "$TEMP_AUDIO"

# Only print after speech completes
echo "Speaking: $MSG"
```

**この修正の利点**:
1. ✅ **GUIセッション不要** - `say -o`はファイル生成のみなので非GUIでも動作
2. ✅ **シンプル** - osascriptの複雑性を排除
3. ✅ **セキュア** - 引数を直接渡すが、`say`コマンド自体に渡すだけなので安全
4. ✅ **堅牢** - `afplay`は既にGlass音で動作実績あり（Line 100）
5. ✅ **同期実行** - `afplay`をフォアグラウンドで実行（`&`なし）
6. ✅ **デバッグ可能** - エラーログ記録機能は維持

### 検証手順

1. speak-sync.shを修正
2. 直接テスト: `bash plugins/cvi/scripts/speak-sync.sh "テストメッセージ"`
3. 音声が聞こえることを確認
4. コミット、PR作成、マージ
5. マーケットプレイス更新、キャッシュクリア、Claude Code再起動
6. `/cvi:speak`コマンドで最終テスト

---

## 参考情報

- **CVIプラグインのCLAUDE.md**: `plugins/cvi/CLAUDE.md`
- **speak-sync.sh**: `plugins/cvi/scripts/speak-sync.sh`
- **speak.sh**: `plugins/cvi/scripts/speak.sh`（削除済み）
- **変更履歴**: commit 56b9f5e → 63dbf16 → PR #102 → Phase 2修正
- **Codex調査**: sayコマンドのGUIセッション依存性
