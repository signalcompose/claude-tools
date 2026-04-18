---
name: autopilot
description: |
  auto mode 前提のフルパイプライン orchestrator。plan approval から PR Ready-to-merge までを
  sprint → audit → simplify → ship → review → retrospective の順で自動連鎖実行する。
  Use when user says "/code:autopilot", "autopilot で実装", "パイプラインで実装", "フルサイクル".
user-invocable: true
argument-hint: [plan-file | "description" | Issue N 参照]
---

# /code:autopilot — full pipeline orchestrator

**MANDATORY**: auto mode を検出できない場合は即座に refuse すること。auto mode 前提の設計であり、permission prompt が発生する環境で走らせると pipeline が途中停止する。

The leader MUST:
1. Verify auto mode (Step 0, CRITICAL — abort if not detected)
2. Resolve input: plan file / Issue reference / free text (Step 1)
3. Initialize `.claude/autopilot.state.json` (Step 2)
4. Run pipeline phases sequentially (Step 3: sprint → audit → simplify → ship → review → retro)
5. Stop at Ready-to-merge (Step 4 — do NOT auto-merge)

🔴 Stop hook (`autopilot-stop.sh`) enforces phase chaining. Do not bypass.

## Step 0: Auto mode verification

Run:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-detect-auto-mode.sh
```

Exit code semantics:
- `0` — auto mode detected (source printed to stdout). Proceed.
- `1` — auto mode disabled by managed setting. Report and abort.
- `2` — not detected. Print guidance and abort:
  ```
  autopilot は auto mode 前提です。以下のいずれかを実施してください:
    1. claude --permission-mode auto で再起動
    2. ~/.claude/settings.json に "permissions": {"defaultMode": "auto"} を追加
    3. 単発の opt-in: touch .claude/autopilot.auto-mode-confirmed
    4. auto mode 不要な場合は /code:dev-cycle を使用
  ```

## Step 1: Resolve input

`$ARGUMENTS` is interpreted as natural language. No flags.

| Pattern | Action |
|--------|--------|
| Absolute path ending in `.md` | Treat as plan file, read it |
| `Issue N`, `#N`, `https://github.com/.../issues/N` | `gh issue view N` → synthesize inline plan |
| free text | Synthesize inline plan from description |
| empty | Abort with guidance to use `/code:plan` first |

For inline plan synthesis, construct a minimal plan with Goal / Acceptance / Files to Modify / Test Strategy derived from the input. Write to `.claude/plans/autopilot-<timestamp>-<slug>.md` with the autopilot directive at the top (same format as `/code:plan` output).

## Step 2: State initialization

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-state.sh init <plan-file> [issue-number]
```

Mark `auto_mode_confidence` based on Step 0:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-state.sh set auto_mode_confidence '"detected"'
```

Run Stage 3.5 (ensure-issue) early to link plan to an OPEN GitHub Issue:
```bash
ISSUE=$(bash ${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-ensure-issue.sh <plan-file>)
bash ${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-state.sh set issue_number "$ISSUE"
```

## Step 3: Pipeline execution

After Step 2, the state file drives phase progression. The Stop hook (`autopilot-stop.sh`) intercepts stop attempts and instructs the leader to invoke the next skill.

Phase map (handled by Stop hook; documented here for transparency):

| Phase | Skill to invoke | Args |
|-------|----------------|------|
| sprint | `code:sprint-impl` | plan file path |
| audit | `code:audit-compliance` | — |
| simplify | `simplify` (built-in) | — |
| ship | `code:shipping-pr` | `--skip-review` |
| post-pr-review | `code:pr-review-team` | PR number (auto-detected) |
| retrospective | `code:retrospective` | — |

**Leader behavior during pipeline**:
- After completing a phase's work, invoke `Skill` for the next phase. The Stop hook detects phase transitions from the state file.
- Do NOT ask the user for confirmation between phases. The directive in the plan file and user's initial invocation authorize the full chain.
- If a phase fails (critical error, classifier block 3x, test failure):
  - Record the failure via `autopilot-state.sh set last_failure "..."` and exit the cycle cleanly. Do NOT retry indefinitely.

## Step 4: Ready-to-merge stop

After `retrospective` phase completes, the Stop hook cleans up the state file and allows stopping. At this point:
- PR exists and is merge-eligible (CI SUCCESS, review 0 critical / 0 important)
- Report summary: PR URL, review stats, CI status, iteration counts per phase
- Wait for explicit user instruction to merge (per CLAUDE.md convention)

## Error handling

- **Classifier block**: the classifier aborts auto mode after 3 consecutive or 20 total denials. If hit, emit state dump + `resume_command` and exit gracefully. User can resume via `/code:autopilot` after the block root cause is cleared.
- **CI stuck pending**: `pr-review-team` waits with `wait-ci-checks.sh`. If CI remains pending after max retries, report and stop with state preserved for resume.
- **Context exhaustion**: at phase boundaries, save state + push current commits. Resume from the same phase in a new session.
- **Issue missing / CLOSED** (ensure-issue step): abort with clear message; user must reopen or create new Issue.

## State file resume

To resume an interrupted cycle (new session, context recovered):

```bash
/code:autopilot  # no args, reads .claude/autopilot.state.json if present
```

The skill detects existing state and jumps to the recorded phase instead of reinitializing.

## Important Notes

- This skill runs **autonomously** in auto mode — no inter-phase confirmations
- `/code:autopilot` is the **only authorized entry** for the full pipeline. Do NOT invoke `sprint-impl` → `audit-compliance` → ... manually in sequence outside autopilot.
- The `skip_review` flag on `shipping-pr` is set automatically during the `ship` phase; do not set it manually.
- The merge step (`gh pr merge`) is NEVER automatic. It requires explicit user instruction per CLAUDE.md rules.
- **When /code:autopilot is not available** (bootstrap): manually follow the pipeline in the same order. The plan directive's enforcement is via Claude's reading, not a runtime check.

## Related

- `/code:plan` — creates plan files with autopilot directive baked in
- `/code:dev-cycle` — legacy, non-auto-mode pipeline
- `/code:shipping-pr --skip-review` — called by autopilot's ship phase
- `plugins/code/scripts/autopilot-state.sh` — state management
- `plugins/code/scripts/autopilot-stop.sh` — Stop hook enforcement
- `plugins/code/scripts/autopilot-detect-auto-mode.sh` — auto mode detection
- `plugins/code/scripts/autopilot-ensure-issue.sh` — Stage 3.5 Issue linkage
