# CLAUDE.md - CVI (Claude Voice Integration)

このファイルはClaude Code (claude.ai/code) 向けのプロジェクト指示書です。

---

## プロジェクト概要

**CVI (Claude Voice Integration)** は、Claude Codeのタスク完了時に音声通知を行うシステムです。

### 目的

- Claude Codeのタスク完了を音声で通知
- 読み上げ中に新しい指示を出した際の自動中断
- hooksシステムを活用した柔軟な通知設定
- 日本語・英語の自動判定と適切な音声選択

---

## 主な機能

### 1. タスク完了通知（Stop Hook）

Claude Codeがタスクを完了した時に：
- macOS通知を表示
- Glass音を再生
- メッセージを音声で読み上げ（日本語: Kyoko、英語: デフォルト）

### 2. 読み上げ中断（UserPromptSubmit Hook）

ユーザーが新しい指示を入力した時に：
- 現在再生中の音声を即座に停止
- 一時ファイルをクリーンアップ
- 無限ループを防止

### 3. 入力確認通知（Notification Hook）

Claude Codeがユーザーの入力を待っている時に：
- Glass音を再生
- 「確認をお願いします」と読み上げ
- 別の音声再生中はスキップ（重複防止）

### 4. /cvi:speak Skill tool（推奨）

Claude CodeはSkill toolを使用して`/cvi:speak`を呼び出し、タスク完了を通知します：
```
詳細な説明...

<use Skill tool: skill="cvi:speak" args="完了しました。設定ファイルを更新しました。">
```

**重要**:
- `/cvi:speak`を呼ばないとStop hookでブロックされます
- Skill toolの結果（`Speaking: ...`）がサマリーとして表示されます
- `[VOICE]タグ`は後方互換性のために残っていますが、非推奨です

---

## セットアップ手順

### プラグインとしてインストール（推奨）

Claude Codeのプラグインシステムを使用：

```bash
/plugin add signalcompose/cvi
```

これだけで完了。hooks、コマンド、スキルが自動的に設定されます。

### 手動インストール

#### STEP 1: スクリプトの配置

以下のスクリプトを`~/.claude/scripts/`に配置：

1. **notify-end.sh** - タスク完了時の通知スクリプト
2. **notify-input.sh** - 入力確認時の通知スクリプト
3. **kill-voice.sh** - 読み上げ中断スクリプト

#### STEP 2: hooksの設定

`~/.claude/settings.json`にhooksを追加：

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

#### STEP 3: スクリプトに実行権限を付与

```bash
chmod +x ~/.claude/scripts/notify-end.sh
chmod +x ~/.claude/scripts/notify-input.sh
chmod +x ~/.claude/scripts/kill-voice.sh
```

---

## ディレクトリ構造

```
CVI/
├── .claude/                 # Claude Code設定（開発用）
│   └── settings.json
├── .claude-plugin/          # プラグイン設定
│   └── plugin.json          # プラグインメタデータ
├── commands/                # スラッシュコマンド定義
│   ├── auto.md              # /cvi:auto - 言語自動検出
│   ├── check.md             # /cvi:check - セットアップ診断
│   ├── lang.md              # /cvi:lang - 言語切り替え
│   ├── practice.md          # /cvi:practice - 英語練習モード
│   ├── setup.md             # /cvi:setup - セットアップ
│   ├── speed.md             # /cvi:speed - 読み上げ速度
│   ├── state.md             # /cvi:state - 有効/無効切り替え
│   └── voice.md             # /cvi:voice - 音声選択
├── docs/                    # ドキュメント
│   ├── INDEX.md             # ドキュメント索引
│   ├── voice-features.md    # 音声機能ガイド
│   ├── voice-mapping.md     # 音声マッピング機能
│   └── research/            # 調査・研究資料
├── examples/                # 設定例
│   ├── settings.json        # hooks設定テンプレート
│   └── README.md            # 設定例の説明
├── hooks/                   # hooks定義
│   └── hooks.json           # プラグイン用hooks設定
├── scripts/                 # スクリプト
│   ├── notify-end.sh        # タスク完了通知
│   ├── notify-input.sh      # 入力確認通知
│   ├── kill-voice.sh        # 読み上げ中断
│   ├── cvi                  # 有効/無効制御
│   ├── cvi-auto             # 言語自動検出
│   ├── cvi-check            # セットアップ診断
│   ├── cvi-lang             # 言語切り替え
│   ├── cvi-practice         # 英語練習モード
│   ├── cvi-setup            # セットアップスクリプト
│   ├── cvi-speed            # 読み上げ速度
│   └── cvi-voice            # 音声選択
├── skills/                  # スキル定義
│   └── voice-integration/
│       └── SKILL.md         # 音声統合スキル
├── CLAUDE.md                # このファイル
├── README.md                # ユーザー向け説明
└── LICENSE                  # MITライセンス
```

---

## 開発原則

### Documentation Driven Development (DDD)

このプロジェクトはDDDで開発します：

1. **仕様書を最初に書く** - `docs/development/`配下
2. **実装** - 仕様書に基づいて実装
3. **テスト** - 動作確認
4. **ドキュメント更新** - 変更内容を反映

---

## セッション開始時の手順

### STEP 1: ドキュメント読み込み

1. **このファイル** (`CLAUDE.md`)
2. **`docs/INDEX.md`** - ドキュメント索引
3. **`README.md`** - ユーザー向け説明

