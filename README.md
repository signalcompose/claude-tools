# CVI (Claude Voice Integration)

Claude Codeのタスク完了時に音声通知を行うシステム

---

## 概要

**CVI**は、Claude Codeの作業を音声でフィードバックするhooksシステムです。

### 特徴

- 🔊 **音声通知**: タスク完了を音声で通知
- ⏸️ **自動中断**: 読み上げ中に新しい指示を出すと自動停止
- 🌐 **多言語対応**: 日本語・英語を自動判定
- 🎯 **カスタマイズ可能**: [VOICE]タグで読み上げ内容を制御

---

## 必要環境

- **OS**: macOS（`say`, `afplay`コマンド使用）
- **Claude Code**: 最新版
- **権限**: スクリプト実行権限

---

## インストール

### プラグインとしてインストール（推奨）

Claude Codeのプラグインシステムを使用してインストールできます：

```bash
# Claude Codeで以下のコマンドを実行
/plugin add signalcompose/cvi
```

これだけで完了です。hooks、コマンド、スキルが自動的に設定されます。

### 初期設定

インストール後、必要に応じて設定を調整：

```bash
/cvi:speed 200    # 読み上げ速度（デフォルト: 200wpm）
/cvi:lang ja      # [VOICE]タグ言語（デフォルト: ja）
/cvi:voice list   # 利用可能な音声を確認
```

---

### 手動インストール（代替方法）

プラグインを使用せず手動でセットアップする場合：

#### cvi-setupスクリプト

```bash
# グローバルインストール（全プロジェクトで有効）
scripts/cvi-setup global

# または、プロジェクトローカル（現在のプロジェクトのみ）
scripts/cvi-setup project
```

#### 完全手動インストール

手動でセットアップする場合：

#### 1. スクリプトをコピー

```bash
# スクリプトを配置
cp scripts/notify-end.sh ~/.claude/scripts/
cp scripts/notify-input.sh ~/.claude/scripts/
cp scripts/kill-voice.sh ~/.claude/scripts/

# 制御コマンドをコピー（グローバルのみ）
cp scripts/cvi ~/.claude/scripts/
cp scripts/cvi-speed ~/.claude/scripts/
cp scripts/cvi-lang ~/.claude/scripts/
cp scripts/cvi-check ~/.claude/scripts/

# 実行権限を付与
chmod +x ~/.claude/scripts/*.sh
chmod +x ~/.claude/scripts/cvi*
```

#### 2. hooks設定

`~/.claude/settings.json`を編集（または作成）：

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/kill-voice.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/notify-end.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/scripts/notify-input.sh"
          }
        ]
      }
    ]
  }
}
```

#### 3. 初期設定ファイル

`~/.cvi/config`を作成：

```bash
mkdir -p ~/.cvi
cat > ~/.cvi/config <<EOF
CVI_ENABLED=on
SPEECH_RATE=200
VOICE_LANG=ja
EOF
```

#### 4. Claude Codeを再起動

設定を反映させるため、Claude Codeを再起動してください。

---

## 使い方

### 基本的な使い方

1. Claude Codeでタスクを実行
2. タスクが完了すると音声通知
3. 読み上げ中に新しい指示を出すと自動停止

### 制御コマンド

#### cvi - 音声通知の有効/無効

```bash
cvi on       # 音声通知を有効化
cvi off      # 音声通知を無効化
cvi show     # 現在の設定を表示
cvi help     # ヘルプを表示
```

#### cvi:speed - 読み上げ速度の調整

```bash
cvi:speed           # 現在の速度を確認
cvi:speed 220       # 速度を220wpmに設定
cvi:speed reset     # デフォルト（200wpm）に戻す
```

推奨速度：
- 180 wpm: ゆっくり、聞き取りやすい
- 200 wpm: 標準速度（デフォルト）
- 220 wpm: やや速め、効率的

#### cvi:lang - 言語切り替え

```bash
cvi:lang           # 現在の言語を確認
cvi:lang ja        # 日本語に設定
cvi:lang en        # 英語に設定
cvi:lang reset     # デフォルト（ja）に戻す
```

言語設定の役割：
- **日本語（ja）**: フォールバックメッセージが日本語になります
- **英語（en）**: フォールバックメッセージが英語になります

注意:
- 実際の読み上げ音声は`cvi:voice`で設定します
- 日本語モードでは常にシステムデフォルト音声を使用
- 英語モードでは`cvi:voice`で設定した音声を使用
- [VOICE]タグ内のテキストは言語設定に関わらずそのまま読み上げられます

#### cvi:voice - 音声の選択（言語別設定）

```bash
cvi:voice                    # 現在の設定を確認
cvi:voice en Zoe             # 英語音声をZoeに設定
cvi:voice ja Kyoko           # 日本語音声をKyokoに設定
cvi:voice mode auto          # 自動音声選択モード（デフォルト）
cvi:voice mode fixed         # 固定音声モード
cvi:voice fixed Zoe          # 全言語でZoeを使用
cvi:voice list               # 利用可能な音声一覧
cvi:voice reset              # デフォルトに戻す
```

**言語別音声設定**:
- **英語音声** (`cvi:voice en [VOICE]`): 英語テキスト用の音声
- **日本語音声** (`cvi:voice ja [VOICE]`): 日本語テキスト用の音声
- 各言語で異なる音声を設定できます

**音声モード**:
- **autoモード** (デフォルト): 言語に応じて自動的に音声を切り替え
- **fixedモード**: 全ての言語で同じ音声を使用

**人気の音声**:

*日本語*:
- **system**: システムデフォルト（日本語Siri）
- **Kyoko**: 標準日本語音声（女性）
- **Otoya**: 標準日本語音声（男性）

*英語*:
- **system**: システムデフォルト（英語Siri）
- **Samantha** (US): 標準的でクリアな女性の声
- **Zoe** (UK): プレミアム女性音声
- **Karen** (AU): オーストラリア英語、女性
- **Daniel** (UK): イギリス英語、男性

#### cvi:auto - 言語自動検出

```bash
cvi:auto           # 現在の設定を確認
cvi:auto on        # 言語自動検出を有効化
cvi:auto off       # 言語自動検出を無効化（デフォルト）
cvi:auto status    # 詳細ステータス表示
```

**言語自動検出**:
- [VOICE]タグ内のテキストを分析し、日本語/英語を自動判定
- 日本語検出時 → 日本語音声を使用
- 英語検出時 → 英語音声を使用
- 設定言語に関わらず、適切な音声で読み上げ

**使用例**:
```bash
# 日本語環境で英語学習
cvi:lang ja            # フォールバックは日本語
cvi:voice ja system    # 日本語はシステム音声
cvi:voice en Zoe       # 英語はZoe（学習用）
cvi:auto on            # 自動検出ON

