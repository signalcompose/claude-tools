# Autopilot Directive (canonical text)

This is the canonical directive text that `/code:plan` injects at the top of every plan file it generates. Embed exactly as written.

---

```markdown
🔴 **MANDATORY**: このプランは auto mode で `/code:autopilot` により実装すること。手動実装は禁止。
起動コマンド: `/code:autopilot <plan-file-absolute-path>`

---
```

## Frontmatter (immediately below the directive)

```yaml
---
created: <ISO8601 timestamp, e.g. 2026-04-18T12:34:56Z>
autopilot: true
status: draft
estimated_size: small|medium|large
issue: <number>|null
---
```

## Field semantics

| Field | Purpose |
|-------|---------|
| `created` | ISO8601 timestamp for traceability |
| `autopilot` | Always `true` in `/code:plan` output. Flags this plan for `/code:autopilot` processing. |
| `status` | Lifecycle marker: `draft` (during planning) → `ready` (ExitPlanMode approved) → `in-progress` (autopilot picked up) → `done` |
| `estimated_size` | Rough size hint for autopilot to calibrate iteration counts. `small` = < 5 files, `medium` = 5–15, `large` = > 15 |
| `issue` | GitHub Issue number if known, otherwise `null`. Autopilot's Stage 3.5 will create an Issue if `null`. |

## Why the directive matters

Without the directive, `ExitPlanMode` approval causes Claude to implement the plan directly. The autopilot pipeline (sprint → audit → simplify → ship → review → retrospective) is skipped entirely.

The directive establishes a behavioral contract: "this plan is for autopilot." Claude reads it immediately after approval and routes implementation through `/code:autopilot`.
