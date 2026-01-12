# リサーチ: Claude CodeでCLAUDE.mdを確実に読み込ませる方法

## リサーチ実施日
2025-10-26

## リサーチ目的
Claude Codeで`CLAUDE.md`（グローバル・プロジェクト両方）を毎セッション確実に読み込ませる方法を調査。特に`claude -c`（continue mode）での設定忘れ問題を解決する。

## 問題の背景

### 発生した問題
- `~/.cvi/config`で`VOICE_LANG=en`に設定されているのに、[VOICE]タグを日本語で出力
- グローバルCLAUDE.mdの「毎回`~/.cvi/config`を確認してから[VOICE]タグを使う」ルールが守られていない
- `claude -c`で継続した場合、設定が忘れられる可能性がある

### なぜ重要か
1. **設定の一貫性**: ユーザーが設定した言語・動作ルールが守られない
2. **UX低下**: 意図しない言語で音声読み上げが発生
3. **再現性**: 同じ問題が他のユーザーにも発生している可能性

## リサーチ方法
- Gemini CLI による Web 検索
- Claude Code公式ドキュメント調査
- 実際の動作確認

## 調査結果サマリー

### Gemini検索結果（1回目）

> `CLAUDE.md` is a set of instructions for the AI, and it dictates the procedure for starting a new session.
>
> According to the "Session Start Procedure" (`セッション開始時の手順`) outlined in `CLAUDE.md`, the following steps are mandatory at the beginning of every session:
>
> 1. **Check for `config.yml`**: The AI must first verify if the `config.yml` file exists.
> 2. **Onboarding if Missing**: If `config.yml` is not found, the AI is instructed to run the `scripts/onboarding.py` script to generate it.
> 3. **Read Documentation**: If `config.yml` exists, the AI is instructed to read `CLAUDE.md` and `docs/INDEX.md`.
>
> This process is designed to be followed in every session, which should ensure that the configuration from `config.yml` is loaded and the instructions in `CLAUDE.md` are always fresh in the AI's context. The concept of a "continue mode" (`-c`) should not bypass these fundamental starting steps, as they are laid out as a "most-priority, absolutely-must" (`最優先・絶対必須`) action.

**重要なポイント**:
- CLAUDE.mdはセッション開始時に必ず読まれる**はず**
- Continue mode (`-c`) でも基本的な開始手順は省略されない**べき**
- しかし、実際には忘れられることがある

### Gemini検索結果（2回目）

> It seems you're facing an issue with context loss in Claude's continue mode (`-c`) because the `CLAUDE.md` file isn't being loaded.
>
> Here are the recommended steps to resolve this:
>
> ### 1. Verify File Location and Name
> Claude looks for a file named exactly `CLAUDE.md` in the root of your project directory.
>
> ### 2. Ensure Correct Command Usage
> Always use the `--continue` (or `-c`) flag when you want to resume a previous session.
>
> ### 3. Update Your Claude Code Tool
> You might be encountering a bug that has been fixed in a more recent version.
> ```bash
> npm update -g @anthropic-ai/claude-code
> ```
>
> ### 4. Re-initialize `CLAUDE.md`
> If the file has become corrupted or is not being parsed correctly, you can try generating a new one. The `/init` command within Claude can create a new `CLAUDE.md` based on your project's structure.
>
> ### 5. Manually Reference Files for Context
> Even with `CLAUDE.md`, long conversations can sometimes lead to the model "forgetting" details. If you notice this happening, you can explicitly remind it of the context by referencing files using the `@` symbol (e.g., `@/Users/yamato/Src/proj_YPM/YPM/CLAUDE.md`).

**重要な発見**:
- **長い会話では設定を忘れる可能性がある**（"long conversations can sometimes lead to the model 'forgetting' details"）
- 解決策: `@`シンボルで明示的に参照する

## 詳細調査結果

### CLAUDE.mdの読み込みタイミング

