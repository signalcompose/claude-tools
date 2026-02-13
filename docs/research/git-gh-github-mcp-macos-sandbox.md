# Research: git, gh CLI, GitHub MCP on macOS Sandbox

## 調査日
2026-02-13

## 調査目的
Claude CodeでのGitHub操作において、gh CLIとGitHub MCP（Docker版）のどちらを使うべきかを検証し、macOS Sandbox環境での制約とベストプラクティスを確立する。

## 調査方法
- WebSearchによる業界標準の調査
- GitHub API仕様の確認
- macOS Sandbox環境での実験
- Prompt-based permissions設定の検証

## 調査結果サマリー

### 結論: gh CLI一本化を推奨

| 操作 | 推奨ツール | 理由 |
|------|------------|------|
| ローカル操作 | `git` | Git標準、高速、履歴保持 |
| GitHub操作 | `gh` | 公式CLI、業界標準、広く採用 |

**GitHub MCP（Docker版）**: 不要（gh CLIで十分）

## 詳細調査内容

### 1. gh CLI vs GitHub MCP の比較

#### 履歴の残り方

**調査前の仮説**: 「gh pr mergeとGitHub MCP merge_pull_requestで履歴の残り方が違う」

**調査結果**: **仮説は誤り**

両方とも同じGitHub REST APIを使用:
```
PUT /repos/{owner}/{repo}/pulls/{pull_number}/merge
```

**履歴に違いが出るケース**:
- `git push` vs `GitHub MCP push_files`
  → git pushはローカルの完全な履歴を保持、GitHub MCP push_filesはスナップショット的

**結論**: PR操作（merge, create, comment等）では履歴の違いはない。違いがあるのはpush操作のみ。

#### 業界標準とベストプラクティス

WebSearchによる調査結果（2026-02-13）:

**GitHub公式の推奨**:
- gh CLIが公式の推奨ツール
- 開発者エクスペリエンス向上のために設計
- 広く採用されている

**専門家の意見**:
- gh CLIは業界標準として確立
- CI/CD環境でも広く使用
- GitHub MCPは特殊なユースケース向け（自動化、統合）

**採用事例**:
- 主要なOSSプロジェクトでgh CLIを採用
- Enterprise環境でもgh CLIが標準

### 2. macOS Sandbox環境での制約

#### TLS証明書エラー

**問題**: Sandbox環境でgh CLIがTLS証明書検証に失敗

```
error: x509: OSStatus -26276
```

**原因**: macOS Seatbelt（Sandbox機構）がKeychain（証明書ストア）へのアクセスをブロック

**解決策**: Claude Codeの自動リトライ機能

1. 最初の実行でTLSエラー発生
2. Claude Codeが自動的に`dangerouslyDisableSandbox: true`で再実行
3. ユーザーに再実行の許可を求める

#### Prompt-based Permissions設定

**目的**: 再実行時のパーミッションプロンプトを削減

**推奨設定** (`~/.claude/settings.json`):

```json
{
  "permissions": {
    "allow": ["Bash(git *)", "Bash(gh *)"],
    "ask": ["Bash(git merge *)", "Bash(gh pr merge *)"],
    "deny": ["Bash(gh repo delete *)"]
  }
}
```

**設計思想**:
- `allow`: 読み取り専用操作（status, log, diff, pr list等）
- `ask`: リスクのある操作（merge, force push等）
- `deny`: 破壊的操作（repo delete等）

**効果**:
- `git status`、`gh pr list`等は自動承認
- `gh pr merge`はユーザー確認が必要
- Sandbox再実行時のプロンプトが削減

### 3. PR Status確認のベストプラクティス

#### Checks API vs Combined Status API

**推奨**: Checks API（GitHub Actions対応）

```bash
# ✅ 正しい（Checks API）
gh pr view <PR番号> --json statusCheckRollup --jq '.statusCheckRollup[] | "\(.context // .name): \(.state // .conclusion)"'

# ❌ 古い（Combined Status API、GitHub Actionsに非対応）
gh pr view <PR番号> --json statusCheckRollup,commits --jq '.commits[-1].statusCheckRollup'
```

**Checks APIの利点**:
- GitHub Actions対応
- より詳細な状態情報
- 最新の推奨API

#### PR Status確認の完全なコマンド

**Sandbox制限に注意**: `dangerouslyDisableSandbox: true` 必須

```bash
# 1. CIチェック状態（Checks API）
gh pr view <PR番号> --json statusCheckRollup --jq '.statusCheckRollup[] | "\(.context // .name): \(.state // .conclusion)"'
# 出力例: ci (20): SUCCESS, claude-review: SUCCESS

# 2. レビュー承認状態
gh pr view <PR番号> --json reviewDecision,reviews --jq '{reviewDecision, reviewCount: (.reviews | length)}'
# 出力例: {"reviewDecision":"REVIEW_REQUIRED","reviewCount":0}

# 3. マージ可能性
gh pr view <PR番号> --json mergeable,mergeStateStatus
# 出力例: {"mergeable":true,"mergeStateStatus":"BLOCKED"}
```

**判定ロジック**:

| 状態 | CI チェック | レビュー | ブロック理由 |
|------|------------|---------|-------------|
| Ready to merge | ✅ All SUCCESS | ✅ APPROVED | - |
| Blocked (CI) | ❌ FAILURE/PENDING | - | CI チェック失敗・実行中 |
| Blocked (Review) | ✅ All SUCCESS | ⚠️ REVIEW_REQUIRED | レビュー承認待ち |
| Blocked (Both) | ❌ FAILURE/PENDING | ⚠️ REVIEW_REQUIRED | CI + レビュー両方 |

### 4. GitHub MCP（Docker版）について

#### 提供元
- GitHub公式のMCPサーバー
- Anthropic公式プラグイン（`plugin:github:github`）ではない

#### 使用ケース
- 特殊な統合が必要な場合
- gh CLIでカバーできない機能（ほとんどない）

#### 非推奨理由
1. gh CLIで十分な機能を提供
2. 業界標準はgh CLI
3. 追加のDocker依存関係
4. メンテナンスコスト

## ベストプラクティス

### 1. GitHub操作の基本方針

```markdown
**原則**: gh CLI一本化（GitHub MCP不要）

| 操作 | 使用ツール |
|------|------------|
| **ローカル操作** | `git` |
| **GitHub操作** | `gh` |

**macOS Sandbox制約**:
- `gh` CLIはSandbox環境でTLS証明書エラーが発生する場合がある
- Claude Codeが自動的に`dangerouslyDisableSandbox: true`で再実行
- Prompt-based permissionsで再実行時のプロンプトを削減
```

### 2. 推奨settings.json設定

```json
{
  "permissions": {
    "allow": ["Bash(git *)", "Bash(gh *)"],
    "ask": ["Bash(git merge *)", "Bash(gh pr merge *)"],
    "deny": ["Bash(gh repo delete *)"]
  }
}
```

### 3. PRステータス確認テンプレート

```bash
# Bash tool with dangerouslyDisableSandbox: true
gh pr view <PR番号> --json statusCheckRollup,reviewDecision
```

## 参考リソース

- GitHub CLI公式ドキュメント: https://cli.github.com/
- GitHub REST API: https://docs.github.com/en/rest
- GitHub Checks API: https://docs.github.com/en/rest/checks
- macOS Sandbox (Seatbelt): Apple Developer Documentation

## 追加調査が必要な項目

- [ ] GitHub MCPの具体的な使用ケース
- [ ] gh CLIでカバーできない機能の有無
- [ ] Enterprise環境での制約

## 更新履歴

- 2026-02-13: 初版作成（dropcontrol）
