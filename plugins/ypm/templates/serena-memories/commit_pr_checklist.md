# コミット・PR作成時の必須チェックリスト

## 🚨 絶対に守るべき言語ルール

### コミットメッセージ

- ✅ **タイトル（1行目）**: 必ず英語 (Conventional Commits)
- ✅ **本文（2行目以降）**: 必ず日本語

### PR（Pull Request）

- ✅ **タイトル**: 英語
- ✅ **本文**: 日本語

### ISSUE

- ✅ **タイトル**: 英語
- ✅ **本文**: 日本語

---

## コミット作成時のチェックリスト

### 1. コミットメッセージの確認

```bash
git commit -m "$(cat <<'EOF'
feat(scope): implement your feature  ← 英語

実装内容の詳細説明  ← 日本語
変更理由や背景  ← 日本語

Closes #123
EOF
)"
```

**チェック項目**:
- [ ] タイトル（1行目）が英語になっているか
- [ ] 本文（2行目以降）が日本語になっているか
- [ ] Conventional Commits形式に準拠しているか
- [ ] ISSUE番号を記載しているか（`Closes #123`）

### 2. Conventional Commits形式

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

---

## PR作成時のチェックリスト

### 1. PR作成前の確認

```bash
gh pr create --title "英語タイトル" --body "$(cat <<'EOF'
## 概要
日本語で説明

## 変更内容
- 日本語項目1
- 日本語項目2

## 関連ISSUE
Closes #123
EOF
)"
```

**チェック項目**:
- [ ] PRタイトルが英語になっているか
- [ ] PR本文が日本語になっているか
- [ ] ISSUE番号を記載しているか
- [ ] 正しいブランチからPRを作成しているか
  - feature/* → develop
  - bugfix/* → develop
  - hotfix/* → main
  - develop → main (リリース時のみ)

### 2. PRテンプレート確認

- [ ] 概要セクションが日本語で記載されているか
- [ ] 変更内容が日本語で箇条書きされているか
- [ ] テスト内容が記載されているか
- [ ] チェックリストがすべて確認済みか

---

## 🚨 違反検知

以下の状況を検知したら**即座に停止**:

### 1. コミット本文が英語

**❌ 間違った例**:
```bash
feat(tickets): implement issue search functionality

- Add search_issues tool  ← 英語はダメ！
- Support multiple filter parameters  ← 英語はダメ！
```

**✅ 正しい例**:
```bash
feat(tickets): implement issue search functionality

チケット検索機能を実装  ← 日本語
- search_issuesツールを追加  ← 日本語
- 複数のフィルターパラメータに対応  ← 日本語
```

**対応**: 即座停止、「コミット本文は必ず日本語で記述してください」と報告

### 2. PRタイトルが日本語

**❌ 間違った例**:
```
チケット検索機能の実装  ← 日本語はダメ！
```

**✅ 正しい例**:
```
feat(tickets): implement issue search functionality  ← 英語
```

**対応**: 即座停止、「PRタイトルは必ず英語で記述してください」と報告

### 3. PR本文が英語

**❌ 間違った例**:
```markdown
## Summary
This PR implements issue search functionality...  ← 英語はダメ！
```

**✅ 正しい例**:
```markdown
## 概要
チケット検索機能を実装します...  ← 日本語
```

**対応**: 即座停止、「PR本文は必ず日本語で記述してください」と報告

---

## よくある質問

### Q: なぜタイトルは英語、本文は日本語？

A:
- **タイトル英語**: Conventional Commitsという国際標準に準拠
- **本文日本語**: チーム内コミュニケーションを円滑にするため

### Q: コード内のコメントは？

A:
- **コメント**: 日本語推奨（チーム内の理解を優先）
- **変数名・関数名**: 英語（コーディング規約）

### Q: 英語が苦手なのですが...

A:
- タイトルは定型文（feat, fix等）+ 簡単な英語でOK
- 本文は日本語で詳しく説明すれば問題ありません
- AIに英訳を依頼するのもOK

---

## 例：完璧なコミット・PRの作成

### コミット例

```bash
git commit -m "$(cat <<'EOF'
feat(auth): implement JWT authentication

JWT認証機能を実装

## 変更内容
- JWT トークンの生成・検証ロジックを追加
- ログインエンドポイントを実装
- 認証ミドルウェアを作成

## テスト
- 単体テスト追加（カバレッジ90%）
- 統合テスト実施済み

Closes #123
EOF
)"
```

### PR例

```bash
gh pr create \
  --title "feat(auth): implement JWT authentication" \
  --body "$(cat <<'EOF'
## 概要

JWT認証機能を実装しました。

## 変更内容

- JWT トークンの生成・検証ロジックを追加
- ログインエンドポイントを実装
- 認証ミドルウェアを作成

## テスト

- [ ] 単体テスト追加（カバレッジ90%）
- [ ] 統合テスト実施済み
- [ ] ローカル環境で動作確認

## 関連ISSUE

Closes #123
EOF
)"
```

---

**このチェックリストを守ることで、コミット履歴が統一され、
チーム内のコミュニケーションが円滑になります。**