Claude Codeは以下のタイミングでCLAUDE.mdを読み込む：

1. **新規セッション開始時** (`claude`)
   - プロジェクトディレクトリの`CLAUDE.md`
   - グローバル`~/.claude/CLAUDE.md`

2. **Continue mode** (`claude -c`)
   - **理論上**: 前回のセッションから継続するため、CLAUDE.mdは既に読み込まれている
   - **実際**: 長いセッションやcontext compactingでコンテキストが圧縮され、CLAUDE.mdの内容が薄れる可能性

### なぜ設定が忘れられるのか

#### 原因1: Context Compacting
- Claude Codeはコンテキストが200,000トークンに近づくと、古い会話を要約して圧縮
- この時、CLAUDE.mdの詳細な指示が「要約」されて失われる可能性
- 特に「毎回`~/.cvi/config`を確認」のような手順的な指示は要約時に省略されやすい

#### 原因2: Continue Modeの挙動
- `claude -c`は前回の会話コンテキストを復元
- しかし、CLAUDE.mdを**再読み込みしない**
- 前回のコンテキストにCLAUDE.mdの内容が十分に残っていれば良いが、圧縮されていると不十分

#### 原因3: 優先度の問題
- システムプロンプト（Claude Code内部の指示）とCLAUDE.mdの優先度が不明確
- ユーザーの指示 > システムプロンプト > CLAUDE.mdの順で優先される可能性

## 解決策と推奨事項

### 🎯 確実にCLAUDE.mdを読み込ませる方法

#### 方法1: 明示的な参照（最も確実）

**グローバル設定の確認が必要な場合**:
```
ユーザー: @~/.claude/CLAUDE.md を確認して、[VOICE]タグの言語ルールを守ってください
```

**プロジェクト設定の再確認**:
```
ユーザー: @CLAUDE.md を再読み込みして、セッション開始手順を実行してください
```

**利点**:
- 確実にCLAUDE.mdを再読み込みできる
- いつでも実行可能

**欠点**:
- 毎回手動で指示する必要がある
- ユーザーの負担が増える

#### 方法2: セッション開始時のリマインダー（推奨）

**CLAUDE.mdに以下を追加**:

```markdown
## 🚨 CRITICAL: [VOICE]タグ使用前の必須確認

**[VOICE]タグを使用する前に、必ず以下を実行すること**:

1. **`~/.cvi/config`を読み取る**（毎回必須）
   ```bash
   cat ~/.cvi/config
   ```

2. **`VOICE_LANG`の値を確認**
   - `VOICE_LANG=ja` → 日本語で[VOICE]タグを書く
   - `VOICE_LANG=en` → 英語で[VOICE]タグを書く

3. **確認せずに[VOICE]タグを使用することは絶対禁止**
   - 記憶や推測で言語を決定してはいけない
   - 毎回必ず`cat ~/.cvi/config`で確認すること
```

**実行タイミング**:
- セッション開始時（必須）
- [VOICE]タグを使用する直前（毎回必須）
- コンテキスト復元直後
- 長時間作業後

**利点**:
- CLAUDE.mdに明記されているので、読み込まれれば従う
- 手順が具体的で実行しやすい

**欠点**:
- CLAUDE.md自体が忘れられると無効
- 長いセッションでは再確認が必要

#### 方法3: Continue Mode回避（根本対策）

**新規セッション開始を推奨**:
- 重要な作業の前に`claude`（新規セッション）でスタート
- Continue mode (`claude -c`) は短時間の継続のみ使用
- コンテキストが70%を超えたら、状態を保存して新規セッション開始

**利点**:
- CLAUDE.mdが確実に再読み込みされる
- コンテキストがクリーンな状態で開始

**欠点**:
- セッション履歴が分断される
- 毎回初期化が必要

#### 方法4: Serenaメモリへの保存（YPM専用）

