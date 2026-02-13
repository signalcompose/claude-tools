# 実装計画: CVIプラグインのMCPサーバ化

## Context（背景）

### 問題の本質

CVIプラグインの `/cvi:speak` コマンドが、sandbox制限によりブロックされています：

**調査結果**:
- **コマンド経由**: オーディオデバイスアクセスが禁止され、音声再生が完全に失敗
- **Hooks経由**: 正常に動作（notify-input.sh等）
- **Phase 1〜3の修正**: セキュリティ強化（`say -o` + `afplay`、コマンドインジェクション対策）を試みたが、sandbox制限により効果なし
- **ロールバック**: Phase 1実装前のシンプルな `say "$MSG" &` でも動作せず

**根本原因**: プラグインコマンドはsandbox内で実行されるため、オーディオデバイスへのアクセスがブロックされる。実装方法ではなく、実行環境の制限。

### なぜMCPサーバ化するのか

**MCPサーバの利点**:
1. **Sandbox制限を回避**: MCPサーバはClaude Code本体とは別プロセスで動作するため、sandbox制限を受けない
2. **安定した音声再生**: オーディオデバイスへの直接アクセスが可能
3. **設定管理の改善**: RESTful APIライクなツール設計で、設定の取得・変更が明確化
4. **将来の拡張性**: プリセット機能、統計情報、デバッグ機能などを容易に追加可能

**ユーザーメリット**:
- `/cvi:speak` コマンドが確実に動作
- Stop hookで音声通知が確実に再生される
- エラーハンドリングの改善（明確なエラーメッセージ）

---

## 推奨アプローチ

### アーキテクチャ概要

```
┌─────────────────────────────────────────────┐
│ Claude Code (Sandbox内)                     │
│                                             │
│  ┌──────────────┐      ┌─────────────────┐ │
│  │ CVI Plugin   │ ───▶ │ MCP Client      │ │
│  │              │      │                 │ │
│  │ /cvi:speak   │      │ Tool Call:      │ │
│  │ /cvi:state   │      │ cvi_speak       │ │
│  │ Stop Hook    │      │ cvi_get_config  │ │
│  └──────────────┘      └─────────────────┘ │
└─────────────────────────────────────────────┘
                              │
                         JSON-RPC (stdio)
                              │
┌─────────────────────────────▼───────────────┐
│ MCP Server (Sandbox外)                      │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │ mcp-server-cvi (Python)              │  │
│  │                                      │  │
│  │ Tools:                               │  │
│  │  - cvi_speak                         │  │
│  │  - cvi_get_config                    │  │
│  │  - cvi_set_config                    │  │
│  │  - cvi_toggle_enabled                │  │
│  │  - cvi_get_voices                    │  │
│  │  - cvi_test_voice                    │  │
│  │  - cvi_validate_setup                │  │
│  └──────────────────────────────────────┘  │
│                   │                         │
│                   ▼                         │
│  ┌──────────────────────────────────────┐  │
│  │ macOS Audio System                   │  │
│  │  - say (TTS)                         │  │
│  │  - afplay (Audio Playback)           │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 実装する機能

#### 1. MCPサーバ（新規リポジトリ: `signalcompose/mcp-server-cvi`）

**優先度HIGH（必須機能）**:

| Tool | 目的 | 入力 | 出力 |
|------|------|------|------|
| `cvi_speak` | テキスト読み上げ | text, lang, voice, rate, sync | success, details |
| `cvi_get_config` | 設定取得 | key (optional) | config |
| `cvi_set_config` | 設定変更 | key, value | success, old_value, new_value |
| `cvi_toggle_enabled` | 有効/無効切り替え | enabled (optional) | success, enabled, previous_state |
| `cvi_get_voices` | 利用可能音声一覧 | lang | voices, total_count |

**優先度MEDIUM（便利機能）**:

| Tool | 目的 | 入力 | 出力 |
|------|------|------|------|
| `cvi_test_voice` | テスト音声再生 | voice, rate, lang | success, test_text |
| `cvi_validate_setup` | セットアップ診断 | なし | valid, checks, warnings, errors |

**技術スタック**:
- **言語**: Python 3.10+
- **フレームワーク**: FastMCP（mcp[cli] >= 1.2.0）
- **依存関係**: 標準ライブラリのみ（subprocess, pathlib, tempfile）

**ファイル構造**:
```
mcp-server-cvi/
├── pyproject.toml          # パッケージ設定
├── README.md               # セットアップガイド
├── LICENSE                 # MIT
├── src/
│   └── cvi_mcp/
│       ├── __init__.py
│       ├── server.py       # FastMCPサーバ、全Tools定義
│       ├── config.py       # ~/.cvi/config読み書き
│       ├── speech.py       # 音声再生ロジック（言語検出、say実行）
│       └── utils.py        # ヘルパー関数
└── tests/
    ├── test_config.py
    ├── test_speech.py
    └── test_server.py