# 動作
[VOICE]Task completed[/VOICE]  # Zoeで英語読み上げ
[VOICE]完了しました[/VOICE]      # システム音声で日本語
```

#### cvi:check - セットアップ診断

```bash
cvi:check          # セットアップ状態を診断
```

チェック項目：
- Siri音声設定
- スクリプト実行権限
- hooks設定
- 読み上げ速度
- 言語設定

### [VOICE]タグの使用

Claude Codeのレスポンスに`[VOICE]...[/VOICE]`タグを含めると、その部分が読み上げられます：

```markdown
詳細な技術的説明が続く...

[VOICE]ファイルの編集が完了しました。3つのファイルを更新しました。[/VOICE]
```

タグがない場合は、メッセージの最初の200文字が自動的に読み上げられます。

### Siri音声の使用（推奨）

より自然で流暢な読み上げのため、Siri音声を設定してください：

1. **システム設定** > **アクセシビリティ** > **読み上げコンテンツ**
2. **システムの声**で「Siri (声2)」または「Eloquence」を選択
3. CVIは自動的にシステムデフォルト音声を使用

確認方法：
```bash
say "これはテストメッセージです"
```

Siri音声で読み上げられれば、CVIでも同じ音声が使われます。

---

## 高度なカスタマイズ

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

# notify-end.sh内で別の音に変更
afplay -v 1.0 /System/Library/Sounds/Ping.aiff &
```

---

## トラブルシューティング

### Q: 音声が再生されない

**まず診断コマンドを実行**:
```bash
cvi:check
```

**確認事項**:
1. CVI が有効になっているか確認
   ```bash
   cvi status
   ```
2. macOSの音量がミュートになっていないか確認
3. スクリプトに実行権限があるか確認
   ```bash
   ls -l ~/.claude/scripts/notify-end.sh
   ```
4. hooks設定が正しいか確認
   ```bash
   cat ~/.claude/settings.json
   ```

### Q: 読み上げが不自然・ロボット的

**Siri音声を設定**:
1. **システム設定** > **アクセシビリティ** > **読み上げコンテンツ**
2. **システムの声**で「Siri (声2)」を選択
3. Claude Codeを再起動

確認:
```bash
say "テストメッセージです"
```

### Q: 読み上げが中断されない

**確認事項**:
1. `UserPromptSubmit`フックが設定されているか
2. `kill-voice.sh`に実行権限があるか
3. Claude Codeを再起動したか

### Q: 読み上げ速度を変更したい

```bash
cvi:speed 220  # 速めに設定
cvi:speed 180  # ゆっくりに設定
```

### Q: 英語で読み上げたい

```bash
cvi:lang en    # 英語に切り替え
```

注意: [VOICE]タグ内のテキストは言語設定に関わらずそのまま読み上げられます。

### Q: エラーメッセージが表示される

**デバッグ方法**:
```bash
# スクリプトを直接実行してエラー確認
bash ~/.claude/scripts/notify-end.sh < /dev/null

# 診断実行
cvi:check
```

---

## アンインストール

### グローバルインストールの場合

```bash
# 音声通知を無効化
cvi off

# スクリプトを削除
rm ~/.claude/scripts/notify-end.sh
rm ~/.claude/scripts/notify-input.sh
rm ~/.claude/scripts/kill-voice.sh
rm ~/.claude/scripts/cvi
rm ~/.claude/scripts/cvi-*

# 設定ファイルを削除
rm -rf ~/.cvi

# スラッシュコマンドを削除
rm ~/.claude/commands/cvi*.md

# settings.jsonからhooks設定を削除
# （手動で編集が必要）
```

### プロジェクトローカルの場合

```bash
# プロジェクトのスクリプトを削除
rm -rf .claude/scripts/notify-*.sh
rm -rf .claude/scripts/kill-voice.sh

# プロジェクトのsettings.jsonからhooks設定を削除
# （手動で編集が必要）
```

---

## 貢献方法

バグ報告や機能要望は、GitHubのIssuesでお知らせください。

プルリクエストも歓迎します！

---

## ライセンス

MIT License - 詳細は[LICENSE](LICENSE)ファイルをご覧ください。

---

## 参考

- [Claude Code公式ドキュメント](https://docs.claude.com/en/docs/claude-code)
- [macOS `say`コマンド](https://ss64.com/mac/say.html)
- [Claude Code Hooks](https://docs.claude.com/en/docs/claude-code/hooks)

---

**快適なClaude Codeライフを！** 🚀
