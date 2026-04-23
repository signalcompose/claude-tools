---
description: Pre-merge checklist reminder (surfaces items to consider; does not verify)
---

# /code:checkup

merge 前に確認したい項目を surface する **reminder** skill。**done / not done は判定しない**。user が各項目を見て判断します。

Invoke the `checkup` skill via the Skill tool. The skill reads `${CLAUDE_PLUGIN_ROOT}/skills/checkup/SKILL.md` for its hardcoded core checklist and additionally scans `CLAUDE.md` (user global + project-local) for any project-specific pre-merge items to surface.

## Core checklist (always shown)

- simplify
- pr-review-team
- secret scan (trufflehog)
- .gitignore security patterns
- tests
- docs

## Use it like

```
/code:checkup
```

そのまま叩くだけ。引数なし。

## 関連

- `/code:pr-review-team` — team review（checkup が「やった？」と surface する対象の一つ）
- `/code:trufflehog-scan` — secret scan（checkup が surface する対象の一つ）