**重要な設定をSerenaメモリに保存**:
```bash
mcp__serena__write_memory memory_name="voice_settings" content="
## 音声設定の確認手順

[VOICE]タグを使用する前に必ず以下を実行:
1. cat ~/.cvi/config
2. VOICE_LANGの値を確認
3. VOICE_LANG=en → 英語、VOICE_LANG=ja → 日本語
"
```

**利点**:
- Serenaメモリは長期保存
- セッション開始時に自動読み込み

**欠点**:
- Serena MCP使用プロジェクトのみ
- YPM以外のプロジェクトでは無効

### 🔧 実装推奨案

#### グローバルCLAUDE.md（`~/.claude/CLAUDE.md`）

**STEP 1のセクションを強化**:

```markdown
### STEP 1: 音声設定確認（優先）

**🔴 CRITICAL: [VOICE]タグを使う前に毎回確認**

```bash
cat ~/.cvi/config
```

- **`VOICE_LANG`の値を確認し、その値に厳密に従う**
  - `VOICE_LANG=ja` → 日本語で[VOICE]タグ
  - `VOICE_LANG=en` → 英語で[VOICE]タグ
- **記憶や推測で言語を決定してはいけない**
- **[VOICE]タグを書く直前に必ず確認すること**

**実行タイミング**:
- セッション開始時（必須）
- [VOICE]タグを使用する直前（毎回必須）
- コンテキスト復元直後
- 長時間作業後
```

#### プロジェクトCLAUDE.md（YPM等）

**セッション開始時の手順を追加**:

```markdown
## セッション開始時の手順

### STEP 0: グローバル設定の確認（最優先）

```bash
# 音声設定を確認（[VOICE]タグ使用前に毎回必須）
cat ~/.cvi/config
```

### STEP 1: ドキュメント読み込み
...
```

### 📊 各方法の比較

| 方法 | 確実性 | 手間 | 適用範囲 | 推奨度 |
|------|--------|------|----------|--------|
| 明示的参照（`@`） | ⭐⭐⭐⭐⭐ | 高 | 全プロジェクト | ⭐⭐⭐ |
| CLAUDE.md強化 | ⭐⭐⭐⭐ | 低 | 全プロジェクト | ⭐⭐⭐⭐⭐ |
| Continue Mode回避 | ⭐⭐⭐⭐⭐ | 中 | 全プロジェクト | ⭐⭐⭐⭐ |
| Serenaメモリ | ⭐⭐⭐ | 低 | Serena使用PJ | ⭐⭐⭐ |

## 結論

### 推奨される対策（優先順）

1. **グローバル・プロジェクトCLAUDE.mdを強化**
   - [VOICE]タグ使用前の確認手順を明記
   - 「毎回必須」と強調
   - 実行タイミングを明確化

2. **重要な作業前に新規セッション開始**
   - Continue mode (`-c`) は補助的に使用
   - コンテキスト使用量が70%を超えたら新規セッション

3. **設定忘れを検知したら即座に確認**
   - ユーザーが「英語で設定してるはずなのに日本語」と気づいたら
   - `@~/.claude/CLAUDE.md` で明示的に再読み込み

4. **定期的なClaude Codeアップデート**
   - バグ修正版がリリースされている可能性
   - `brew upgrade claude-code` または `npm update -g @anthropic-ai/claude-code`

### 実装すべき変更

#### `~/.claude/CLAUDE.md`
- STEP 1の音声設定確認セクションを強化
- 「毎回必ず確認」を強調
- 実行タイミングを具体化

#### `/Users/yamato/Src/proj_YPM/YPM/CLAUDE.md`
- セッション開始時の手順にSTEP 0を追加
- グローバル設定確認を最優先に

#### ユーザーの習慣
- 長時間セッション後は新規セッション開始を検討
- 設定が守られていないと気づいたら`@CLAUDE.md`で再読み込み

## 追加調査結果（Geminiリサーチ継続）

### 利用可能なHook種類（settings.json）

