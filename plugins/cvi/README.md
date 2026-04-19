# CVI (Claude Voice Integration)

Claude Codeのタスク完了時に音声通知を行うシステム

---

## 概要

**CVI**は、Claude Codeの作業を音声でフィードバックするhooksシステムです。

### 特徴

- 🔊 **音声通知**: タスク完了を音声で通知（`/cvi:speak` Skill tool使用）
- ⏸️ **自動中断**: 読み上げ中に新しい指示を出すと自動停止
- 🌐 **多言語対応**: 日本語・英語を自動判定
- 🔒 **プロジェクト分離**: 複数プロジェクトの音声が干渉しない
- 🛡️ **堅牢性**: エラーログ、依存関係チェック、自動ロッククリーンアップ
- 🎯 **推奨**: `/cvi:speak` Skill tool（[VOICE]タグは非推奨）

---

## 必要環境

- **OS**: macOS（`say`, `afplay`, `osascript` コマンド使用）
- **Claude Code**: 最新版
- **`uv`**: MCP server の Python 依存解決に使用（`brew install uv`）
  - MCP server は `uv run --script` で自動的に temporary venv を作成し、user の
    site-packages を汚染せず動作する
  - PEP 668 制約のある macOS Homebrew / Xcode Python を回避

---

## インストール

### プラグインとしてインストール（推奨）

Claude Codeのプラグインシステムを使用してインストールできます：

```bash
# Claude Codeで以下のコマンドを実行
/plugin add signalcompose/cvi
```

これだけで完了です。hooks、コマンド、スキル、MCP server (`cvi-voice`) が自動的に設定されます。

### MCP server の起動について

`cvi-voice` MCP server は `uv run --script` で自動起動します。初回のみ `uv`
が `mcp` パッケージを temporary venv に解決する時間（数秒）がかかりますが、
以降は cached されます。ユーザー側で追加 install の作業は不要です。

`uv` が PATH に無い場合は MCP server 起動に失敗し、Claude Code 側で
`cvi-voice` tool が登録されません。その際は `brew install uv` 後に
Claude Code を再起動してください（[Bash fallback について](#実行経路-mcp-と-bash-fallback) も参照）。

### 初期設定

インストール後、必要に応じて設定を調整：

```bash
/cvi:speed 200    # 読み上げ速度（デフォルト: 200wpm）
/cvi:lang ja      # [VOICE]タグ言語（デフォルト: ja）
/cvi:voice list   # 利用可能な音声を確認
```

---

### 手動インストール（非推奨）

手動セットアップは **非推奨**です。Claude Code のプラグインシステムが登場する前の
手順であり、現在の MCP server + hooks + commands + skills を全て自前で配線する
必要があります。プラグイン経由のインストール（上記）を強く推奨します。

どうしても手動構成が必要な場合は `scripts/cvi-setup` を参照してください。

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

## 技術仕様

### アーキテクチャ

#### 実行経路: MCP と Bash fallback

`/cvi:speak` は 2 つの経路を持つ。`speak.md` が **MCP を優先**して呼び出し、
利用不可の場合に Bash fallback を試す構成:

| 経路 | 実装 | Sandbox | bypass 要件 |
|------|------|---------|-----|
| **MCP (優先)** | `mcp/server.py` (Python FastMCP, `uv run --script`) | 外（subprocess） | 不要（sandbox 制約外で動作） |
| **Bash (fallback)** | `scripts/post-speak.sh` → `speak-sync.sh` | 内 | `dangerouslyDisableSandbox: true` |

MCP 経路は Claude Code sandbox の外で動作するため、macOS audio API（`say` /
`afplay` / `osascript`）が `dangerouslyDisableSandbox: true` bypass なしで
到達できる。bash fallback は defense in depth として温存。

#### Phase 1: 同期音声再生（MVP, 2026-02）

- **Bash**: `/cvi:speak` → `post-speak.sh` → `speak-sync.sh`（フォアグラウンド `say`）
- **設定読み込み**: `~/.cvi/config` から voice / rate / language を読む
- **タイミング保証**: 音声完了後に `Speaking: ...` を stdout 出力（hook 契約）

#### Phase 2: プロジェクト分離（2026-02）

- **プロジェクト固有のロック**: `/tmp/claude/cvi/${PROJECT_HASH}.lock`
  - プロジェクトルートの MD5 ハッシュ（16 文字）で分離
  - `mkdir` ベースの atomic lock、30 秒 timeout
- **Sentinel Value**: `INITIALIZING` で race condition を軽減
- **複数プロジェクト対応**: 異なるプロジェクトの音声が並行再生可能

#### Phase 3: エラーハンドリングと堅牢性（2026-02）

- **ロッククリーンアップ**: SessionStart hook で古いロックを自動削除
  - プロセス存在確認、PID ファイル整合性チェック
- **エラーログ**: `~/.cvi/error.log`（タイムスタンプ付き、1MB 制限）
- **依存関係チェック**: SessionStart hook で `say` / `afplay` / `osascript` / `jq` 等を確認

#### Phase 4: MCP server 化（2026-04, 現在）

- **MCP server** (`mcp/server.py`): Python FastMCP で `speak(text, voice?, rate?)` tool 提供
  - tool signature は [parrotvox](https://github.com/signalcompose/parrotvox)（CVI の最終後継）に合わせており、
    将来の移行で `speak.md` の server 指定を差し替えるだけで完了する設計
  - PEP 723 inline metadata で `mcp>=1.0,<2.0` を自動解決
  - `uv run --script` で temporary venv に隔離、user の Python を汚染しない
- **sandbox 内動作**: MCP server は Claude Code サブプロセスとして sandbox 外で実行されるため、
  従来 bypass が必要だった audio API 呼び出しが permission prompt なしで通る

### ファイル構成

```
/tmp/claude/cvi/
├── ${PROJECT_HASH}.lock         # プロジェクト別ロックファイル
└── ${PROJECT_HASH}.lock.pid     # sayプロセスのPID記録

~/.cvi/
├── config                        # グローバル設定
└── error.log                     # エラーログ（1MB制限）
```

### パフォーマンス

- **音声再生レイテンシ**: 音声の長さのみ（例: 3秒の音声 = 3秒待機）
- **ロックオーバーヘッド**: <10ms
- **プロジェクト並行実行**: 制限なし（プロジェクトごとに独立）

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
