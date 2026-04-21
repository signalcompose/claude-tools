---
name: autopilot-violations
description: Project-local log of autopilot phase bypasses and skip declarations. Read at /code:autopilot start as a commitment device. Authored by the retrospective phase; do not hand-edit unless fixing formatting.
type: feedback
---

# Autopilot Violations — project-local

## Purpose

Past failures observed while running `/code:autopilot` in **this specific project**. Read this at the start of every autopilot run. Do not repeat the patterns listed below.

## Rules (always applicable, regardless of entries below)

1. **Stopping is allowed and expected when blocked**. Record `last_failure` via `autopilot-state.sh` and stop cleanly.
2. **Silently skipping a phase is a spec violation**. If a phase legitimately needs to be skipped, declare it first:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-state.sh skip-declare <phase> "<reason>"
   ```
   The retrospective audits both the declaration and the transcript; silent skips are logged here on detection.
3. **`gh pr merge` is never automatic**. The spec's "complete" state means ready-to-merge, not merged. Wait for an explicit user instruction (e.g. "マージして" or "merge").

## Known violations

<!--
Append new entries here via the retrospective reconciliation step.
Keep most recent first. Consolidate or trim when this section exceeds ~30 entries.

Entry template:

## <YYYY-MM-DD> — <short title>

**Phase**: <phase name>
**Outcome**: SILENT_SKIP | PARTIAL_EXEC | UNAUTHORIZED_ACTION
**Detection**: <what tipped off the audit>
**Rationalization used**: <the excuse the prior run gave, if known>
**Remediation for future runs**: <what should happen instead>
-->

_No entries yet. Retrospective will append here on detection._
