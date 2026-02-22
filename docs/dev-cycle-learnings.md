# Dev Cycle Learnings

Project-local learnings from dev-cycle retrospectives.
Managed automatically by `code:retrospective` — manual edits are preserved.

## Active Learnings

<!-- Active items are read by code:sprint-impl Phase 1 and appended to agent task descriptions in Phase 6 -->

### [2026-02-21] DDD spec gate scope for documentation-only changes
- **Source**: Auditor
- **Category**: process
- **Finding**: DDD spec gate (Phase 4.5) failed because no `docs/specs/` document was created for a documentation-only change (skill definition updates). The gate makes no exception for non-code changes.
- **Action**: ドキュメント自体の変更（SKILL.md, リファレンスファイル等）では、GitHub Issue が十分に詳細であれば spec ファイルは不要。コード変更を伴う場合は `docs/specs/` に spec を作成する。

### [2026-02-21] GitHub Issue tracking for all change types
- **Source**: Auditor
- **Category**: process
- **Finding**: No GitHub Issue was created for the two-tier PDCA feature branch. Commit messages contain zero issue references. The ISSUE principle applies to all changes, not just code.
- **Action**: Always create a GitHub Issue before starting work, even for documentation-only changes. Reference the issue number in commit messages.

### [2026-02-21] audit-compliance asymmetry with learnings check
- **Source**: Researcher
- **Category**: architecture
- **Finding**: The auditor-prompt.md (retrospective agent) checks `docs/dev-cycle-learnings.md`, but the standalone `audit-compliance` skill does not. Running `/code:audit-compliance` independently will not verify learnings follow-up.
- **Action**: Consider adding learnings check to audit-compliance/SKILL.md PROCESS section, or document that learnings follow-up is retrospective-only.

### [2026-02-22] Runtime state files must be in .gitignore
- **Source**: Researcher
- **Category**: process
- **Finding**: A-2 (Serena fallback) で導入した `.claude/dev-cycle-checkpoint.md` が `.gitignore` に未登録だった。同様に `.claude/dev-cycle.state.json` も未登録。ランタイム状態ファイルの誤コミットリスク。
- **Action**: 新しいランタイムファイルを導入する際は、実装と同時に `.gitignore` にエントリを追加すること。

### [2026-02-22] Inlined references should preserve concrete examples
- **Source**: code-reviewer
- **Category**: documentation
- **Finding**: prohibitions.md をインライン化する際、prohibition #1 の具体的なアンチパターン例と #6 のフック説明が欠落していた。コードレビューで指摘されて修正。
- **Action**: リファレンスをインライン化する場合、「なぜ禁止か」の具体例を省略しない。抽象的なルールだけでは Claude の遵守率が下がる可能性がある。

## Resolved

<!-- Items promoted to Resolved by code:retrospective when evidence of fix is found -->

### [2026-02-21] Phase 5 learnings injection lacks concrete example (resolved: 2026-02-21)
- **Original finding**: sprint-impl Phase 6 has a concrete example of learnings injection (`## Project Learnings` section), but Phase 5 (sequential-only sprints) has no equivalent example, making the injection path ambiguous.
- **Action taken**: Added concrete example to Phase 5 showing how learnings are applied during sequential implementation.
- **Resolution**: sprint-impl/SKILL.md Phase 5 now includes example guidance for applying Active Learnings during sequential tasks.