### STEP 2: 現在の状況確認

```bash
# 現在のスクリプトを確認
ls -la ~/.claude/scripts/

# hooks設定を確認
cat ~/.claude/settings.json
```

### STEP 3: ユーザーからの指示を待つ

---

## 技術仕様

### 音声合成

- **日本語**: `say -v Kyoko`（macOS標準）
- **英語**: `say`（デフォルト音声）
- **音量**: 60%（0.6）
- **一時ファイル**: `/tmp/claude_notify_$$.aiff`

### プロセス管理

- **afplay**: macOSの音声再生コマンド
- **killall afplay**: 全てのafplayプロセスを停止
- **バックグラウンド実行**: `&`でスクリプトをブロックしない

### hooksシステム

- **UserPromptSubmit**: ユーザーがプロンプトを送信する前に実行
- **Stop**: Claude Codeがタスクを完了した時に実行
- **Notification**: Claude Codeがユーザーの入力を待っている時に実行
- **Exit Code**: 0=成功、2=ブロッキングエラー

---

## トラブルシューティング

### Q: 音声が再生されない

**A**: 以下を確認：
1. スクリプトに実行権限があるか？ (`chmod +x`)
2. hooks設定が正しいか？ (`~/.claude/settings.json`)
3. macOSの音量がミュートになっていないか？

### Q: 読み上げ中断が動作しない

**A**: 以下を確認：
1. `UserPromptSubmit`フックが設定されているか？
2. `kill-voice.sh`に実行権限があるか？
3. Claude Codeを再起動したか？

### Q: 読み上げが重なる

**A**: 現在の設計では、複数の読み上げが重なることがあります。これは意図的な動作です。`UserPromptSubmit`フックで中断してください。

---

## 今後の拡張予定

### Phase 1（完了）
- [x] 基本的な音声通知機能
- [x] 読み上げ中断機能
- [x] [VOICE]タグサポート

### Phase 2（完了）
- [x] 音量調整機能
- [x] 音声選択機能（言語別音声設定）
- [x] 通知のカスタマイズ（音・音声のON/OFF）
- [x] 言語自動検出機能
- [x] 入力確認通知（Notification Hook）
- [x] プラグインシステム対応

### Phase 3（将来）
- [ ] GUI設定ツール
- [ ] プロジェクトごとの設定
- [ ] 音声ファイルのカスタマイズ

---

## Git Workflow

### ブランチ戦略

**GitHub Flow**を採用（シンプルなOSS向けワークフロー）

```
main              ← 本番ブランチ（デフォルト）
  └── feature/xxx ← 機能ブランチ
  └── fix/xxx     ← バグ修正ブランチ
  └── docs/xxx    ← ドキュメント更新ブランチ
  └── chore/xxx   ← メンテナンスブランチ
```

**デフォルトブランチ**: `main`

### ブランチ保護

- **main への直接プッシュ禁止**（管理者バイパス可能）
- **PR必須**
- **マージコミット推奨**

### 開発フロー

```bash
# 1. mainブランチから最新を取得
git checkout main
git pull origin main

# 2. 作業ブランチを作成
git checkout -b feature/your-feature-name

# 3. 開発・コミット
git add .
git commit -m "feat: implement your feature"

# 4. プッシュ
git push -u origin feature/your-feature-name

# 5. Pull Request作成
gh pr create --base main --head feature/your-feature-name

# 6. レビュー後マージ → 自動的にmainに反映
```

### リリースフロー

1. mainブランチが常に最新のリリース可能な状態
2. 必要に応じてタグ付け（`git tag v1.0.1`）
3. claude-toolsへの同期

---

## Commit・PR・ISSUE言語ルール

### 🚨 絶対に守るべき言語ルール

#### コミットメッセージ

- ✅ **タイトル（1行目）**: 必ず英語 (Conventional Commits)
- ✅ **本文（2行目以降）**: 必ず日本語

#### PR（Pull Request）

- ✅ **タイトル**: 英語
- ✅ **本文**: 日本語

#### ISSUE

- ✅ **タイトル**: 英語
- ✅ **本文**: 日本語

### Conventional Commits形式

**フォーマット**:
```
<type>(<scope>): <subject>  ← 英語

<body>  ← 日本語

<footer>
```

**タイプ**:
- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `refactor`: リファクタリング
- `test`: テスト追加・修正
- `chore`: ビルドプロセスやツールの変更

### 正しい例

```bash
git commit -m "$(cat <<'EOF'
feat(voice): add volume control

音量調整機能を追加

## 変更内容
- 音量設定をconfig.ymlに追加
- say コマンドに-rオプションを追加
- デフォルト音量を60%に設定

Closes #123
EOF
)"
```

### 間違った例（絶対にやってはいけない）

```bash
# ❌ NG: 本文が英語
feat(voice): add volume control

- Add volume setting to config.yml  ← 英語はダメ！
- Add -r option to say command  ← 英語はダメ！
```

```bash
# ❌ NG: タイトルが日本語
音量調整機能の追加  ← タイトルは英語で！

音量設定をconfig.ymlに追加しました。
```

---

## 参考ドキュメント

- **[README.md](README.md)** - CVIの使い方
- **[docs/INDEX.md](docs/INDEX.md)** - ドキュメント索引

---

**このプロジェクトは、Claude Codeをより使いやすくします。** 🔊
