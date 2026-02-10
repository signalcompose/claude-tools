# Docker Sandboxes for Plugin Testing

開発中プラグインをmainブランチにmergeせずに、Claude Code上で実際にテストする方法。

## 概要

### 問題

**マーケットプレイスとして公開しているリポジトリ**で、featureブランチの変更をmainにmergeせずにテストする方法が必要。

**なぜ重要か**:
- mainにmergeすると`/plugin update`でauto updateしているユーザーがバグに巻き込まれる
- 開発中の変更を**Claude Code上で実際に実行**してテストしたい
- 「push → merge → /plugin update」のサイクルでは開発速度が遅い

### 解決策: Docker Sandboxes

Docker Desktopの`docker sandbox run`コマンドを使用して、microVM隔離環境でプラグインをテストする。

**特徴**:
- ✅ microVM隔離（最高レベルのセキュリティ）
- ✅ Dockerfile不要（自動セットアップ）
- ✅ ホスト環境に一切影響なし
- ✅ 本番環境のプラグインキャッシュと完全分離

---

## 前提条件

### 必要な環境

| 項目 | 要件 |
|------|------|
| **Docker Desktop** | 24.0.0以降 |
| **OS** | macOS / Windows / Linux |
| **Claude Code** | 最新版 |

### インストール確認

```bash
# Docker Desktop バージョン確認
docker --version
# 出力例: Docker version 29.2.0

# docker sandbox コマンド確認
docker sandbox --help
# 出力が表示されればOK
```

---

## 基本的な使い方

### ワークフロー概要

**重要**: `docker sandbox run`は**新しい独立したセッション**を起動します。現在のセッション内では実行できません。

```
┌─────────────────┐         ┌─────────────────┐
│  Terminal 1     │         │  Terminal 2     │
│  (ホスト環境)   │         │  (Sandbox環境)  │
│                 │         │                 │
│  feature/xxx    │         │  feature/xxx    │
│  開発・編集     │◀───────▶│  テスト実行     │
│                 │  報告   │                 │
│  Claude (親)    │         │  Claude (子)    │
└─────────────────┘         └─────────────────┘
```

**実行方法**:
1. **別ターミナル（ghostty等）**: 同じディレクトリで`docker sandbox run claude .`実行
2. **ユーザーが橋渡し**: サンドボックス内Claudeとのやり取りをホスト環境セッションに報告
3. **ホスト環境セッション**: 結果を確認・判断（Teamワークフローと同じ構造）

### Step-by-Step ガイド

#### Step 1: ホスト環境で開発

```bash
# Terminal 1（ホスト環境）
cd /path/to/claude-tools
git checkout feature/your-feature

# プラグインを編集
vim plugins/utils/scripts/xxx.sh
```

#### Step 2: Sandboxを起動

```bash
# Terminal 2（別ターミナルを開く）
cd /path/to/claude-tools
docker sandbox run claude .
```

**出力例**:
```
To connect to this sandbox, run:
  docker sandbox run claude-claude-tools

Starting claude agent in sandbox 'claude-claude-tools'...

>> You're now Running Claude Code in a microVM sandbox.
>> Run coding agents with --dangerously-skip-permissions (but safely).
```

#### Step 3: Sandbox内でプラグインをテスト

```bash
# Terminal 2（Sandbox内のClaude Codeセッション）
>> /plugin-test .

# 結果をTerminal 1のセッションに報告（コピー＆ペースト）
```

```bash
# Terminal 2
>> /utils:clear-plugin-cache cvi --dry-run

# 結果をTerminal 1に報告
```

```bash
# Terminal 2
>> /code:review-commit

# 結果をTerminal 1に報告
```

#### Step 4: テスト完了後、Sandboxを終了

```bash
# Terminal 2
>> exit

# Sandboxセッション終了
```

#### Step 5: ホスト環境で結果確認

```bash
# Terminal 1
# 報告されたテスト結果を確認

# 本番環境が影響を受けていないことを確認
/plugin list
# → 本番プラグインのみ表示されることを確認

# 問題なければmainにマージ
git checkout main
git merge feature/your-feature
```

---

## 実践例

### 例1: utilsプラグインのテスト

```bash
# ===== Terminal 1（ホスト環境）=====
git checkout feature/update-utils
vim plugins/utils/scripts/clear-plugin-cache.sh

# ===== Terminal 2（別ターミナル）=====
docker sandbox run claude .

# ===== Terminal 2（Sandbox内）=====
>> /plugin-test plugins/utils

# 結果:
# Phase 1: Automated Validation
# [1/5] Script Syntax: PASS
# [2/5] Executable Permissions: PASS
# [3/5] Hook Configuration: PASS
# [4/5] File Structure: PASS
# [5/5] Sandbox Compatibility: PASS
#
# Phase 2: Manual Testing
# Test 2.1: Command Execution Test
# Execute: /utils:clear-plugin-cache cvi --dry-run
# Result: PASS

>> exit

# ===== Terminal 1（ホスト環境に戻る）=====
# テスト結果を確認して、問題なければマージ
```

### 例2: codeプラグインの新機能テスト