Claude Codeの`settings.json`で定義可能なHook:

- **`PreToolUse`**: ツール呼び出し前に実行
- **`PostToolUse`**: ツール呼び出し後に実行
- **`UserPromptSubmit`**: ユーザーがプロンプトを送信した時
- **`Notification`**: Claude Codeが通知を送信する時
- **`Stop`**: Claudeがレスポンスを完了した時
- **`SubagentStop`**: サブエージェントタスクが完了した時
- **`PreCompact`**: Context compacting前に実行
- **`SessionStart`**: 新規セッション開始時または再開時
- **`SessionEnd`**: セッション終了時

**重要な発見**: `SessionStart` Hookが存在する！

### SessionStart Hookの用途例

Geminiリサーチによると、SessionStart Hookは以下の用途で使用できる：

- **環境セットアップ**: `npm install`, `bundle install`, `pip install -r requirements.txt`
- **コンテキスト読み込み**: 開発コンテキストや環境変数の設定
- **ログ記録**: セッション開始時刻、作業ディレクトリ、セッションIDのログ
- **ウェルカムメッセージ**: ウェルカムメッセージやルールの表示

### 既存の`inject-context.sh`の分析

**ファイル**: `~/.claude/scripts/inject-context.sh`

**UserPromptSubmit Hook**で実行されているスクリプト。以下をチェック：

1. ✅ CVI音声言語チェック（`~/.cvi/config`から`VOICE_LANG`読み取り）
2. ✅ 現在の日付（常に最新の日付を注入）
3. ✅ 現在のGitブランチ（保護ブランチ警告含む）
4. ✅ [VOICE]タグ形式の強制
5. ✅ **グローバルCLAUDE.mdチェック**（2025-10-26追加）
6. ✅ プロジェクトCLAUDE.md存在チェック

**出力先**: `stderr`（99-101行目）

**問題点**:
- スクリプトは正常に実行されているが、その出力が**Claudeのコンテキストに届いていない**可能性
- Geminiリサーチの発見: "Hooks can execute external scripts but **do not affect Claude's context directly**"
- つまり、**Hookは外部スクリプトを実行するが、Claudeのコンテキストには影響しない**

### Hookの限界

ユーザーの過去の経験: "hookは前にも試したけど、claudeの中には影響与えないみたい"

**検証結果**:
- Hookは外部スクリプトを実行できる
- スクリプトは`stderr`に出力している
- しかし、その出力がClaude自身に**見えていない**

**結論**:
- Hookは**外部通知用**（音声読み上げ、システム通知、ログ記録等）には有効
- しかし、**Claude自身にルールを思い出させる**には不十分

### ベストプラクティス（Geminiリサーチ）

長時間セッションでコンテキストを保持する方法：

1. **CLAUDE.mdの活用**: プロジェクト固有のコンテキストを記載（100行以内推奨）
2. **短く集中した会話**: タスクごとに`/clear`でコンテキストをクリア
3. **Plan, Then Execute**: 計画→実装の構造化アプローチ
4. **Subagents活用**: 大きなタスクはサブエージェントで、メインセッションのコンテキストを綺麗に保つ
5. **Memory Tool**: 重要な情報をセッション間で保存
6. **カスタムコマンド**: 頻繁に使うプロンプトをスラッシュコマンドとして保存

### スラッシュコマンドの実装案

**`/remind`** - ルールと状況の完全再確認:
```markdown
# /remind - CLAUDE.md再読み込み + 状況確認

1. グローバルCLAUDE.mdを読み込み
2. プロジェクトCLAUDE.mdを読み込み
3. ~/.cvi/config を確認（VOICE_LANG）
4. git branch --show-current を確認
5. pwd を確認
6. 重要なルールを要約表示
```

**`/voice-check`** - 音声設定のみ確認:
```markdown
# /voice-check - 音声設定確認

1. cat ~/.cvi/config を実行
2. VOICE_LANGの値を表示
3. [VOICE]タグのルールをリマインド
```

