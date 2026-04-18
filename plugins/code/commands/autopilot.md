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

```
Stage 0: Auto mode 検出 + State 初期化
Stage 1: sprint-impl        (実装、per-module commit)
Stage 2: audit-compliance   (DDD/TDD/DRY/ISSUE/PROCESS)
Stage 3: simplify           (built-in /simplify、3 agents 並列レビュー)
Stage 3.5: ensure-issue     (plan.issue が null なら gh issue create)
Stage 4: shipping-pr        (--skip-review で commit + push + PR 作成)
Stage 5: pr-review-team     (CI 待機 + 4 agents + iterate)
Stage 6: retrospective      (学習記録、Serena memory 保存)
Stage 7: Ready-to-merge で停止 (マージは user 指示待ち)
```

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
