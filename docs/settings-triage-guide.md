# Settings Triage Guide — `.claude/settings.json` 棚卸し手順

> **Last Updated**: 2026-04-17
> **Audience**: Claude Code を長期運用しているユーザー / プロジェクトメンテナー
> **対象ファイル**: `<plugin>/.claude/settings.json`, `.claude/settings.json`, `.claude/settings.local.json`

---

## 目的

Claude Code の個人 `settings.local.json` は、`ask → allow` を都度承認するたびに allow が追加される構造上、放っておくと肥大化する。本ガイドは:

1. 肥大化した `settings.local.json` の **棚卸し手順**
2. チーム共有価値のある allow の `.claude/settings.json` への **昇格基準**
3. 危険操作の `deny` **明示化**

を通じて、**安全性を維持しつつ dev workflow の自動化度を保つ** ことを目指す。

Dev Cycle (`/code:dev-cycle`) 固有の自律実行用パーミッション設計は [dev-cycle-guide.md](./dev-cycle-guide.md) を参照。本ガイドは **任意のプロジェクト** に適用できる汎用手順。

---

## 3層設定モデル

Claude Code の permission は 3 つのレイヤーで定義される。各層の**役割と対象**を区別することが本ガイドの前提。

| 層 | パス | 役割 | 対象 | Git 管理 |
|----|------|------|------|:--------:|
| プラグイン同梱 | `<plugin>/.claude/settings.json` | プラグインが必要とする最小権限 | プラグイン利用者全員 | プラグインリポジトリ |
| プロジェクト共有 | `.claude/settings.json` | チーム共有、プロジェクト固有の権限 | プロジェクトコラボレータ | プロジェクト |
| 個人ローカル | `.claude/settings.local.json` | 真に個人固有な権限 | 単一ユーザー | gitignored |

### アンチパターン

- プロジェクト共有が空で、個人 local が肥大化 → 新メンバー / 新環境で同じ prompt を都度 allow し直す
- プラグイン同梱が薄い → プラグインの標準フローで毎回 prompt
- プロジェクト共有に個人アカウント依存の allow が混ざる → 他メンバーで意味をなさない or 混乱

---

## 肥大化の兆候

以下のいずれかが当てはまったら棚卸しの合図:

- `settings.local.json` の `allow` 項目が **50 個以上**
- シェルキーワード (`do`, `done`, `fi`, `else`, `then`) が allow にある
- コメント付きコマンド (`Bash(# ～を探す find ...)`) がある
- 古いプラグインキャッシュパス (`/Users/<you>/.claude/plugins/cache/<name>/<old-hash>/...`)
- 1 回限りの HEREDOC コミットコマンドがまるごと allow
- プロジェクト絶対パス (`/Users/<you>/Src/<project>/plugins/<plugin>/scripts/<script>.sh:*`)

---

## 棚卸しトリアージ手順

### Step 1: 現状把握

```bash
python3 -c "
import json
for f in ['.claude/settings.json', '.claude/settings.local.json']:
    try:
        d = json.load(open(f))
        p = d.get('permissions', {})
        print(f'{f}: allow={len(p.get(\"allow\",[]))}, ask={len(p.get(\"ask\",[]))}, deny={len(p.get(\"deny\",[]))}')
    except: pass
"
```

数が 50 を超えていたら、次ステップへ。

### Step 2: 分類

各 `allow` エントリを以下のいずれかに振り分ける。判断は**機械的に**、迷ったら「個人残留」寄りに。

| 分類 | 判断基準 | 行き先 |
|------|---------|-------|
| **削除** | ループ断片、コメント付き、1 回限り、古いキャッシュパス、プロジェクト絶対パス | - |
| **プラグイン昇格** | そのプラグインの skill が必ず使う操作 | `<plugin>/.claude/settings.json` |
| **プロジェクト共有** | プロジェクトのチーム全員が使う操作 | `.claude/settings.json` |
| **個人残留** | 個人アカウント、個人ブラウザセッション、個人 MCP サーバー等 | `.claude/settings.local.json` |

### Step 3: 書き換え実施

- `.claude/settings.json` (共有): `Edit` / `Write` で拡張、git commit 対象
- `.claude/settings.local.json` (個人): `Write` で minimal 版へ全置換、gitignored

### Step 4: 検証

- `python3 -m json.tool <file>` で JSON validity
- `/code:review-commit` を走らせ、セキュリティ & CLAUDE.md 整合を iterative に確認
- 指摘が出たら修正 → 再レビュー (通常 3〜5 iterations で収束)

---

## 分類基準詳細

### 削除すべきもの (技術的負債)

実例ベースで列挙:

