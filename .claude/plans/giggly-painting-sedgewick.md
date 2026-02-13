# 実装計画: Progressive Disclosure影響範囲調査と修正

## Context（背景）

### 問題の発見

chezmoiプラグインの `/chezmoi:sync` コマンドがワーキングディレクトリ制限によりブロックされる問題を調査した結果、**Progressive Disclosure（Referencesセクション）**の実装方法に起因する全体的な問題が判明しました。

**エラー例**:
```
Error: Bash command permission check failed for pattern "!`cat /Users/yamato/.claude/plugins/cache/claude-tools/chezmoi/.../references/diff-interpretation-guide.md`": cat in '/Users/yamato/.claude/plugins/cache/...' was blocked. For security, Claude Code may only concatenate files from the allowed working directories
```

**根本原因**:
1. **2026-02-09**: chezmoi がコマンドからスキルへ統一（commit: dd9afde）
2. **新機能**: Progressive Disclosure（Referencesセクション）追加
3. **Claude Code動作**: Markdownリンクを `!`cat ...`` に自動展開
4. **制限**: プラグインキャッシュディレクトリがワーキングディレクトリ外のためブロック

---

## 調査結果サマリー

### 影響範囲

**Progressive Disclosureを使用しているスキル**: 8個

| プラグイン | スキル | Referencesファイル数 | 実装 | 修正必要 |
|-----------|--------|-----------------|------|---------|
| **chezmoi** | setup | 6ファイル | Markdownリンク | ✅ 必要 |
| **chezmoi** | shell-sync-setup | 3ファイル | Markdownリンク | ✅ 必要 |
| **chezmoi** | sync | 2ファイル | Markdownリンク | ✅ 必要 |
| **chezmoi** | commit | 2ファイル | Markdownリンク | ✅ 必要 |
| **code** | review-commit | 1ファイル | Markdownリンク | ✅ 必要 |
| **ypm** | project-bootstrap | 10ファイル | 環境変数 | ✅ 正しい |
| **ypm** | git-workflow-setup | 2ファイル | 環境変数 | ✅ 正しい |
| **ypm** | project-status-update | 2ファイル | 環境変数 | ✅ 正しい |

**修正対象**: 5スキル（chezmoi: 4, code: 1）
**参考実装**: 3スキル（ypm: すべて正しい実装）

### Claude Code公式の実装パターン

#### 正しい実装（YPMパターン - 推奨）

```markdown
## How to Execute

Read the reference files:

- **Phase 1**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/phase-1.md`
- **Phase 2**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/phase-2.md`
```

**特徴**:
- `${CLAUDE_PLUGIN_ROOT}` 環境変数で絶対パス指定
- Claudeが環境変数を展開し、ユーザーがRead toolで読む
- ワーキングディレクトリに依存しない

**YPMの成功例**: project-bootstrap（10ファイル）、git-workflow-setup（2ファイル）

#### 誤った実装（Markdownリンク - 修正必要）

```markdown
## References
- Diff の読み方: [references/diff-interpretation-guide.md](references/diff-interpretation-guide.md)
```

**問題点**:
- Markdownリンクは**Claude Codeで自動解決されない**（仕様）
- 相対パス解決が不安定
- ワーキングディレクトリ制限でブロックされる

**修正対象**: chezmoi（4スキル）、code（1スキル）

---

## 推奨される修正アプローチ

### Claude Code標準パターンへの統一（推奨）

**方針**: YPMパターンを全プラグインの標準実装とする

**根拠**:
- YPMの実装が**Claude Code公式の仕様に適合**
- Markdownリンクは**仕様上動作しない**（バグではなく設計）
- `${CLAUDE_PLUGIN_ROOT}` 環境変数が正しい参照方法

**対象**: chezmoi（4スキル）、code（1スキル）

**方法**:
1. Markdownリンク形式を `${CLAUDE_PLUGIN_ROOT}` 形式に変更
2. Referencesファイルはそのまま維持（Progressive Disclosure継続）
3. YPMパターンに統一

**変更例（chezmoi/sync）**:
```markdown
# 変更前（誤った実装）
## References
- Diff の読み方: [references/diff-interpretation-guide.md](references/diff-interpretation-guide.md)
- エラー対処: [references/error-handling.md](references/error-handling.md)

# 変更後（正しい実装）
## How to Execute

### Step 1: Fetch and Apply

Run: !`chezmoi update -v`

### Step 2: Report Results

If needed, read reference files:

- **Diff interpretation**: Read `${CLAUDE_PLUGIN_ROOT}/skills/sync/references/diff-interpretation-guide.md`
- **Error handling**: Read `${CLAUDE_PLUGIN_ROOT}/skills/sync/references/error-handling.md`
```

**メリット**:
- ✅ Claude Code仕様に完全準拠
- ✅ Progressive Disclosureを維持
- ✅ YPMと統一された参照方法
- ✅ ワーキングディレクトリに依存しない
- ✅ 環境変数自動展開で確実に動作

**デメリット**:
- Markdownプレビューで読みにくい（実運用では問題なし）
- 5スキルの修正が必要（全体の62.5%）

---

## 推奨する実装計画

### Phase 1: 全スキルをClaude Code標準パターンに統一

**目的**: 全プラグインでYPMパターン（`${CLAUDE_PLUGIN_ROOT}`）を標準化

**対象**:
- **修正必要**: chezmoi（4スキル）、code（1スキル）
- **参考実装**: ypm（3スキル）- すでに正しい

