# Main Agent Responsibilities & Guidelines

## Pre-Sprint

1. Branch creation (`feature/phase-N-<scope>`)
2. GitHub Issue creation (parent + sub-issues) via GitHub MCP
3. DDD spec creation + commit
4. Type definitions + typecheck + commit

## During Sprint (Team Agent Management)

1. TeamCreate to create team
2. TaskCreate + dependency setup
3. Agent spawn (`subagent_type: "general-purpose"`, `mode: "acceptEdits"`)
4. Wait for agent completion + verify each agent's output
5. **Commit per-agent individually** (lead performs commits, not agents)
6. After all agents complete: shutdown + TeamDelete

## Post-Sprint

1. Barrel export updates + commit
2. Phase 7 integration verification (tsc, vitest, eslint)
3. Fix commits if needed
4. Overall coverage check

## Agent Prompt Guidelines

- Async handlers must use `await` (`void handler()` is prohibited — prevents unhandled rejection)
- Capability declarations must only include methods that exist on the interface
- Include error case tests (SDK call failures) for each method

## Commit Pattern

- `docs(<scope>): add <phase> specification` (spec)
- `feat(<scope>): add <phase> type definitions` (types)
- `feat(<module>): add <module-name> with TDD tests` (per agent)
- `fix(<scope>): resolve integration issues` (post-merge fixes)

## Output Language

- All user-facing output MUST follow the language configured in user settings
- SKILL.md instructions are in English — this does NOT change the output language
- Technical terms, code identifiers, and commit messages follow their own conventions (commit title: English, commit body: user's language)