1. **シェルキーワード**: `Bash(do)`, `Bash(done)`, `Bash(then)`, `Bash(else)`, `Bash(fi)`
2. **コメント付きコマンド**: `Bash(# 最新のキャッシュパスを確認 ls -td ...)`
3. **1 回限りの HEREDOC**: `Bash(git commit -m "$(cat <<'EOF'...)` 全体
4. **古いプラグインキャッシュパス**: `Bash(/Users/<user>/.claude/plugins/cache/<plugin>/<old-hash>/scripts/...)` (commit hash 固定で陳腐化)
5. **プロジェクト絶対パス**: `Bash(/Users/<user>/Src/<project>/plugins/<plugin>/scripts/<script>.sh:*)` (`${CLAUDE_PLUGIN_ROOT}` で書けるため)
6. **1 回限りの調査ループ**: `Bash(for id in "<hash1>" "<hash2>")`, `Bash(for profile in "Profile 1" "Profile 2")`
7. **`__NEW_LINE_*__` 系の自動生成 allow**: Claude Code 内部で稀に生成される、実用価値のない文字列

### プラグイン昇格候補

プラグインの主要 skill が必ず使う operation だけ:

- `dev-cycle`: `jq`, `mkdir -p .claude`, `rm -f .claude/dev-cycle.state.json`, `Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/*)`
- `chezmoi:*`: `chezmoi status/diff/apply/cat/source-path`
- 各プラグイン固有のスクリプト実行

これらは**全プラグインユーザーに恩恵がある**。ただし「そのプラグインを使わないユーザー」にも強制される点に注意。最小セットに留める。

### プロジェクト共有候補

プロジェクトのチーム全員が使う汎用操作:

- Git 書き込み基本: `Bash(git add:*)`, `Bash(git commit:*)`, `Bash(git push origin :*)`, `Bash(git push -u origin :*)`
- GitHub 操作: `Bash(gh pr list:*)`, `Bash(gh pr create:*)`, `Bash(gh issue create:*)`
- 共通 WebFetch: `WebFetch(domain:api.anthropic.com)`, `WebFetch(domain:docs.github.com)`
- 共通 Skill: `Skill(code:review-commit)`, `Skill(pr-review-toolkit:review-pr)`
- 共通 MCP: Serena, Context7 (プロジェクトで依存するもの)

### 個人残留

他メンバーに共有すべきでない、または個人依存:

- 個人 Playwright browser セッション (ログイン状態含む)
- 1Password CLI (`op item list/get`)
- 個人 Slack workspace (`mcp__slack__*`)
- 個人 WebFetch ドメイン (AWS 個人アカウント、個人ダッシュボード)
- `outputStyle`, `sandbox` 等の個人 preferences

---

## CLAUDE.md 整合チェックリスト

`.claude/settings.json` を書き換える前に、プロジェクト CLAUDE.md のルールとの整合を確認:

### Force Push

| 項目 | あるべき配置 |
|------|-------------|
| `Bash(git push --force :*)` | **deny** (完全禁止) |
| `Bash(git push -f :*)` | **deny** |
| `Bash(git push --force-with-lease:*)` | **ask** (rebase 後のみ許可) |
| `Bash(git push:*)` in **allow** | ⚠️ narrow pattern 推奨。`ask` ルールで `--force-with-lease` を個別 gate すれば precedence (`deny > ask > allow`) により bypass はされないが、意図より広い許可になりやすい |
| `Bash(git push origin :*)` in **allow** | ✅ 通常 push は narrow pattern で allow |

### Merge ガード (user 明示確認)

| 項目 | あるべき配置 |
|------|-------------|
| `Bash(gh pr merge:*)` | **ask** |
| `mcp__github__merge_pull_request` | **ask** (MCP 経由も対称的に) |
| `Bash(gh pr merge --squash :*)` | **deny** (squash 禁止プロジェクトの場合) |

### シークレット読み取り防止

| 項目 | あるべき配置 |
|------|-------------|
| `Read(./.env)` | **deny** |
| `Read(./.env.*)` | **deny** |
| `Read(~/.ssh/*)` / `Read(~/.gnupg/*)` | プロジェクトのセキュリティ要件に応じて **deny** 追加を検討 (`~/` prefix は macOS で公式サポート済み) |