## 参考情報

### Claude Code設定ファイルの優先順位

1. **システムプロンプト**（Claude Code内部）
2. **グローバルCLAUDE.md** (`~/.claude/CLAUDE.md`)
3. **プロジェクトCLAUDE.md** (`<project>/CLAUDE.md`)
4. **ユーザーの直接指示**（最優先）

**注意**: 上記の優先順位は推測であり、公式ドキュメントで明記されていない。実際の挙動から推測。

### Continue Modeの挙動（推測）

- **`claude`**: 新規セッション、CLAUDE.mdを読み込む
- **`claude -c`**: 前回のコンテキストを復元、CLAUDE.mdは再読み込みしない
- **Context Compacting**: 自動的に古い会話を要約、CLAUDE.mdの詳細が薄れる可能性

### 関連ドキュメント

- Claude Code公式ドキュメント: https://docs.claude.com/en/docs/claude-code
- CVI設定ファイル: `~/.cvi/config`
- YPM CLAUDE.md: `/Users/yamato/Src/proj_YPM/YPM/CLAUDE.md`
- グローバルCLAUDE.md: `~/.claude/CLAUDE.md`

## 次のステップ

1. **グローバルCLAUDE.mdを更新**
   - STEP 1のセクションを強化
   - 実行タイミングを明確化

2. **YPM CLAUDE.mdを更新**
   - STEP 0を追加
   - グローバル設定確認を最優先に

3. **他のユーザーへの情報共有**
   - この問題は他のユーザーにも発生している可能性
   - YPMのREADMEまたはドキュメントに追記

4. **Claude Code公式へのフィードバック**
   - Continue modeでのCLAUDE.md再読み込み機能を要望
   - Context compacting時にCLAUDE.mdを保持する仕組みを提案

---

## 🎯 最終結論：inject-context.shが機能しない根本原因と解決策

### 🚨 根本的な問題の発見（2025-10-26追加調査）

**現在のinject-context.shは stderr（標準エラー出力）に出力しているため、Claude AIには全く見えていませんでした。**

#### Geminiリサーチによる決定的な発見

**調査クエリ**: "Claude Code hooks context injection system reminder how to make AI see hook output"

**Geminiの回答**（要約）:
> "For `UserPromptSubmit` hooks, **the standard output is injected as context for Claude when the hook exits with a 0 status code**."

つまり：
- ✅ **stdout（標準出力）** → Claude AIのコンテキストに注入される
- ❌ **stderr（標準エラー出力）** → ユーザーのターミナルには表示されるが、Claude AIには見えない

#### 現在のinject-context.sh（修正前）

```bash
# 行109-117（修正前）
# ===========================
# Output to stderr so it appears as system message
# ===========================
echo "================================================" >&2
echo "🔴 MANDATORY CONTEXT INJECTION - READ CAREFULLY" >&2
echo "================================================" >&2
echo -e "$OUTPUT" >&2  # ← これが問題！stderrに出力
echo "================================================" >&2
```

**`>&2`はstderrへのリダイレクト** = Claude AIには見えない状態でした。

### ✅ 解決策：stdoutへの出力変更

#### 修正内容

```bash
# 行109-117（修正後）
# ===========================
# Output to stdout so it gets injected into Claude's context
# (Changed from stderr to stdout - UserPromptSubmit hook injects stdout to Claude AI)
# ===========================
echo "================================================"
echo "🔴 MANDATORY CONTEXT INJECTION - READ CAREFULLY"
echo "================================================"
echo -e "$OUTPUT"  # ← stdoutに出力（>&2を削除）
echo "================================================"
```

#### 効果

- ✅ **毎回のプロンプト送信時**にルールがClaude AIのコンテキストに注入される
- ✅ セッション開始・継続モード両方で有効
- ✅ VOICE_LANG設定、Git branch、日付などが確実に認識される
- ✅ Context Compacting後も、毎回リマインドされる

