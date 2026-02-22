# Serena MCP Integration Steps

Shared across skills that use Serena MCP for context management.

**Prerequisite**: Serena MCP tools (`mcp__plugin_serena_serena__*`) must be available.
If Serena tools are confirmed unavailable, skip all Serena phases.

## Phase 0: Context Load (at start, ~15 sec)

1. `mcp__plugin_serena_serena__activate_project` — activate the current project
   (use the basename of `$CLAUDE_PROJECT_DIR` as the project name)
2. `mcp__plugin_serena_serena__check_onboarding_performed` — verify onboarding
3. Read relevant memories in parallel:
   - `project_overview` — architecture, current phase
   - `style_and_conventions` — coding rules, commit/PR rules
   - `suggested_commands` — dev commands
   - `task_completion_checklist` — verification steps for shipping
   - Any `phase*` memory matching the current work
4. `mcp__plugin_serena_serena__get_symbols_overview` on files being modified
   to understand existing code structure before making changes

If Serena is NOT available, skip — all essential info is also in `CLAUDE.md` and `docs/`.

## Mid-Sprint: Context Pressure Save (Serena or File)

When context usage exceeds 70%, save work state.

**If Serena is available**, use Serena memory:

```
mcp__plugin_serena_serena__write_memory
  memory_file_name: "pre_compact_<work_content>_<YYYY-MM-DD>"
  content: |
    # Pre-Compact Save — <date>
    ## Completed
    - (list of completed tasks)
    ## In Progress
    - (current task details)
    ## Next Steps
    - (remaining work)
```

**If Serena is NOT available**, save to a local checkpoint file instead:

```bash
cat > .claude/dev-cycle-checkpoint.md << 'CHECKPOINT_EOF'
# Dev Cycle Checkpoint — <date>

## Completed
- (list of completed tasks)

## In Progress
- (current task details)

## Next Steps
- (remaining work)

## Technical Decisions
- (key decisions made during this session)
CHECKPOINT_EOF
```

This file provides the same compaction resilience as Serena memory without requiring MCP.

## Post-Sprint: Memory Save (~10 sec)

Save findings for future sessions:

```
mcp__plugin_serena_serena__write_memory
  memory_file_name: "<phase_name>_complete_<YYYY-MM-DD>"
  content: |
    # <Phase Name> Complete — <date>
    ## What Was Done
    - Files created/modified (list)
    - Test results (count, coverage)
    ## Review Issues Found
    - (if any were found)
    ## Next Steps
    - What comes next
```
