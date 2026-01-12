# Private-to-Public Repository Strategy

**作成日**: 2025-11-11
**目的**: YPMのprivate開発環境からpublicコミュニティ版を作成・管理する戦略
**対象**: YPMおよび他プロジェクトでの再利用

---

## エグゼクティブサマリー

**戦略**: Two-Repository Strategy（Android AOSP新モデル準拠）

- **YPM-yamato（private）**: 実運用環境（機密情報含む）
- **YPM（public）**: コミュニティ版（機密情報完全除外）

**核心原則**:
1. Private-first development（日常開発はprivate）
2. 選択的export（git-filter-repoで機密情報除外）
3. Community contributionの受け入れ（cherry-pick）

---

## 目次

1. [背景と課題](#背景と課題)
2. [業界ベストプラクティス](#業界ベストプラクティス)
3. [Two-Repository Strategy詳細](#two-repository-strategy詳細)
4. [Git Filter-Repo使用方法](#git-filter-repo使用方法)
5. [YPM固有の実装](#ypm固有の実装)
6. [Community Contribution受け入れフロー](#community-contribution受け入れフロー)
7. [他プロジェクトへの適用](#他プロジェクトへの適用)
8. [Git Workflow設定](#git-workflow設定)

---

## 背景と課題

### YPMの特殊性

YPMは「プロジェクト管理システム」として、ユーザーの実際のプロジェクト情報を扱います:

- プロジェクト名
- プロジェクト数・統計
- コミットメッセージ
- Git情報

これらの情報は**機密情報**であり、publicリポジトリに公開できません。

### 従来のFork関係の問題点

GitHubのfork関係には以下の制約があります:

❌ **Private → Public forkは不可能**
- すべてのforkは元のリポジトリと同じ可視性を持つ
- Private repoのforkはprivateのまま
- Public repoのforkはpublicのまま

❌ **可視性変更時の履歴公開リスク**
- Private repoをpublic化すると、全コミット履歴が公開される
- 過去の機密情報も公開される

**結論**: Fork関係は使用できない

---

## 業界ベストプラクティス

### Linux Kernel Development

#### プロセス

1. **企業の内部ブランチ**
   - 各企業（Intel、Samsung、Google等）は独自の内部開発ブランチを持つ
   - プロプライエタリな機能、未公開ハードウェア対応を含む

2. **Upstream contribution用のpublicブランチ**
   - 内部ブランチとは別に、upstream貢献用のpublicブランチを管理
   - Cherry-pickまたはmergeで選択的にコミットを移動

3. **Patch submission workflow**
   - `git format-patch`でパッチを生成
   - メーリングリスト（LKML）へ送信
   - レビュー → 修正 → 承認 → maintainerがmerge

#### YPMへの適用

✅ 内部ブランチ（YPM-yamato/develop）とupstream用ブランチ（YPM/main）の分離
✅ Cherry-pickによる選択的貢献
✅ メトリクス管理（どの機能をpublicに貢献したか追跡）

---

### Android AOSP（2025年3月以降）

#### 新しい開発モデル

1. **完全private開発**
   - すべてのAndroid OS開発をGoogle内部ブランチで実施
   - Public AOSPブランチは廃止

2. **Source code release**
   - 新しいAndroidバージョンリリース時にソースコードを公開
   - リリースから約1ヶ月後に公開（量産開始時期）

3. **Community contribution**
   - AOSP Gerritへのpatch submitは継続可能
   - Google engineersがレビュー → 承認された場合、internal branchへcherry-pick

#### YPMへの適用

✅ **Private-first development**（YPM-yamatoで開発）
✅ **定期的なsource release**（リリース時にpublic repoを更新）
✅ **Community contributionの受け入れ**（public repoへのPRを受け付け、cherry-pickでprivateへ取り込み）

**新しいAndroidモデルはYPMに最適**:
- 日常開発はprivateで実施
- リリース時のみpublicへexport
- 機密情報を完全に制御可能

---

## Two-Repository Strategy詳細

### アーキテクチャ

```
YPM-yamato (private)          YPM (public)
├── develop (default)         ├── main (default)
├── feature/xxx               ├── develop
└── (実プロジェクト情報)      └── (機密情報なし)
         │
         │ git-filter-repo export
         ↓
    機密情報除外
         │
         ↓
    YPM (public)
```

### ファイル管理戦略

#### 完全にprivateなファイル（公開禁止）

- `PROJECT_STATUS.md` - 実プロジェクトの状況
- `config.yml` - 実環境の設定
- `CLAUDE.md` - 個人用開発ツール設定
- `docs/research/*-private.md` - 個人的なリサーチメモ

**管理方法**:
- `.gitignore`に追加
- Export scriptでフィルタリング

#### Public/Private共通ファイル

- `CONTRIBUTING.md` - 開発ガイド
- `docs/development/` - 開発原則、Git Workflow
- `scripts/` - スクリプト
- `templates/` - テンプレート

**管理方法**:
- 機密情報を含まない一般化された内容
- Public/Private両方でgit管理

#### Publicのみのファイル

- `config.example.yml` - 設定テンプレート

---

## Git Filter-Repo使用方法

### インストール

```bash
brew install git-filter-repo
```

### 基本的な使用方法

#### 特定ファイルを履歴から削除

```bash
git filter-repo --path PROJECT_STATUS.md --invert-paths --force
```

#### コミットメッセージを書き換え

```bash
git filter-repo --message-callback '
import re
# プロジェクト名を[project]に置換
message = message.replace(b"oshireq", b"[project]")
message = message.replace(b"orbitscore", b"[project]")
# プロジェクト数を[N]に置換
message = re.sub(rb"\d+プロジェクト", rb"[N]プロジェクト", message)
return message
' --force
```

### 重要な注意事項

⚠️ **Fresh cloneでのみ動作**
- 既存リポジトリでは実行不可
- 必ず新しいcloneを作成してから実行

⚠️ **破壊的操作**
- 履歴を書き換えるため、force pushが必要
- 実行前にバックアップ推奨

---

## YPM固有の実装

### Export Script

`scripts/export-to-public.sh`:

```bash
#!/bin/bash
set -e

PRIVATE_REPO="/Users/yamato/Src/proj_YPM/YPM-yamato"
PUBLIC_REPO_URL="https://github.com/signalcompose/ypm.git"
EXPORT_DIR="/tmp/ypm-public-export-$(date +%s)"

echo "🔍 Exporting YPM to public repository..."

# Fresh clone
git clone "$PRIVATE_REPO" "$EXPORT_DIR"
cd "$EXPORT_DIR"
git checkout develop

# 機密ファイルを履歴から削除
git filter-repo \
  --path PROJECT_STATUS.md --invert-paths \
  --path config.yml --invert-paths \
  --path CLAUDE.md --invert-paths \
  --force

# コミットメッセージから機密情報削除
git filter-repo --message-callback '
import re
projects = [b"oshireq", b"orbitscore", b"picopr", b"TabClear", b"DUNGIA", b"godot-mcp", b"YPM-yamato"]
for proj in projects:
    message = message.replace(proj, b"[project]")
message = re.sub(rb"\d+プロジェクト", rb"[N]プロジェクト", message)
message = re.sub(rb"\d+ projects", rb"[N] projects", message)
return message
' --force

# Public repoにpush
git remote add public "$PUBLIC_REPO_URL"
git push public develop:main --force

echo "✅ Export completed!"
echo "⚠️  Verify: https://github.com/signalcompose/ypm"
```

### 実行手順

```bash
# Export実行
bash scripts/export-to-public.sh

# 結果確認（manual verification推奨）
cd /tmp/ypm-public-export-*
git log --oneline  # コミットメッセージ確認
git show  # 最新コミット詳細確認
```

---

## Community Contribution受け入れフロー

### 概要

外部コントリビューターがYPM（public）にPRを送った場合、以下のフローでYPM-yamato（private）に取り込みます。

### 詳細フロー

#### Step 1: Public repoでPR受信

1. 外部コントリビューターがYPM（public）にPRを作成
2. GitHub UIでPR #XXXを確認
3. コードレビュー実施

**例**: PR #10 "feat: add new scanning feature"

#### Step 2: YPM-yamato（private）でcherry-pick準備

```bash
# YPM-yamatoに移動
cd ~/Src/proj_YPM/YPM-yamato

# Public repoをremoteに追加（初回のみ）
git remote add public https://github.com/signalcompose/ypm.git

# Public repoの最新情報を取得
git fetch public

# Developブランチに切り替え
git checkout develop
```

#### Step 3: PRの変更をcherry-pick

```bash
# PRのコミットを確認
git log public/develop --oneline -10

# 特定のコミットをcherry-pick
git cherry-pick <commit-hash>

# コンフリクトが発生した場合は解決
git status
# ファイルを編集してコンフリクト解決
git add <resolved-files>
git cherry-pick --continue
```

**なぜcherry-pickを使うのか？**

- **選択的取り込み**: 必要なコミットだけを取り込める
- **履歴の独立性**: Private repoとpublic repoの履歴を分離
- **テスト環境**: Private repoで実環境テスト可能

#### Step 4: YPM-yamato（private）でテスト

```bash
# 実環境でテスト
python scripts/scan_projects.py
# 結果確認...

# 新機能をテスト
# （実際のプロジェクトで動作確認）
```

#### Step 5: YPM-yamato（private）にpush

```bash
# テスト成功後、private repoにpush
git push origin develop
```

#### Step 6: Public repoのPRをマージ

```bash
# GitHub UIでPR #XXXをマージ
# または gh CLIで
gh pr merge 10 --repo signalcompose/ypm --merge
```

### フロー図

```
外部コントリビューター
  ↓ PR作成
YPM (public) - PR #XXX
  ↓ レビュー・承認
YPM-yamato (private)
  ↓ git fetch public
  ↓ git cherry-pick <commit-hash>
  ↓ テスト（実環境）
  ↓ git push origin develop
  ↓
YPM (public) - PR #XXXをマージ
```

### 重要な注意事項

⚠️ **Public repoへの直接commit禁止**
- すべての変更はYPM-yamato（private）経由
- Public repoは定期的なexportで更新

⚠️ **テストは必須**
- Cherry-pick後、必ず実環境でテスト
- 問題があればPRに修正依頼

⚠️ **コミットメッセージの保持**
- Cherry-pickはコミットメッセージを保持
- コントリビューターのクレジットが維持される

---

## 他プロジェクトへの適用

このPrivate-to-Public戦略は、以下のようなプロジェクトに適用できます:

### 適用可能なプロジェクト

✅ **機密情報を扱うツール**
- 顧客情報、プロジェクト情報を含む開発ツール
- 社内ツールのOSS版作成

✅ **環境固有設定を含むツール**
- ディレクトリパス、API endpoint等を含む

✅ **段階的なOSS化**
- Private開発後、安定してからOSS化したいプロジェクト

### 適用手順（汎用版）

#### 1. ファイル分類

**完全にprivate**:
- 機密情報を含むファイル
- 環境固有設定

**public化可能**:
- 一般化可能なコード
- ドキュメント

#### 2. .gitignore設定

```gitignore
# Private files
config.yml
PROJECT_STATUS.md
CLAUDE.md
*-private.md
```

#### 3. Export script作成

```bash
#!/bin/bash
set -e

PRIVATE_REPO="/path/to/your/private-repo"
PUBLIC_REPO_URL="https://github.com/your-org/your-public-repo.git"
EXPORT_DIR="/tmp/export-$(date +%s)"

git clone "$PRIVATE_REPO" "$EXPORT_DIR"
cd "$EXPORT_DIR"

# 機密ファイル削除
git filter-repo \
  --path config.yml --invert-paths \
  --path CLAUDE.md --invert-paths \
  --force

# 機密情報削除（プロジェクト固有にカスタマイズ）
git filter-repo --message-callback '
import re
# 顧客名を[customer]に置換
message = message.replace(b"Acme Corp", b"[customer]")
return message
' --force

git remote add public "$PUBLIC_REPO_URL"
git push public main --force
```

#### 4. 定期Export運用

- 新機能完了時
- リリース前
- 月1回の定期メンテナンス

---

## Git Workflow設定

### ブランチ戦略

**Git Flow**を採用:

```
main          ← Release branch（public repo）
  └── develop ← Development branch（private repo）
       └── feature/xxx  ← Feature branches
```

### ブランチプロテクション設定

#### GitHub CLI

```bash
# mainブランチ保護
gh api repos/your-org/your-repo/branches/main/protection -X PUT \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":0}' \
  -f required_linear_history=false \
  -f allow_force_pushes=false \
  -f allow_deletions=false

# developブランチ保護（同様）
gh api repos/your-org/your-repo/branches/develop/protection -X PUT \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"required_approving_review_count":0}' \
  -f required_linear_history=false \
  -f allow_force_pushes=false \
  -f allow_deletions=false
```

#### マージ設定

```bash
# マージコミットのみ許可（Squash/Rebase禁止）
gh api repos/your-org/your-repo -X PATCH \
  -f allow_squash_merge=false \
  -f allow_merge_commit=true \
  -f allow_rebase_merge=false
```

**理由**: Git Flowの履歴を保持するため、マージコミットのみ許可

### Git Worktree設定

複数ブランチを同時に作業する場合、Git Worktreeが有用です:

```bash
# Main worktree
cd /path/to/your-repo

# Developブランチ用worktree追加
git worktree add ../your-repo-develop develop

# Worktree一覧確認
git worktree list
```

---

## リスク管理

### リスク1: 機密情報の誤commit

**対策**:
- Pre-commit hookで機密ファイルを検出
- `.gitignore`の徹底
- Export前の手動レビュー

**Pre-commit hook例**:

```bash
#!/bin/bash
# .git/hooks/pre-commit

SENSITIVE_FILES=("PROJECT_STATUS.md" "config.yml")

for file in "${SENSITIVE_FILES[@]}"; do
  if git diff --cached --name-only | grep -q "^$file$"; then
    echo "❌ Error: $file is staged for commit"
    echo "This file contains sensitive information."
    exit 1
  fi
done
```

### リスク2: コミットメッセージに機密情報

**対策**:
- Export scriptでコミットメッセージを自動サニタイズ
- コミット時の手動レビュー
- Commit message template使用

### リスク3: Public repoとprivate repoの履歴divergence

**対策**:
- 定期的なexport（月1回以上）
- Export前に必ずdevelopブランチを最新化
- Public repoへのdirect commitを避ける

---

## まとめ

### 推奨戦略

**Two-Repository Strategy with git-filter-repo**が最適:

✅ 機密情報を完全に制御
✅ 業界標準（Android AOSP新モデル）と一致
✅ 将来的なOSS化に対応
✅ Community contributionを受け入れ可能

### 成功の鍵

1. **Discipline（規律）**
   - 機密情報を絶対にpublic repoにcommitしない
   - Export前の手動レビューを怠らない

2. **Automation（自動化）**
   - Export scriptで人為的ミスを防止
   - Pre-commit hookで機密情報を検出

3. **Documentation（ドキュメント化）**
   - Export手順をドキュメント化
   - 新しいcontributorへのガイドライン提供

4. **Community Engagement（コミュニティ連携）**
   - Public repoへのPRを歓迎
   - Private開発の透明性を保つ

---

## 参考文献

### 技術ドキュメント

- [git-filter-repo Official Repository](https://github.com/newren/git-filter-repo)
- [GitHub Docs: About permissions and visibility of forks](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-permissions-and-visibility-of-forks)
- [Linux Kernel Contribution Maturity Model](https://docs.kernel.org/process/contribution-maturity-model.html)

### 実例

- [Braintree Payments: Our Git Workflow](http://www.braintreepayments.com/blog/our-git-workflow/)
- [Android Authority: Google will develop Android OS fully in private](https://www.androidauthority.com/google-android-development-aosp-3538503/)

### ツール

- [git-filter-repo tutorial](https://andrewlock.net/rewriting-git-history-simply-with-git-filter-repo/)

---

**ドキュメント作成**: 2025-11-11
**最終更新**: 2025-11-11
**作成者**: Hiroshi Yamato
**レビュー**: Claude (Sonnet 4.5)