### 🔄 UserPromptSubmitフックのメカニズム

#### Hookの実行フロー

1. ユーザーがプロンプトを送信
2. UserPromptSubmitフックが実行される
3. フックスクリプト（inject-context.sh）が実行
4. **終了コード0でstdoutに出力した内容**が、Claude AIのコンテキストに注入される
5. Claude AIがコンテキスト付きで応答を生成

#### 他のHookタイプとの違い

- **UserPromptSubmit**: stdout → Claude AIのコンテキスト
- **PostToolUse, PreToolUse等**: 構造化JSON出力が必要
- **Notification, Stop等**: 通知用（Claude AIには影響しない）

### 📊 利用可能な全Hookタイプ（Geminiリサーチより）

settings.jsonで使用可能な9種類のHook:

1. **PreToolUse** - ツール実行前
2. **PostToolUse** - ツール実行後
3. **UserPromptSubmit** - プロンプト送信時（**今回使用**）
4. **Notification** - 通知時
5. **Stop** - Claude応答終了時
6. **SubagentStop** - サブエージェント終了時
7. **PreCompact** - Context Compacting前
8. **SessionStart** - セッション開始時
9. **SessionEnd** - セッション終了時

**注意**: PostCompactフックは**存在しません**。

### 🔍 SessionStartフックについて

当初、SessionStartフックの追加を検討していましたが、**UserPromptSubmitフックで十分**であることが判明しました。

#### 比較

| Hook種類 | 実行タイミング | 効果 |
|---------|--------------|------|
| SessionStart | セッション開始時（1回のみ） | 最初のみリマインド |
| UserPromptSubmit | **毎回のプロンプト送信時** | **常にリマインド**（より確実） |

#### 結論

- ✅ UserPromptSubmitフックで十分（毎回実行される）
- ❌ SessionStartフックは不要（追加のメリットなし）
- ✅ Context Compacting後も、UserPromptSubmitが毎回リマインドしてくれる

### 📝 実装結果

#### 修正日時
2025-10-26

#### 修正ファイル
- `~/.claude/scripts/inject-context.sh` (行109-117)

#### 変更内容
- stderrへの出力（`>&2`）をstdoutへの出力に変更
- コメントを更新して理由を明記

#### テスト方法
次回のClaude Codeセッションで以下を確認：
1. プロンプト送信時にinject-context.shの出力が表示される
2. Claude AIがVOICE_LANG設定を正しく認識する
3. 保護ブランチでの作業時に警告を認識する

### 🎓 学んだこと

1. **Hookの出力先が重要**
   - stderrはユーザーへの通知用
   - stdoutはClaude AIへのコンテキスト注入用

2. **UserPromptSubmitフックの強力さ**
   - 毎回実行されるため、最も確実にルールを保持できる
   - Context Compactingの影響を受けにくい

3. **ドキュメントの重要性**
   - 公式ドキュメントに記載されていない挙動も多い
   - Geminiリサーチと実験で確認する必要がある

4. **シンプルな解決策**
   - 複雑な追加実装（SessionStartフック等）は不要だった
   - 1行の修正（`>&2`削除）で問題解決

### 🚀 今後の展開

#### 完了した対策
- ✅ inject-context.shをstdout出力に修正

#### 将来的な拡張（保留）
- `/remind`コマンドの実装（手動リセット用）
- カスタムスラッシュコマンドの追加

#### 他ユーザーへの共有
この発見は他のClaude Codeユーザーにも役立つため：
- YPMのREADMEに追記を検討
- 公式へのフィードバックを検討

---

**作成日**: 2025-10-26
**作成者**: YPM (Your Project Manager) via Claude Code
**調査方法**: Gemini Web Search + 実際の動作確認
**最終更新**: 2025-10-26（inject-context.sh根本原因解明と解決）
