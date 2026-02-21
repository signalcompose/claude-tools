# Learnings PDCA Reference

## Project-Side: `docs/dev-cycle-learnings.md` Optimization

After integrating Auditor + Researcher reports in Step 3:

1. Read `docs/dev-cycle-learnings.md` (if it exists)
2. Classify each finding:
   - Duplicates an existing Active Learning → **Merge** (strengthen evidence, update date)
   - Existing Active Learning is now resolved → **Promote** to Resolved (add resolution date + evidence)
   - New finding → **Add** to Active Learnings
3. If Active Learnings exceed 10 items → consolidate related items, aggressively Promote resolved ones (limit keeps injected context concise for sprint agents)
4. Write the optimized file (create if it doesn't exist yet)
5. Commit as part of Step 5 retrospective artifacts

**Template for new file** (if `docs/dev-cycle-learnings.md` does not exist):

```markdown
# Dev Cycle Learnings

Project-local learnings from dev-cycle retrospectives.
Managed automatically by `code:retrospective` — manual edits are preserved.

## Active Learnings

<!-- Active items are read by code:sprint-impl Phase 1 and appended to agent task descriptions in Phase 6 -->

### [YYYY-MM-DD] <short title>
- **Source**: Auditor | Researcher (which agent's report the finding was extracted from during Step 3 integration)
- **Category**: code-quality | process | architecture | testing | performance
- **Finding**: <what was observed>
- **Action**: <what agents should do differently>

## Resolved

<!-- Items promoted to Resolved by code:retrospective when evidence of fix is found -->

### [YYYY-MM-DD] <short title> (resolved: YYYY-MM-DD)
- **Original finding**: <what was observed>
- **Action taken**: <what agents did differently>
- **Resolution**: <how it was fixed>
```

## Plugin-Side: GitHub Issue Suggestion

When a skill-design-level problem is detected (not project-specific):

```markdown
## Suggested Plugin Issue

**Repository**: signalcompose/claude-tools
**Target skill**: code:<skill-name>
**Title**: <English title>

**Current behavior**: <what currently happens>
**Expected behavior**: <what should happen>
**Evidence**: <evidence from retrospective findings>

To file: `gh issue create --repo signalcompose/claude-tools --title "..." --body "..."`
```

Constraints:
- Do NOT modify files under `${CLAUDE_PLUGIN_ROOT}/` — they are cached and will be overwritten on next `/plugin update`
- Do NOT auto-create the Issue — output the suggestion for the user to decide
