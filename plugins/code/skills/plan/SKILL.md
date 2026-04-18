---
name: plan
description: |
  built-in /plan mode の薄いラッパー。plan file 先頭に autopilot 強制 directive を注入することで、
  承認後の実装が必ず /code:autopilot pipeline を経由することを保証する。
  Use when user says "/code:plan", "プラン書いて", "autopilot で実装する plan を作って".
user-invocable: true
argument-hint: [description or issue reference]
---

# /code:plan — autopilot-enforced planning

**MANDATORY**: This skill is a thin wrapper around built-in `/plan` mode. Its distinguishing behavior is injecting an autopilot directive at the top of the generated plan file, ensuring that implementation goes through `/code:autopilot` pipeline.

The leader MUST:
1. Enter built-in plan mode via `EnterPlanMode` tool (Step 1)
2. Interpret `$ARGUMENTS` as natural language to determine plan source (Step 2)
3. Explore / synthesize / write plan file (Step 3)
4. **Inject the autopilot directive at the top of the plan file** (Step 4, CRITICAL)
5. Call `ExitPlanMode` to request user approval (Step 5)
6. After approval, automatically invoke `/code:autopilot <plan-file>` (Step 6)

## Input Interpretation

`$ARGUMENTS` is interpreted as natural language. No explicit flags.

| Pattern | Interpretation |
|--------|---------------|
| empty | Synthesize from current conversation history |
| `今までの...`, `これまでの...`, `会話から...`, `議論で...` | Synthesize from conversation history |
| `Issue N`, `#N`, `issue 123 から...`, GitHub URL | Fetch via `gh issue view N --json title,body,comments` and synthesize |
| anything else (free text) | Treat as description; structure directly |

**Ambiguity rule**: If the input could mean multiple things, ask a single clarifying question before entering plan mode.

## Step 1: Enter Plan Mode

Call the `EnterPlanMode` tool immediately. The built-in plan mode will provide:
- A plan file path (e.g., `/Users/.../.claude/plans/<adjective-word-word>.md`)
- Read-only restrictions (only the plan file is writable)
- Phase structure: Initial Understanding → Design → Review → Final Plan → ExitPlanMode

## Step 2: Interpret $ARGUMENTS

Based on the input pattern (see table above), identify the plan source:

**Conversation synthesis**: Walk the current conversation context to extract goals, decisions, acceptance criteria, files mentioned, trade-offs discussed.

**Issue-based**: Run `gh issue view <N> --json title,body,comments`. Use the result to populate plan sections.

**Free text**: Use the description directly as the seed for Goal and Acceptance. Ask clarifying questions if critical sections are unspecified.

## Step 3: Explore and Synthesize (standard plan mode phases)

Follow the built-in plan mode workflow:
- Launch Explore agents if code context is needed
- Launch Plan agents if design alternatives need evaluation
- Write the plan file incrementally

Plan file sections (recommended):
- **Context** (why this change is being made)
- **Goal** (what should be achieved)
- **Acceptance Criteria** (measurable success conditions)
- **Files to Modify** (absolute or relative paths)
- **Test Strategy** (how to verify end-to-end)
- **Risks** (known concerns, classifier blocks in auto mode)
- **References** (related docs, Issues, PRs)

## Step 4: Inject Autopilot Directive (CRITICAL)

**The plan file MUST begin with this directive block**, before any other content:

```markdown
🔴 **MANDATORY**: このプランは auto mode で `/code:autopilot` により実装すること。手動実装は禁止。
起動コマンド: `/code:autopilot <plan-file-absolute-path>`

---
```

The directive makes the difference between this skill and built-in `/plan`. Without it, approval leads to direct implementation and the autopilot pipeline (sprint → audit → simplify → ship → review → retrospective) is bypassed.

**Also include a YAML frontmatter block** immediately after the directive (before the main content):

```yaml
---
created: <ISO8601 timestamp>
autopilot: true
status: draft
estimated_size: small|medium|large
issue: <number>|null
---
```

- `autopilot: true` signals that this plan is intended for `/code:autopilot` processing.
- `status` transitions: `draft` (during planning) → `ready` (when user approves via ExitPlanMode) → `in-progress` (autopilot picks up) → `done`.
- `issue`: set to the Issue number if one exists; otherwise `null` (autopilot's Stage 3.5 will create one).

## Step 5: Exit Plan Mode

Once the plan file is complete (including the directive and frontmatter), call `ExitPlanMode`. The user will review and approve.

## Step 6: Auto-Invoke /code:autopilot (after approval)

**MANDATORY after approval**: Immediately invoke `/code:autopilot` with the plan file path as argument. Do not ask "should I proceed?" — the directive at the top of the plan makes this step obligatory.

Example first action after approval:
```
Next: /code:autopilot /Users/.../.claude/plans/<plan-file>.md
```

If `/code:autopilot` is not yet installed (bootstrap paradox), state so explicitly and proceed with the manual pipeline equivalent (sprint-impl → audit-compliance → simplify → shipping-pr --skip-review → pr-review-team → retrospective).

## Error Handling

- **User declines approval**: Exit cleanly. Do not proceed to Step 6.
- **Issue fetch fails** (Step 2, issue-based): Fall back to asking the user for the Issue body or description.
- **`/code:autopilot` not available**: Log a warning in the summary and run manual pipeline equivalent.

## Important Notes

- This skill is a **thin wrapper**. Its unique value is the directive injection (Step 4). All other steps delegate to built-in plan mode behavior.
- Do NOT skip Step 4. Without the directive, this skill reduces to built-in `/plan`, defeating its purpose.
- Do NOT skip Step 6 unconditionally. If the user explicitly asks to delay implementation, exit gracefully. Otherwise the directive is binding.
- The directive is written in Japanese because the project's primary response language is Japanese. The structure (🔴 MANDATORY / 起動コマンド) matches conventions used in project CLAUDE.md.

## Related

- `/code:autopilot` — the pipeline orchestrator this skill delegates to
- Built-in `/plan` — the parent mechanism this skill wraps
- `plugins/code/skills/plan/templates/directive.md` — canonical directive text (reference)