> ⚠️ **重要な注意**: `Read` deny は Claude の**組み込み Read ツールのみ**をブロックし、`Bash(cat .env)` 等のシェル経由読み取りは防げない。完全なシークレット保護には Claude Code の [OS サンドボックス](https://code.claude.com/docs/en/sandboxing) を併用する必要がある。

### MCP 書き込み系の対称ガード

CLAUDE.md のルールは **どのツール経由でも** 適用すべき:

| 項目 | あるべき配置 | 理由 |
|------|-------------|------|
| `mcp__github__create_or_update_file` | **ask** | main 直接コミット回避 |
| `mcp__github__update_pull_request` | **ask** | base branch 変更等 silent mutation 防止 |
| `mcp__github__create_pull_request` | **allow** (CLAUDE.md で PR 作成は自動許容) | プロジェクト方針次第 |

---

## 推奨 Deny Patterns (プラグイン同梱の最小セット)

`plugins/<plugin>/.claude/settings.json` の deny リスト推奨 (全ユーザーに配布):

```json
"deny": [
  "Bash(git push --force *)",
  "Bash(git push -f *)",
  "Bash(sudo *)",
  "Bash(chmod 777 *)",
  "Read(./.env)",
  "Read(./.env.*)"
]
```

上記 `Read(.env)` 系の deny は Claude Read ツールにのみ効く。Bash 経由読み取りは別途サンドボックス等で対処する前提。

### 含めないもの (legitimate workflow を破壊する)

| Pattern | 含めない理由 |
|---------|-------------|
| `Bash(rm -rf *)` | `rm -rf node_modules`, `rm -rf dist` 等で legitimate に使う |
| `Bash(git reset --hard *)` | error recovery で使う standard 操作 |
| `Read(~/.ssh/*)` / `Read(~/.gnupg/*)` | プラグイン同梱の最小セットには含めない (`~/` pattern 自体は動作するが、プロジェクトのセキュリティ要件に応じて `.claude/settings.json` 側で追加する方針) |

---

## review-commit で出やすい指摘パターン

`/code:review-commit` で iterative に指摘される典型 finding (実施実績ベース):

1. **`gh pr merge` が allow に配置されている**
   → CLAUDE.md 違反。ask に移動。

2. **`--force-with-lease` が allow を通過する**
   → `Bash(git push:*)` 形式の broad allow が bypass 原因。narrow `Bash(git push origin :*)` に分離し、broad は ask に。

3. **MCP が permission gate を bypass**
   → `mcp__github__merge_pull_request`, `mcp__github__create_or_update_file`, `mcp__github__update_pull_request` は gh CLI 相当の gate で ask に。

4. **deny pattern のスペース不一致**
   → `Bash(gh pr merge --squash :*)` (space 付き) と `Bash(gh pr merge --squash:*)` (space なし) は挙動が異なる可能性。既存の pattern 流儀に合わせる。

5. **`gh api` が broad すぎる**
   → `gh api -X DELETE /repos/...` で deny を bypass できる。ask に移動。

6. **`git push -u origin` / `--set-upstream` が ask 落ち**
   → 頻用される first-push 系。allow に narrow pattern (`Bash(git push -u origin :*)`, `Bash(git push --set-upstream origin :*)`) を追加。

---

## Pattern Syntax Notes

Claude Code の permission pattern は **glob**。

- `Bash(git push :*)` と `Bash(git push *)` は等価 (どちらも prefix + space + wildcard)
- space が word boundary を強制 → `Bash(git push --force *)` は `git push --force-with-lease` にマッチしない
- 複合コマンド (`&&`, `||`, `;`, `|`) はサブコマンド個別評価 → `Bash(safe-cmd *)` は `safe-cmd && rm -rf` を allow しない
- 優先順位: **`deny > ask > allow`**。同じ tier 内は最初のマッチが勝つ

詳細: [Claude Code permissions](https://code.claude.com/docs/en/permissions)

---

## built-in `less-permission-prompts` スキルとの関係

Claude Code には `less-permission-prompts` という built-in スキルがある。transcript を scan して頻出の read-only 操作を `.claude/settings.json` に allow として追加する。

**本ガイドと補完関係**:

| built-in skill が得意 | 本ガイドが得意 |
|---------------------|--------------|
| transcript から read-only 操作を自動抽出 | write / MCP 書き込み系の扱い |
| 「settings.json がほぼ空」の状態で価値大 | 既に整理済みの設定の定期棚卸し |
| 標準的な allowlist 生成 | CLAUDE.md ルール整合チェック |

**限界** (実測ベース):

- skill は「全プロジェクトの transcript」を scan するが、書き込み先は「現プロジェクトの `.claude/settings.json`」のみ → 他プロジェクト由来の pattern が大量に紛れ込む可能性
- wildcard 判定が甘く、`Bash(gh pr *)` や `Bash(npm run *)` のような task runner wildcard が候補に上がる (skill 自身の指示で禁止されているにも関わらず)
- 個人 `settings.local.json` との突合なし

→ **使い所**: 空 or ほぼ空の settings.json を持つプロジェクトで初期 allowlist を作る際。既に整理済みのプロジェクトでは本ガイドの手動棚卸しが確実。

---

## 参考実績

claude-tools での棚卸し実施結果 (2026-04-17):

| 項目 | Before | After | 効果 |
|------|-------:|------:|-----|
| `settings.local.json` allow | 133 | 33 | **75% 削減** |
| `.claude/settings.json` allow | 3 | 70 | +67 項目 (チーム共有へ昇格) |
| `.claude/settings.json` ask | 2 (broad) | 8 (specific gates) | CLAUDE.md ガード強化 |
| `.claude/settings.json` deny | 9 | 10 | squash merge 明示拒否追加 |

レビュープロセス: `/code:review-commit` で 5 iterations 実施。各 iteration で important issue を指摘・修正し、最終 `critical=0 important=0` に収束。

関連 PR:
- #191: `code` プラグイン同梱 settings に最小 deny リスト追加
- #192: プロジェクト settings の棚卸しと CLAUDE.md 整合強化

---

## 関連ドキュメント

- [dev-cycle-guide.md](./dev-cycle-guide.md): Dev Cycle 固有の自律実行パーミッション設計
- [development-guide.md](./development-guide.md): プラグイン開発ガイド
- [Claude Code permissions (公式)](https://code.claude.com/docs/en/permissions)
