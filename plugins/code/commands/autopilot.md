---
description: auto mode 前提のフルパイプライン orchestrator (sprint → audit → simplify → ship → review → retro)
argument-hint: [plan-file | "description" | Issue N 参照]
---

# /code:autopilot

auto mode 前提のフルパイプライン orchestrator。プラン承認から PR Ready-to-merge までを自動連鎖する。

## 使い方

```
/code:autopilot /abs/path/to/plan.md             # plan file から起動
/code:autopilot "shipping-pr に skip_review..."   # 自然言語 description
/code:autopilot Issue 123 を実装                   # GitHub Issue を自然言語で参照
```

引数は自然言語で判別します（明示 flag は不要）。

## パイプライン

実行フェーズ（`.claude/autopilot.state.json` の `.phase` フィールド）:

```
Prep:  Auto mode 検出 + state 初期化 + ensure-issue (plan.issue が null なら gh issue create)
  ↓
sprint          (code:sprint-impl — 実装、per-module commit)
  ↓
audit           (code:audit-compliance — DDD/TDD/DRY/ISSUE/PROCESS)
  ↓
simplify        (simplify — 3 agents 並列レビュー、critical+important=0 まで iterate)
  ↓
ship            (code:shipping-pr --skip-review — commit/push/PR 作成、simplify 収束後のみ)
  ↓
post-pr-review  (code:pr-review-team — CI 待機 + 4 agents + iterate)
  ↓
retrospective   (code:retrospective — 学習記録、Serena memory 保存)
  ↓
complete        (Ready-to-merge で停止、マージは user 指示待ち)
```

`ensure-issue` は phase ではなく Prep 内の一括処理として実行される。

停止条件: `critical + important = 0` AND `security pass` AND `CI SUCCESS`

## Auto mode 非対応時

`autopilot-detect-auto-mode.sh` で auto mode を検出できなかった場合、refuse して以下を案内:

1. `claude --permission-mode auto` で再起動
2. settings.json に `permissions.defaultMode: "auto"` を追加
3. auto mode 不要なら `/code:dev-cycle` を使用

## 関連

- `/code:plan` — autopilot 強制 directive を注入する plan 作成ラッパー
- `/code:dev-cycle` — auto mode 非対応時の legacy パイプライン
- `/code:shipping-pr` — `--skip-review` フラグで個別起動可能
