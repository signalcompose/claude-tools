---
description: Audit current branch for compliance with DDD, TDD, DRY, ISSUE, PROCESS principles
---

# Compliance Audit

現在のブランチが開発原則（DDD、TDD、DRY、ISSUE、PROCESS）に準拠しているか監査する。

## 使い方

```
/code:audit-compliance                    # 現在のブランチを監査
/code:audit-compliance <branch-or-phase>  # 指定ブランチ/フェーズを監査
```

## 監査原則

| 原則 | チェック内容 |
|------|------------|
| DDD | `docs/specs/` にスペックドキュメントが存在し、実装前にコミットされているか |
| TDD | テストコミットが実装コミットより先か |
| DRY | 意味のあるコード重複がないか |
| ISSUE | 実装前に GitHub Issues が作成されているか |
| PROCESS | コードレビュー・出荷ワークフローが正しく実行されたか |

## 関連スキル

- `/code:dev-cycle` — 全サイクル（監査含む）
- `/code:sprint-impl` — 実装スプリント（監査の前に実行）
- `/code:shipping-pr` — PR作成（監査通過後に実行）
