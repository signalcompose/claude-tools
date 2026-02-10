# CVI 音声機能ガイド

## 概要

CVI (Claude Voice Integration) は、Claude Codeのタスク完了時に音声でフィードバックを行うhooksシステムです。

---

## 音声通知機能

### 特徴

- 🔊 **音声通知**: タスク完了を音声で通知
- ⏸️ **自動中断**: 読み上げ中に新しい指示を出すと自動停止
- 🌐 **多言語対応**: 日本語・英語を自動判定
- 🎯 **カスタマイズ可能**: Skill toolで読み上げ内容を制御

### タスク完了通知の仕組み

タスクが完了したときに：
1. macOS通知が表示される
2. 通知音（Glass）が鳴る
3. 完了メッセージが音声で読み上げられる

### /cvi:speak によるタスク完了通知

Claude CodeはSkill toolを使って`/cvi:speak`を呼び出し、タスク完了を通知します。

**ルール**：
- **Skill toolで呼び出し** - テキストとして書かない
- **2-3文**で何をしたか・結果を伝える
- 技術的詳細よりも成果にフォーカス
- **[VOICE]タグは不要** - Skill結果が要約表示になる

**例**：
```markdown
詳細な作業内容の説明...

技術的な詳細が続く...

<use Skill tool: skill="cvi:speak" args="設定ファイルの編集が完了しました。3つのファイルを更新し、全てのテストが成功しています。">
```

**動作**：
- Skill toolの結果（`Speaking: ...`）がレスポンスに表示される
- macOS通知、Glass音、音声読み上げが実行される
- `/cvi:speak`を呼ばないとStop hookでブロックされる

---

## インストール

### 必要環境

- **OS**: macOS（`say`, `afplay`コマンド使用）
- **Claude Code**: 最新版
- **権限**: スクリプト実行権限

### セットアップ手順

#### 簡単セットアップ（推奨）

```bash
# CVIリポジトリから
cd /path/to/CVI

# グローバルインストール（全プロジェクトで有効）
scripts/cvi-setup global

# または、プロジェクトローカル（現在のプロジェクトのみ）
scripts/cvi-setup project
```

これで以下が自動的に実行されます：
- スクリプトのコピーと権限設定
- hooks設定の追加
- 初期設定（速度、言語）
- Siri音声設定の確認

#### 手動セットアップ

