# Dev Cycle Learnings

Project-local learnings from dev-cycle retrospectives.
Managed automatically by `code:retrospective` — manual edits are preserved.

## Active Learnings

<!-- Active items are read by code:sprint-impl Phase 1 and appended to agent task descriptions in Phase 6 -->

### [2026-02-21] DDD spec gate scope for documentation-only changes
- **Source**: Auditor
- **Category**: process
- **Finding**: DDD spec gate (Phase 4.5) failed because no `docs/specs/` document was created for a documentation-only change (skill definition updates). The gate makes no exception for non-code changes.
- **Action**: For documentation-only branches, create a lightweight spec (design rationale + change scope) under `docs/specs/` before committing, or propose a process exception for non-code changes.

### [2026-02-21] GitHub Issue tracking for all change types
- **Source**: Auditor
- **Category**: process
- **Finding**: No GitHub Issue was created for the two-tier PDCA feature branch. Commit messages contain zero issue references. The ISSUE principle applies to all changes, not just code.
- **Action**: Always create a GitHub Issue before starting work, even for documentation-only changes. Reference the issue number in commit messages.

### [2026-02-21] Phase 5 learnings injection lacks concrete example
- **Source**: Researcher
- **Category**: architecture
- **Finding**: sprint-impl Phase 6 has a concrete example of learnings injection (`## Project Learnings` section), but Phase 5 (sequential-only sprints) has no equivalent example, making the injection path ambiguous.
- **Action**: Add a concrete example to Phase 5 showing how learnings are applied during sequential implementation, similar to Phase 6's example format.

### [2026-02-21] audit-compliance asymmetry with learnings check
- **Source**: Researcher
- **Category**: architecture
- **Finding**: The auditor-prompt.md (retrospective agent) checks `docs/dev-cycle-learnings.md`, but the standalone `audit-compliance` skill does not. Running `/code:audit-compliance` independently will not verify learnings follow-up.
- **Action**: Consider adding learnings check to audit-compliance/SKILL.md PROCESS section, or document that learnings follow-up is retrospective-only.

## Resolved

<!-- Items promoted to Resolved by code:retrospective when evidence of fix is found -->

