# リサーチ: Claude Code スラッシュコマンドの引数渡し

## リサーチ実施日
2025-10-20

## リサーチ目的
CVIのスラッシュコマンド（`/cvi on`など）が引数を正しくスクリプトに渡せない問題を調査し、Claude Codeのスラッシュコマンドにおける引数の扱い方を明確にする。

## リサーチ方法
- Gemini CLI による Web 検索
- 検索クエリ: "Claude Code slash commands best practices arguments passing"

## 調査結果サマリー

Claude Codeのスラッシュコマンドは、**`$ARGUMENTS`変数**を使用して引数を受け取る仕様である。

## 詳細調査結果

### 引数の受け渡し方法

Claude Codeのスラッシュコマンドには**2つの引数受け渡し方法**がある：

1. **`$ARGUMENTS`** - コマンド後の全テキストをキャプチャ
2. **`$1`, `$2`, ...** - 位置引数（シェルスクリプトと同様）

### 実装例

**スラッシュコマンド定義ファイル** (`.claude/commands/test.md`):
```markdown
This is a test with the following arguments: $ARGUMENTS
First argument: $1
Second argument: $2
```

**実行**:
```
/test foo bar
```

**展開結果**:
```
This is a test with the following arguments: foo bar
First argument: foo
Second argument: bar
```

### ベストプラクティス

1. **引数を使用してコマンドを柔軟にする**
   - `$ARGUMENTS`を使って全引数を受け取る
   - `$1`, `$2`で個別の引数を参照

2. **サブディレクトリでコマンドを整理**
   - `.claude/commands/git/commit.md` → `/git:commit`

3. **YAML frontmatterで説明を追加**
   - `/help`コマンドで表示される説明を追加できる

4. **シェルコマンドの実行**
   - `!`プレフィックスでシェルコマンドを実行可能

## CVIへの適用

### 修正前のコマンド定義

```markdown
## 使い方

### 音声通知を有効化

```bash
~/.claude/scripts/cvi on
```
```

**問題点**: 引数が固定値として記述されており、実行時の引数が渡らない

### 修正後のコマンド定義

```markdown
---
description: Control CVI voice notification (on/off/status)
---

# CVI Main Control

以下のBashコマンドを**即座に実行**してください（確認ダイアログなし）:

```bash
~/.claude/scripts/cvi $ARGUMENTS
```

## 引数

- `on` - 音声通知を有効化
- `off` - 音声通知を無効化
- `status` - 現在のステータスを表示
```

**改善点**:
1. `$ARGUMENTS`を使用して引数を動的に渡す
2. YAML frontmatterで説明を追加
3. 明確な実行指示を記述
4. 利用可能な引数を明記

## テスト結果

修正後、すべてのCVIコマンドが正常に動作：

- ✅ `/cvi on` → スクリプトに`on`が渡される
- ✅ `/cvi off` → スクリプトに`off`が渡される
- ✅ `/cvi status` → スクリプトに`status`が渡される
- ✅ `/cvi-speed 220` → スクリプトに`220`が渡される

## 結論

Claude Codeのスラッシュコマンドで引数を渡すには、`$ARGUMENTS`変数を使用する必要がある。この変数を使用することで、ユーザーがコマンド実行時に入力した引数が動的にスクリプトに渡される。

### 推奨される実装パターン

```markdown
---
description: Brief command description
---

# Command Name

Brief explanation of what this command does.

Execute the following Bash command immediately:

```bash
~/.claude/scripts/script-name $ARGUMENTS
```

## Arguments

- `arg1` - Description
- `arg2` - Description

## Usage Examples

- `/command arg1` - Example description
- `/command arg2` - Example description
```

## 参考情報

- Gemini検索結果より抽出
- Claude Code公式ドキュメント: スラッシュコマンド機能