```

#### 2. CVIプラグインの変更

**ファイル変更**:

| ファイル | 変更内容 | 理由 |
|---------|---------|------|
| `.mcp.json` | 新規作成 | MCPサーバ起動設定 |
| `plugin.json` | `mcpServers` フィールド追加 | .mcp.jsonを参照 |
| `commands/speak.md` | MCP tool呼び出しに変更 | cvi_speak使用 |
| `commands/state.md` | MCP tool呼び出しに変更 | cvi_get_config + cvi_toggle_enabled |
| `commands/check.md` | MCP tool呼び出しに変更 | cvi_validate_setup使用 |
| `commands/speed.md` | MCP tool呼び出しに変更 | cvi_set_config(SPEECH_RATE) |
| `commands/lang.md` | MCP tool呼び出しに変更 | cvi_set_config(VOICE_LANG) |
| `commands/voice.md` | MCP tool呼び出しに変更 | cvi_set_config(VOICE_EN/JA) |
| `commands/auto.md` | MCP tool呼び出しに変更 | cvi_set_config(AUTO_DETECT_LANG) |
| `hooks/hooks.json` | Stop hookをMCP統合 | cvi_speak使用 |
| `scripts/*` | 保守モード（Phase 1）| 後に削除予定 |

**`.mcp.json`**（新規）:
```json
{
  "mcpServers": {
    "cvi": {
      "command": "uvx",
      "args": ["mcp-server-cvi"],
      "env": {
        "CVI_CONFIG_DIR": "${HOME}/.cvi"
      }
    }
  }
}
```

**`plugin.json`**（変更箇所のみ）:
```json
{
  "mcpServers": "./.mcp.json"
}
```

---

## 実装手順（3 Phases）

### Phase 1: MCPサーバ実装（2週間）

**目標**: ローカルで動作するMCPサーバを完成させる

**タスク**:
1. **リポジトリ作成** (Day 1)
   - [ ] `signalcompose/mcp-server-cvi` リポジトリ作成
   - [ ] pyproject.toml設定（mcp[cli]>=1.2.0依存）
   - [ ] README.md作成（セットアップ手順）

2. **Core実装** (Day 2-8)
   - [ ] `config.py`: ~/.cvi/config読み書き、デフォルト値管理
   - [ ] `speech.py`: 言語自動検出、say実行、同期/非同期再生
   - [ ] `server.py`: FastMCPサーバ本体
     - [ ] `cvi_speak` 実装
     - [ ] `cvi_get_config` 実装
     - [ ] `cvi_set_config` 実装
     - [ ] `cvi_toggle_enabled` 実装
     - [ ] `cvi_get_voices` 実装

3. **追加機能** (Day 9-10)
   - [ ] `cvi_test_voice` 実装
   - [ ] `cvi_validate_setup` 実装

4. **テスト** (Day 11-14)
   - [ ] ローカルテスト（`uv run mcp-server-cvi`）
   - [ ] MCP Inspector統合テスト
   - [ ] Claude for Desktop統合テスト
   - [ ] バグ修正

**検証基準**:
- `cvi_speak` で日本語・英語が正しく読み上げられる
- `cvi_set_config` で設定変更が `~/.cvi/config` に反映される
- Claude for Desktopから全toolsが呼び出せる

---

### Phase 2: プラグイン統合（1週間）

**目標**: CVIプラグインをMCPサーバに統合

**タスク**:
1. **MCP設定** (Day 1)
   - [ ] `.mcp.json` 作成
   - [ ] `plugin.json` に `mcpServers` フィールド追加

2. **コマンド書き換え** (Day 2-4)
   - [ ] `/cvi:speak` → `mcp__cvi__cvi_speak` 呼び出し
   - [ ] `/cvi:state` → `mcp__cvi__cvi_get_config` + `cvi_toggle_enabled`
   - [ ] `/cvi:check` → `mcp__cvi__cvi_validate_setup`
   - [ ] `/cvi:speed`, `/cvi:lang`, `/cvi:voice`, `/cvi:auto` → `cvi_set_config`

3. **Hooks統合** (Day 5)
   - [ ] Stop hookをMCP tool呼び出しに変更
   - [ ] SessionStart, UserPromptSubmit, NotificationはMCP統合（必要に応じて）

4. **統合テスト** (Day 6-7)
   - [ ] マーケットプレイス更新（`/plugin update`）
   - [ ] キャッシュクリア（`/utils:clear-plugin-cache cvi`）
   - [ ] Claude Code再起動
   - [ ] 全コマンド動作確認
   - [ ] Stop hook動作確認
   - [ ] 回帰テスト

**検証基準**:
- `/cvi:speak test` で音声が再生される（sandbox環境で動作）
- Stop hookで音声通知が正常に再生される
- 既存機能（`/cvi:practice`等）に影響がない

---

### Phase 3: レガシースクリプト廃止（1週間、安定稼働後）

**目標**: 既存スクリプトを削除し、完全MCP化

**タスク**:
1. **安定稼働確認** (1-2週間)
   - [ ] ユーザーフィードバック収集
   - [ ] バグ修正

2. **スクリプト削除** (Day 1-3)
   - [ ] `scripts/` ディレクトリ削除
   - [ ] README.md更新（MCP版の使い方）
   - [ ] CLAUDE.md更新

3. **ドキュメント整備** (Day 4-7)
   - [ ] 移行ガイド作成（`docs/migration-to-mcp.md`）
   - [ ] リリースノート作成
   - [ ] アーキテクチャ図更新

**検証基準**:
- スクリプト削除後も全機能が正常動作
- ドキュメントが最新状態

---

## Critical Files（変更するファイル）

### 新規作成（MCPサーバ）

1. **mcp-server-cvi/pyproject.toml**
   - パッケージ設定、依存関係定義
   - エントリーポイント: `mcp-server-cvi = "cvi_mcp.server:main"`

2. **mcp-server-cvi/src/cvi_mcp/server.py**
   - FastMCPサーバ本体
   - 全Tools定義（cvi_speak, cvi_get_config等）
   - 最重要ファイル

3. **mcp-server-cvi/src/cvi_mcp/speech.py**
   - 音声再生ロジック
   - 言語自動検出（日本語文字判定）
   - `say`コマンド実行（同期/非同期）

4. **mcp-server-cvi/src/cvi_mcp/config.py**
   - `~/.cvi/config` 読み書き
   - デフォルト値管理
   - バリデーション

### 変更（CVIプラグイン）

5. **plugins/cvi/.mcp.json**
   - MCPサーバ起動設定
   - `uvx mcp-server-cvi` で起動

6. **plugins/cvi/.claude-plugin/plugin.json**
   - `mcpServers` フィールド追加: `"./.mcp.json"`

7. **plugins/cvi/commands/speak.md**
   - Bashスクリプト実行 → MCP tool呼び出しに変更
   - 最も重要なコマンド変更

8. **plugins/cvi/hooks/hooks.json**
   - Stop hook: `check-speak-called.sh` → MCP tool呼び出し

---

## Verification（検証方法）

### 1. MCPサーバのローカルテスト

**環境構築**:
```bash
cd mcp-server-cvi
uv venv
source .venv/bin/activate  # macOS
uv add "mcp[cli]>=1.2.0"
```

**テスト実行**:
```bash
# サーバ起動テスト
uv run mcp-server-cvi

# MCP Inspectorで動作確認
npx @modelcontextprotocol/inspector uvx mcp-server-cvi
```

**テストケース**:
1. **cvi_speak - 日本語**
   ```json
   {"text": "こんにちは、これはテストです", "lang": "auto"}
   ```
   - 期待: 日本語音声で再生

2. **cvi_speak - 英語**
   ```json
   {"text": "Hello, this is a test", "lang": "auto"}
   ```
   - 期待: 英語音声で再生

3. **cvi_get_config**
   ```json
   {}
   ```
   - 期待: 全設定値が返される

4. **cvi_set_config**
   ```json
   {"key": "SPEECH_RATE", "value": 250}
   ```
   - 期待: `~/.cvi/config` が更新される

5. **cvi_get_voices**
   ```json
   {"lang": "ja"}
   ```
   - 期待: 日本語音声のみ返される

---

### 2. Claude for Desktop統合テスト

**設定**（`~/Library/Application Support/Claude/claude_desktop_config.json`）:
```json
{
  "mcpServers": {
    "cvi": {
      "command": "uvx",
      "args": ["mcp-server-cvi"],
      "env": {
        "CVI_CONFIG_DIR": "${HOME}/.cvi"
      }
    }
  }
}
```

**テスト**:
1. Claude for Desktop再起動
2. "Use mcp__cvi__cvi_speak to say 'Test message'" を実行
3. 音声が再生されることを確認

---

### 3. プラグイン統合テスト

**準備**:
```bash
# マーケットプレイス更新
/plugin update

# キャッシュクリア
/utils:clear-plugin-cache cvi

# Claude Code再起動
```

**テストケース**:
1. **`/cvi:speak` コマンド**
   ```
   /cvi:speak こんにちは、テストです
   ```
   - 期待: 音声が再生される

2. **`/cvi:state` コマンド**
   ```
   /cvi:state show
   ```
   - 期待: 現在の設定が表示される

3. **`/cvi:speed` コマンド**
   ```
   /cvi:speed 250
   /cvi:state show
   ```
   - 期待: 話速が250に変更される

4. **`/cvi:check` コマンド**
   ```
   /cvi:check
   ```
   - 期待: セットアップ診断結果が表示される

5. **Stop Hook**
   - Claude Codeセッション終了
   - 期待: 音声通知が再生される

---

### 4. 回帰テスト

**既存機能の確認**:
- [ ] `/cvi:practice` コマンドが動作する（変更なし）
- [ ] `/cvi:setup` コマンドが動作する（変更なし）
- [ ] 設定ファイル `~/.cvi/config` の形式が変わっていない
- [ ] 他のプラグイン（gemini, kiro等）に影響がない

---

## リスク管理

### 技術的リスク

| リスク | 対策 | 影響度 |
|--------|------|--------|
| macOS専用機能（`say`） | README.mdに明記、将来的にLinux対応検討 | 中 |
| MCPサーバ起動時間 | FastMCP使用、依存関係最小化 | 低 |
| 言語自動検出の精度 | 既存ロジック移植、明示的指定も可能 | 低 |

### 運用リスク

| リスク | 対策 | 影響度 |
|--------|------|--------|
| 既存ユーザーへの影響 | 段階的移行、詳細な移行ガイド提供 | 中 |
| ドキュメント更新 | Phase 2完了時に一括更新 | 中 |
| デバッグの困難さ | stderrログ、`/cvi:check`診断機能 | 中 |

---

## 成功基準

Phase 2完了時点で、以下をすべて満たすこと:

- [ ] `/cvi:speak` コマンドがsandbox環境で正常動作
- [ ] Stop hookで音声通知が確実に再生される
- [ ] 全設定コマンド（speed, lang, voice, auto）が動作
- [ ] セットアップ診断（`/cvi:check`）が正確に動作
- [ ] 既存機能（`/cvi:practice`等）に影響がない
- [ ] エラーハンドリングが改善され、明確なエラーメッセージが表示される
- [ ] ドキュメントが最新状態（README.md、CLAUDE.md）

---

## 参考資料

- **調査結果**: Explore agents調査（CVIプラグイン全機能、MCP登録方法、Python SDK）
- **設計書**: Plan agent設計（MCPサーバTools仕様、プラグイン統合方法）
- **既存実装**: `plugins/cvi/scripts/speak.sh`, `plugins/cvi/commands/speak.md`
- **MCP公式**: https://modelcontextprotocol.io/docs/develop/build-server
- **FastMCP**: https://github.com/modelcontextprotocol/python-sdk

---

## Serenaメモリ保存（実装後）

実装完了後、以下の内容をSerenaメモリに保存：
- CVIプラグインMCPサーバ化の経緯
- sandbox制限により音声再生が失敗した問題
- MCPサーバ化による解決
- 実装した全Tools
- Phase 1-3の移行プロセス
