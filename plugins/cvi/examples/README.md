# CVIの設定例

このディレクトリには、CVIを使用するための設定例が含まれています。

## settings.json

Claude Code用のhooks設定テンプレートです。

### インストール方法

#### 方法1: 手動でマージ（推奨）

既存の`~/.claude/settings.json`がある場合、手動でhooksセクションをマージしてください：

```bash
# 既存の設定を確認
cat ~/.claude/settings.json

# エディタで編集してhooksセクションを追加
nano ~/.claude/settings.json
```

#### 方法2: 新規インストール

`~/.claude/settings.json`が存在しない場合、そのままコピーできます：

```bash
# 設定ファイルをコピー
cp examples/settings.json ~/.claude/settings.json

# 内容を確認
cat ~/.claude/settings.json
```

### 設定内容

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

### hooksの説明

#### UserPromptSubmit

- **タイミング**: ユーザーが新しい指示を送信する前
- **動作**: 現在再生中の音声を停止
- **スクリプト**: `kill-voice.sh`

#### Stop

- **タイミング**: Claude Codeがタスクを完了した時
- **動作**: macOS通知、Glass音、音声読み上げ
- **スクリプト**: `notify-end.sh`

---

## カスタマイズ

### 特定のプロジェクトでのみ有効化

`matcher`フィールドを使って、特定のディレクトリでのみhooksを有効化できます：

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "/Users/yamato/Src/important-project",
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

### 通知のみ有効化（音声なし）

`notify-end.sh`の音声部分をコメントアウトすることで、通知のみにできます。

---

## トラブルシューティング

### hooksが動作しない

1. **Claude Codeを再起動**: 設定変更後は必ず再起動が必要です
2. **スクリプトの実行権限を確認**: `ls -l ~/.claude/scripts/`
3. **パスを確認**: スクリプトが正しい場所にあるか確認

### 設定がJSONエラーになる

- JSONの文法を確認してください（カンマ、括弧など）
- オンラインJSONバリデーターで検証できます

---

**より詳しい情報は、[README.md](../README.md)を参照してください。**
