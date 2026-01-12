# Git Flow チェックリスト

## 🚨 絶対に守るべき原則

### Git Flowの一方向性

```
develop > feature > PR > develop > PR > main
              ↓                      ↓
          絶対に逆流させない
```

**最重要ルール**: main → develop への逆流は**絶対禁止**

---

## 新機能開発時のチェックリスト

### STEP 1: ISSUE作成
- [ ] GitHubでISSUEを作成
- [ ] ISSUE番号を確認（例: #123）

### STEP 2: ブランチ確認
- [ ] 現在のブランチを確認: `git branch --show-current`
- [ ] developブランチにいることを確認
- [ ] developブランチが最新: `git pull origin develop`

### STEP 3: featureブランチ作成
- [ ] ブランチ作成: `git checkout -b feature/<issue番号>-<機能名>`
- [ ] ISSUE番号がブランチ名に含まれているか確認

### STEP 4: 実装・コミット
- [ ] コミットメッセージ: タイトル英語、本文日本語
- [ ] Conventional Commits準拠

### STEP 5: PR作成
- [ ] PR作成: `feature/<...>` → `develop`
- [ ] PRタイトル: 英語
- [ ] PR本文: 日本語
- [ ] ISSUE番号を記載: `Closes #123`

### STEP 6: マージ
- [ ] **マージコミット**を使用（Squash禁止）
- [ ] マージ後、featureブランチを削除

---

## リリース時のチェックリスト

### STEP 1: ISSUE作成
- [ ] GitHubでリリースISSUE作成（例: `Release v1.0.1`）
- [ ] ISSUE番号を確認

### STEP 2: developブランチで最終調整
- [ ] developブランチに切り替え
- [ ] バージョン番号を更新（必要に応じて）
- [ ] CHANGELOG.mdを更新（必要に応じて）
- [ ] 最終調整をコミット

### STEP 3: PR作成（develop → main）
- [ ] PR作成: `develop` → `main`  ← **直接PRでOK**
- [ ] PRタイトル: 英語（例: `release: v1.0.1`）
- [ ] PR本文: 日本語（リリースISSUEの内容）
- [ ] ISSUE番号を記載

### STEP 4: マージ
- [ ] **マージコミット**を使用（Squash禁止）
- [ ] マージ完了を確認

### STEP 5: タグ付け
- [ ] タグ作成: `git tag v1.0.1`
- [ ] タグをプッシュ: `git push origin v1.0.1`

### STEP 6: リリース後
- [ ] GitHubでリリースノート作成
- [ ] リリースISSUEをクローズ

---

## 🚨 違反検知チェック

以下の状況を検知したら**即座に停止**:

### 1. main → develop への逆流
- ❌ `main` から `develop` へのPR
- ❌ `main` ブランチの変更を `develop` にマージ

**対応**: 即座停止、「逆流は絶対禁止です」と報告

### 2. main・developブランチへの直接コミット
- ❌ `main` ブランチで直接コミット
- ❌ `develop` ブランチで直接コミット

**対応**: 即座停止、「featureブランチで作業してください」と報告

### 3. Squashマージ
- ❌ PRマージ時に「Squash and merge」を選択

**対応**: 即座停止、「必ずマージコミットを使用してください」と報告

### 4. ISSUE番号のないブランチ名
- ❌ `feature/new-feature`（ISSUE番号なし）
- ✅ `feature/123-new-feature`（ISSUE番号あり）

**対応**: ブランチ名を修正するよう報告

---

## ブランチ戦略図

```
main (本番環境)
  ← develop (開発環境)
       ← feature/123-new-feature
       ← bugfix/456-fix-bug
       ← hotfix/789-critical-fix (mainからも切れる)
```

---

## よくある質問

### Q: なぜmain → developの逆流は禁止？

A: developが常に最新の開発状態を保つため。
mainからdevelopに逆流すると、開発中の変更と衝突し、Git Flowが破綻します。

### Q: なぜSquashマージは禁止？

A: Squashは履歴を1つにまとめるため、mainとdevelopで異なる履歴になり、
次回リリース時に全コミットが重複してコンフリクトします。

### Q: developからmainへの直接PRはOK？

A: **リリース時のみOK**です。
開発中の変更はfeature/bugfix/hotfixブランチ経由でdevelopにマージし、
リリース時にdevelopからmainへ直接PRを作成します。

---

**このチェックリストを守ることで、Git Flowの一方向性が保たれ、
履歴が分岐せず、クリーンな開発フローが維持できます。**