詳細は[README.md](../README.md#手動インストール)を参照してください。

---

## 使い方

### 基本的な使い方

1. Claude Codeでタスクを実行
2. タスクが完了すると音声通知
3. 読み上げ中に新しい指示を出すと自動停止

### Claude Codeでの使用例

**ユーザー**: "README.mdを編集して、インストール手順を追加してください"

**Claude Code**:
```markdown
README.mdにインストール手順を追加しました。以下の内容を記載しました：
- 前提条件
- インストールコマンド
- 初期設定手順

<use Skill tool: skill="cvi:speak" args="READMEにインストール手順を追加しました">
```

→ 「READMEにインストール手順を追加しました」と読み上げられます

---

## [VOICE]タグについて（非推奨）

**[VOICE]タグは非推奨です。** 代わりに`/cvi:speak` Skill toolを使用してください。

### なぜ非推奨なのか

1. **Stop hookでの強制**: `/cvi:speak`を呼ばないとStop hookでブロックされる
2. **一貫性**: Skill toolの結果が直接サマリーとして表示される
3. **メンテナンス性**: フック間でのルール重複を排除

### [VOICE]タグからSkill toolへの移行

**旧（非推奨）**:
```markdown
作業完了しました。

[VOICE]設定ファイルを更新しました[/VOICE]
```

**新（推奨）**:
```markdown
作業完了しました。

<use Skill tool: skill="cvi:speak" args="設定ファイルを更新しました">
```

---

## カスタマイズ

### 読み上げ速度の変更

**`cvi-speed`コマンド**で簡単に速度を変更できます：

```bash
# 現在の速度を確認
scripts/cvi-speed

# 速度を変更（90-350 wpm）
scripts/cvi-speed 220    # 速め
scripts/cvi-speed 200    # 標準（デフォルト）
scripts/cvi-speed 180    # ゆっくり

# デフォルトに戻す
scripts/cvi-speed reset
```

**推奨速度**:
- **180 wpm**: ゆっくり、聞き取りやすい
- **200 wpm**: 標準速度（デフォルト）
- **220 wpm**: やや速め、効率的

設定は`~/.cvi/config`に保存され、次回のタスク完了時から適用されます。

---

### 音声の変更（Siri音声の使用）

**システム設定でSiri音声を選択**すると、より自然で流暢な読み上げになります：

1. **システム設定** > **アクセシビリティ** > **読み上げコンテンツ**
2. **システムの声**で「Siri (声2)」または「Eloquence」を選択
3. CVIは自動的にシステムデフォルト音声を使用

**確認方法**：
```bash
# システムデフォルト音声でテスト
say "これはテストメッセージです"
```

Siri音声で読み上げられれば、CVIでも同じ音声が使われます。

---

### 言語切り替え

**`cvi-lang`コマンド**でフォールバックメッセージの言語を切り替えできます：

```bash
# 現在の言語を確認
scripts/cvi-lang

# 言語を変更
scripts/cvi-lang ja    # 日本語
scripts/cvi-lang en    # English

# デフォルトに戻す
scripts/cvi-lang reset
```

**サポート言語**:
- **ja**: 日本語（デフォルト）
- **en**: English

**言語設定の役割**:

`cvi-lang`は**フォールバックメッセージの言語**を設定します：
- **日本語（ja）**: フォールバックメッセージが「タスクが完了しました」
- **英語（en）**: フォールバックメッセージが「Task completed」

**注意**: 実際の読み上げ音声は`cvi-voice`で設定します。

---

### 音声の選択

**`cvi-voice`コマンド**で読み上げ音声を選択できます：

```bash
# 現在の設定を確認
cvi-voice

# システムデフォルト音声を使用
cvi-voice system

# 特定の音声を使用
cvi-voice Samantha   # Samantha（US英語、女性）
cvi-voice Karen      # Karen（AU英語、女性）
cvi-voice Daniel     # Daniel（UK英語、男性）

# 利用可能な英語音声を表示
cvi-voice list

# デフォルトに戻す
cvi-voice reset
```

**system オプション**:
- システムのデフォルト音声を使用（Siri音声など）
- システム設定で言語別の音声が設定されている場合に便利
- 設定方法: **システム設定** > **アクセシビリティ** > **読み上げコンテンツ** > **システムの声**

**人気の英語音声**:
- **Samantha** (US): 標準的でクリアな女性の声（デフォルト）
- **Karen** (AU): オーストラリア英語、聞き取りやすい女性の声
- **Daniel** (UK): イギリス英語、男性の声
- **Moira** (IE): アイルランド英語、女性の声

**使い分けの例**:
- **英語圏のユーザー**: `cvi-lang en` + `cvi-voice system` でシステムのSiri音声を使用
- **日本語環境で英語読み上げ**: `cvi-lang en` + `cvi-voice Samantha` など特定の音声を指定

**重要**:
- `cvi-voice`の設定は英語モード（`cvi-lang en`）の時のみ有効です
- 日本語モードでは常にシステムデフォルト音声を使用します
- [VOICE]タグ内のテキストは言語設定に関わらずそのまま読み上げられます

---

### セットアップ診断

**`cvi-check`コマンド**でセットアップ状態を診断できます：

```bash
scripts/cvi-check
```

以下の項目をチェック：
- ✅ Siri音声設定
- ✅ スクリプト実行権限
- ✅ hooks設定
- ✅ 読み上げ速度
- ✅ 言語設定

問題が見つかった場合、解決方法を案内します。

---

### 音量調整

`~/.claude/scripts/notify-end.sh`の以下の行を編集：

```bash
# 音声読み上げ音量を変更（0.0〜1.0）
afplay -v 0.6 "$TEMP_AUDIO"  # デフォルト: 0.6（60%）

# 通知音の音量を変更（0.0〜1.0）
afplay -v 1.0 /System/Library/Sounds/Glass.aiff  # デフォルト: 1.0（100%）
```

### 通知音の変更

Glass音以外を使用する場合：

```bash
# 利用可能な音を確認
ls /System/Library/Sounds/

# 別の音に変更（notify-end.sh内で）
afplay -v 1.0 /System/Library/Sounds/Ping.aiff &
```

---

## トラブルシューティング

### 音声が再生されない

**確認事項**:
1. スクリプトに実行権限があるか確認
   ```bash
   ls -l ~/.claude/scripts/notify-end.sh
   ```
2. hooks設定が正しいか確認
   ```bash
   cat ~/.claude/settings.json
   ```
3. macOSの音量がミュートになっていないか確認

### 読み上げが中断されない

**確認事項**:
1. `UserPromptSubmit`フックが設定されているか
2. `kill-voice.sh`に実行権限があるか
3. Claude Codeを再起動したか

### エラーメッセージが表示される

**デバッグ方法**:
```bash
# スクリプトを直接実行してエラー確認
bash ~/.claude/scripts/notify-end.sh < /dev/null
```

---

## アンインストール

```bash
# スクリプトを削除
rm ~/.claude/scripts/notify-end.sh
rm ~/.claude/scripts/kill-voice.sh

# settings.jsonからhooks設定を削除
# （手動で編集が必要）
```

---

## 技術仕様

### notify-end.shの処理フロー

1. **入力データ取得**: フックからJSON形式のデータを受け取る
2. **トランスクリプト読み込み**: 会話ログから最新のアシスタントメッセージを抽出
3. **メッセージ処理**:
   - `/cvi:speak`が呼ばれた場合：引数のテキストを使用
   - `[VOICE]タグ`がある場合：タグ内のテキストを抽出（後方互換性）
   - どちらもない場合：最初の200文字を使用
4. **通知表示**: macOS通知を表示
5. **音声生成**: `say`コマンドで音声ファイルを生成
6. **再生**: 指定した音量で音声を再生

### kill-voice.shの処理フロー

1. **プロセス検索**: `say`および`afplay`プロセスを検索
2. **プロセス終了**: 該当プロセスを終了（SIGTERM）
3. **一時ファイル削除**: 音声一時ファイルをクリーンアップ

---

## 参考資料

- [CVI README](../README.md) - プロジェクト概要
- [Claude Code公式ドキュメント](https://docs.claude.com/en/docs/claude-code)
- [Claude Code Hooks](https://docs.claude.com/en/docs/claude-code/hooks)
- [macOS `say`コマンド](https://ss64.com/mac/say.html)

---

**最終更新**: 2026-02-06
