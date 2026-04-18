---
description: built-in /plan の薄いラッパー。autopilot 強制 directive を注入して pipeline 起動を保証
argument-hint: [description or issue reference]
---

# /code:plan

`/code:plan` は built-in `/plan` mode の薄いラッパーで、plan file の先頭に **autopilot 強制 directive** を注入します。この directive により、ExitPlanMode で承認された plan は Claude が自動で `/code:autopilot` 経由で実装するようになります。

## 使い方

```
/code:plan                                 # 会話履歴から synthesis
/code:plan "shipping-pr に skip_review..."  # 自然言語の description から
/code:plan Issue 195 のプラン書いて          # GitHub Issue から synthesis
/code:plan 今までの内容でプランを作って       # 会話履歴から synthesis
```

引数の判別は Claude が自然言語で解釈します（明示的な flag は不要）。

## built-in `/plan` との違い

| 項目 | built-in `/plan` | `/code:plan` |
|------|----------------|-------------|
| plan file 作成 | ✅ | ✅ |
| ExitPlanMode 承認 | ✅ | ✅ |
| Explore 連携 | ✅ | ✅ |
| **autopilot 強制 directive** | ❌ | ✅（決定的な差）|
| 承認後の挙動 | Claude が直接実装 | Claude が `/code:autopilot` を自動起動 → pipeline 実行 |

## 動作フロー

1. built-in plan mode に入る（`EnterPlanMode` 相当）
2. 引数から意図を解釈（description / Issue 参照 / 会話履歴 / 無引数）
3. Explore + synthesis を経て plan file を作成
4. **plan file 先頭に autopilot directive を注入**:
   ```
   🔴 MANDATORY: このプランは auto mode で `/code:autopilot` により実装すること。
   手動実装禁止。起動コマンド: `/code:autopilot <plan-file>`
   ```
5. `ExitPlanMode` で user approval
6. 承認後、directive により Claude が自動で `/code:autopilot <plan-file>` を起動

## いつ使うべきか

- autopilot pipeline（sprint → audit → simplify → ship → review → retro）を通したい時
- PR-ready までの品質ゲートを自動化したい時
- 会話で議論した内容を pipeline に流し込みたい時

## 使うべきでないケース

- autopilot pipeline 不要な単発修正 → built-in `/plan` を使う
- 既に plan file がある → 直接 `/code:autopilot <plan-file>` を呼ぶ

## 関連

- `/code:autopilot` — plan directive が起動する pipeline orchestrator
- `/plan` (built-in) — autopilot を通さない汎用 plan mode