```bash
# ===== Terminal 1 =====
git checkout feature/add-trufflehog
vim plugins/code/scripts/trufflehog-scan.sh

# ===== Terminal 2 =====
docker sandbox run claude .

# ===== Terminal 2（Sandbox内）=====
>> /plugin-test plugins/code
>> /code:trufflehog-scan
>> exit

# ===== Terminal 1 =====
# 結果確認後、マージ
```

---

## Teamワークフローとの類似性

Docker Sandboxesを使ったテストフローは、Teamワークフローと構造が似ています：

| 役割 | Team | Docker Sandboxes |
|------|------|------------------|
| **リーダー** | 現在のセッション（親Claude） | Terminal 1（ホスト環境） |
| **メンバー** | Taskツールで起動したエージェント | Terminal 2（Sandbox内Claude） |
| **通信方法** | SendMessageツール（自動） | ユーザーが橋渡し（手動） |

**違い**:
- Teamワークフロー: エージェント間通信は自動
- Docker Sandboxes: ユーザーがメッセージを手動で伝達

**共通点**:
- 親セッションが全体を統括
- 子セッション/エージェントが実作業を実行
- 結果を親に報告して判断

---

## トラブルシューティング

### Q1: "Starting sandboxd daemon..." で止まる

**症状**:
```
ensure daemon: open log file: operation not permitted
Starting sandboxd daemon...
```

**原因**: sandboxdデーモンの初回起動

**解決策**:
- 数秒待ってから再実行
- Docker Desktopを再起動

### Q2: Sandboxが起動しない

**確認項目**:
1. Docker Desktopが起動しているか
2. Docker Desktopのバージョンが24.0.0以降か
3. `docker info` コマンドが正常に動作するか

**解決策**:
```bash
# Docker Desktop再起動
# macOS: Docker Desktopアプリを終了→再起動

# 確認
docker info
```

### Q3: Sandbox内でプラグインが見つからない

**症状**:
```
>> /plugin-test .
Error: Plugin not found
```

**原因**: Sandboxがプロジェクトディレクトリ以外で起動された

**解決策**:
```bash
# 必ずプロジェクトルートで起動
cd /path/to/claude-tools
docker sandbox run claude .
```

### Q4: ホスト環境のプラグインキャッシュが影響を受けた

**確認方法**:
```bash
# ホスト環境で確認
/plugin list
ls ~/.claude/plugins/cache/claude-tools/
```

**対処法**:
- **Sandboxは完全隔離されているため、通常は起こりません**
- もし起きた場合は、`/utils:clear-plugin-cache`で修復

---

## 将来的な改善案

### Docker MCP Toolkit連携

Docker Desktopには**Docker MCP Toolkit**が統合されており、将来的にClaude Codeと直接連携できる可能性があります。

**現状**:
- Docker MCP Toolkit: MCPサーバーのDocker化と管理
- Dynamic MCP: 会話中にMCPサーバーを動的に追加
- **Docker Sandboxes制御MCP**: 未実装

**将来の可能性**:
- カスタムMCPサーバーを作成すれば、現在のセッションから直接サンドボックス内Claudeに指令を送ることも可能
- Docker API経由でサンドボックスを制御
- stdin/stdoutでサンドボックス内Claudeと通信

**参考**:
- [Docker MCP Toolkit公式ガイド](https://www.docker.com/blog/add-mcp-servers-to-claude-code-with-mcp-toolkit/)

---

## 代替方法: `--plugin-dir` オプション

Dockerが使えない環境では、`claude --plugin-dir`でセッション分離が可能です。

### 使い方

```bash
# featureブランチで開発
git checkout feature/your-feature

# 別セッションでテスト
claude --plugin-dir plugins/utils --plugin-dir plugins/code

# テスト実行
/plugin-test .
/utils:clear-plugin-cache cvi --dry-run
exit
```

### 特徴

| 項目 | Docker Sandboxes | --plugin-dir |
|------|------------------|--------------|
| **隔離レベル** | microVM（完全隔離） | セッション分離 |
| **セットアップ** | Docker Desktop必須 | 不要 |
| **実行環境** | Sandbox内（隔離） | ホスト環境 |
| **推奨度** | ⭐⭐⭐ | ⭐ |

---

## まとめ

### Docker Sandboxesのメリット

✅ **完全隔離**: microVM環境で本番環境に一切影響なし
✅ **簡単セットアップ**: Dockerfile不要、`docker sandbox run`だけ
✅ **実環境テスト**: Claude Code上で実際にプラグインを実行
✅ **開発速度向上**: merge前にテスト可能

### 推奨フロー

```
開発 → Docker Sandboxesでテスト → 問題なければmerge → /plugin update
```

**Before**:
```
開発 → merge → /plugin update → バグ発見 → 修正 → merge → ...
```

**After**:
```
開発 → Sandboxテスト → 修正 → Sandboxテスト → merge（安全）
```

---

## 参考リンク

- [Docker Sandboxes公式ブログ](https://www.docker.com/blog/docker-sandboxes-run-claude-code-and-other-coding-agents-unsupervised-but-safely/)
- [Docker MCP Toolkit](https://www.docker.com/blog/add-mcp-servers-to-claude-code-with-mcp-toolkit/)
- [日本語解説記事](https://www.publickey1.jp/blog/26/dockerclaude_codegemini_climicroivmdocker_snadboxwindowsmac.html)