**期間**: 1-2日

**タスク**:

#### 1. chezmoi プラグイン修正（4スキル）

| スキル | 変更内容 | 優先度 |
|--------|---------|--------|
| **sync** | Referencesセクション（2ファイル）をYPMパターンに | 高 |
| **setup** | Referencesセクション（6ファイル）をYPMパターンに | 高 |
| **commit** | Referencesセクション（2ファイル）をYPMパターンに | 中 |
| **shell-sync-setup** | Referencesセクション（3ファイル）をYPMパターンに | 中 |

#### 2. code プラグイン修正（1スキル）

| スキル | 変更内容 | 優先度 |
|--------|---------|--------|
| **review-commit** | Referencesセクション（1ファイル）をYPMパターンに | 中 |

#### 3. 実装テンプレート作成

YPMパターンを標準テンプレートとして文書化：

```markdown
## How to Execute

### Step 1: [Step Name]

[Step instructions]

### Step 2: [Step Name]

[Step instructions]

## Reference Files (read as needed)

- **[Topic 1]**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/topic-1.md`
- **[Topic 2]**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/topic-2.md`
```

**成果物**:
- 全スキルが統一されたClaude Code標準パターンを使用
- 新規スキル作成時のテンプレート（`docs/skill-template.md`）
- Progressive Disclosureガイドライン（`docs/progressive-disclosure.md`）

### Phase 2: ドキュメント整備

**期間**: 0.5日

**タスク**:
1. **docs/progressive-disclosure.md** を作成
   - Claude Code標準パターンの説明
   - YPMパターンの実装例
   - Markdownリンクが動作しない理由

2. **docs/skill-template.md** を作成
   - 新規スキル作成時のテンプレート
   - References使用時のベストプラクティス

3. **CLAUDE.md** を更新
   - スキル開発ガイドラインにYPMパターンを追記

---

## Critical Files（変更するファイル）

### Phase 1: スキル修正（修正が必要な5スキル）

**chezmoi プラグイン**（4スキル）:
1. **plugins/chezmoi/skills/sync/SKILL.md**
   - Referencesセクション（2ファイル参照）をYPMパターンに変更

2. **plugins/chezmoi/skills/setup/SKILL.md**
   - Referencesセクション（6ファイル参照）をYPMパターンに変更

3. **plugins/chezmoi/skills/commit/SKILL.md**
   - Referencesセクション（2ファイル参照）をYPMパターンに変更

4. **plugins/chezmoi/skills/shell-sync-setup/SKILL.md**
   - Referencesセクション（3ファイル参照）をYPMパターンに変更

**code プラグイン**（1スキル）:
5. **plugins/code/skills/review-commit/SKILL.md**
   - Referencesセクション（1ファイル参照）をYPMパターンに変更

### Phase 2: ドキュメント作成

6. **docs/progressive-disclosure.md** - 新規作成
   - Claude Code標準パターンの説明
   - YPMパターンの実装例
   - Markdownリンクが動作しない理由の解説

7. **docs/skill-template.md** - 新規作成
   - 新規スキル作成時のテンプレート
   - Progressive Disclosure使用時のベストプラクティス

8. **CLAUDE.md** - 更新
   - スキル開発ガイドラインセクションにYPMパターンを追記

### 参考実装（変更不要）

**ypm プラグイン**（既に正しい実装）:
- **plugins/ypm/skills/project-bootstrap/SKILL.md**
- **plugins/ypm/skills/git-workflow-setup/SKILL.md**
- **plugins/ypm/skills/project-status-update/SKILL.md**

これらは既に`${CLAUDE_PLUGIN_ROOT}`パターンを使用しており、修正不要です。

---

## Verification（検証方法）

### Phase 1検証

1. **chezmoi/sync テスト**:
   ```bash
   /chezmoi:sync
   ```
   - 期待: ワーキングディレクトリ制限エラーが発生しない
   - 期待: 正常に dotfiles が同期される

2. **chezmoi/setup テスト**:
   ```bash
   /chezmoi:setup
   ```
   - 期待: セットアップウィザードが正常に起動

### Phase 2検証

3. **全スキルの動作確認**:
   - 各プラグインの主要コマンドを実行
   - Referencesファイルへのアクセスが正常に動作するか確認

4. **回帰テスト**:
   - Progressive Disclosureを使用していないスキルに影響がないか確認

---

## リスク管理

| リスク | 対策 |
|--------|------|
| **環境変数が展開されない** | テストで確認、必要に応じて代替方法検討 |
| **他のプラグインへの影響** | Phase 1で小規模テスト後、Phase 2で全体展開 |
| **ユーザー体験の低下** | 変更前後でコマンド動作に差がないことを確認 |

---

## 成功基準

### Phase 1完了時

- [ ] `/chezmoi:sync` が正常に動作する
- [ ] `/chezmoi:setup` が正常に動作する
- [ ] ワーキングディレクトリ制限エラーが発生しない

### Phase 2完了時

- [ ] 全8スキルが統一された参照形式を使用
- [ ] 全スキルの動作確認完了
- [ ] ドキュメント更新完了

---

## 参考資料

- **調査結果**: Explore agent調査（Progressive Disclosure使用状況）
- **エラーログ**: chezmoi/sync ワーキングディレクトリ制限エラー
- **既存実装**: YPM環境変数形式、Chezmoi Markdownリンク形式
