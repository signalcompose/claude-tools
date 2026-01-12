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

### 3. [VOICE]タグサポート

メッセージ内に`[VOICE]...[/VOICE]`タグを含めることで、読み上げ内容をカスタマイズ：
```
詳細な説明...

[VOICE]完了しました。設定ファイルを更新しました。[/VOICE]
```

タグがない場合は、メッセージの最初の200文字を読み上げます。

---

## セットアップ手順

### STEP 1: スクリプトの配置

以下のスクリプトを`~/.claude/scripts/`に配置：

1. **notify-end.sh** - タスク完了時の通知スクリプト
2. **kill-voice.sh** - 読み上げ中断スクリプト

### STEP 2: hooksの設定

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
    ]
  }
}
```

### STEP 3: スクリプトに実行権限を付与

```bash
chmod +x ~/.claude/scripts/notify-end.sh
chmod +x ~/.claude/scripts/kill-voice.sh
```

---

## ディレクトリ構造

```
~/Src/pro_CVI/CVI/
├── .git/                    # Gitリポジトリ
├── .claude/                 # Claude Code設定
│   └── scripts/             # スクリプト（開発用）
├── scripts/                 # インストール用スクリプト
│   ├── notify-end.sh        # タスク完了通知
│   └── kill-voice.sh        # 読み上げ中断
├── docs/                    # ドキュメント
│   └── INDEX.md             # ドキュメント索引
├── CLAUDE.md                # このファイル
└── README.md                # ユーザー向け説明
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

### Phase 1（現在）
- [x] 基本的な音声通知機能
- [x] 読み上げ中断機能
- [x] [VOICE]タグサポート

### Phase 2（次期）
- [ ] 音量調整機能
- [ ] 音声選択機能（複数の音声から選択）
- [ ] 通知のカスタマイズ（音・音声のON/OFF）

### Phase 3（将来）
- [ ] GUI設定ツール
- [ ] プロジェクトごとの設定
- [ ] 音声ファイルのカスタマイズ

---

## Git Workflow

### ブランチ戦略

**Git Flow**を採用

```
main          ← リリースブランチ（本番環境）
  └── develop ← 開発ブランチ（デフォルト）
       └── feature/xxx  ← 機能ブランチ
       └── bugfix/xxx   ← バグ修正ブランチ
       └── docs/xxx     ← ドキュメント更新ブランチ
```

**デフォルトブランチ**: `develop`

### ブランチ保護

- **main/develop への直接プッシュ禁止**
- **PR必須**（レビュー推奨: 1、管理者バイパス可能）
- **マージコミット必須**（Squash禁止）

### 🚨 絶対禁止事項

- ❌ **main → develop への逆流**（これが最も重要）
- ❌ **main・developブランチへの直接コミット**
- ❌ Squashマージ（Git Flow履歴が破壊される）
- ❌ ISSUE番号のないブランチ名

### リリースフロー

**STEP 1**: GitHubでISSUE作成（例: `Release v1.0.1`）
**STEP 2**: developブランチで最終調整・バージョン更新（必要に応じて）
**STEP 3**: PR作成（`develop` → `main`）  ← **直接PRでOK**
**STEP 4**: マージ（**マージコミット使用**）
**STEP 5**: タグ付け（`git tag v1.0.1`）

**重要**: developからmainへの直接PRは**リリース時のみ許可**。
逆方向（main → develop）は**絶対禁止**。

### 開発フロー

```bash
# 1. developブランチから最新を取得
git checkout develop
git pull origin develop

# 2. 作業ブランチを作成
git checkout -b feature/your-feature-name

# 3. 開発・コミット
git add .
git commit -m "feat: implement your feature"

# 4. プッシュ
git push -u origin feature/your-feature-name

# 5. Pull Request作成
gh pr create --base develop --head feature/your-feature-name
```

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
