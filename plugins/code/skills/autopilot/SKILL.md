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

## Step 0.5: Read project-local violations memory (Issue #248)

Before Step 1, read this project's autopilot violations log as a commitment device:

```bash
# Locate project memory dir. Claude Code replaces both `/` and `_` with `-`
# in the current working directory path and keeps the leading `-`.
PROJECT_SLUG=$(pwd | sed 's|[/_]|-|g')
VIOLATIONS_FILE="$HOME/.claude/projects/${PROJECT_SLUG}/memory/feedback_autopilot_violations.md"
```

- If the file exists: **Read it with the Read tool**. The Known violations section lists past spec bypasses in this project. Do not repeat them.
- If it does not exist (first autopilot run in this project): bootstrap by copying
  `${CLAUDE_PLUGIN_ROOT}/skills/autopilot/references/violations-skill-template.md`
  to that path, then read it.

The retrospective phase appends new violation entries here when it detects silent skips. Treating this as required reading makes each entry a concrete commitment carried into the next run.

## Stop vs Skip — what counts as a violation

Three behaviors to distinguish at every phase:

| Action | Status | Recording |
|--------|--------|-----------|
| **Stop** when blocked (missing dependency, test failure, external API down, etc.) | ✅ Allowed | `autopilot-state.sh set last_failure '"<reason>"'` — then stop. User resumes after fixing. |
| **Skip** a phase because the project state makes it a legitimate no-op (e.g., no code changes for `simplify` to review) | ⚠️ Allowed **with declaration** | `autopilot-state.sh skip-declare <phase> "<reason>"` — then `advance`. Retrospective reviews the declaration. |
| **Silent skip** — proceed past a phase without its skill invocation and without a declaration | ❌ Spec violation | Retrospective detects via transcript grep and appends an entry to the violations memory file. |

### Rationalization patterns to reject (documented in Issue #247)

- "This PR is docs-only, so `simplify` adds no value." → Invoke `simplify` anyway (cheap, maintains discipline); or `skip-declare` with a concrete reason if truly no-op.
- "One `pr-review-toolkit:code-reviewer` agent is enough; four is overkill." → No. `code:pr-review-team` specifies four parallel reviewers for a reason.
- "The user said 『走り切って』, so I can merge autonomously." → No. Merge is always gated on an explicit "マージして" / "merge" instruction from the user.
- "I can run several `advance` calls in a row to catch up." → No. Each phase needs its own skill invocation between advances.

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
| simplify | `simplify` (plugin-registered skill) | — |
| ship | `code:shipping-pr` | `--skip-review` (only after simplify metrics.critical == 0 AND metrics.important == 0) |
| post-pr-review | `code:pr-review-team` | PR number (auto-detected) |
| retrospective | `code:retrospective` | — |

**Pre-ship gate**: before invoking `code:shipping-pr --skip-review`, the leader MUST verify:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-state.sh get .metrics.critical
bash ${CLAUDE_PLUGIN_ROOT}/scripts/autopilot-state.sh get .metrics.important
```
Both must be `0`. If not, `autopilot-stop.sh` cleans up state and exits. The user must investigate the unresolved findings manually. Autopilot does not auto-loop back to simplify — convergence failure is a terminal state in the current design (rationale: 5 simplify iterations × N reviewers already represents meaningful budget; further auto-retries may mask structural issues).

**Leader behavior during pipeline**:
- After completing a phase's work, invoke `Skill` for the next phase. The Stop hook detects phase transitions from the state file.
- Do NOT ask the user for confirmation between phases. The directive in the plan file and user's initial invocation authorize the full chain.
- If a phase fails (critical error, classifier block 3x, test failure):
  - Record the failure via `autopilot-state.sh set last_failure "..."` and exit the cycle cleanly. Do NOT retry indefinitely.

**State hygiene — do not manually advance `phase`**:

The Stop hook owns `phase` transitions. It reads the current phase to pick `NEXT_SKILL`, invokes the next skill, and advances the state atomically (see `autopilot-stop.sh` switch). Manually running `autopilot-state.sh set phase ...` while the pipeline is in flight *skips the next-skill dispatch* for the intermediate phase. Concrete failure mode previously observed: while phase was still `ship` (before the Stop hook had advanced it to `post-pr-review`), running `set phase post-pr-review` caused the next Stop hook fire to read `post-pr-review` as the current phase and dispatch `code:retrospective` — `pr-review-team` was never invoked, and the PR shipped without its post-merge review.

- ✅ OK: `autopilot-state.sh advance` (explicit single-step)
- ✅ OK: `autopilot-state.sh set <non-phase-key> ...` (e.g. `last_successful_stage`, `issue_number`, `auto_mode_confidence`)
- ❌ NOT OK: `autopilot-state.sh set phase ...` during normal flow — blocked by the script unless `AUTOPILOT_STATE_ALLOW_SET_PHASE=1` is set (reserved for manual resume-from-crash recovery)

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

## Sandbox bypass policy — do not use `dangerouslyDisableSandbox`

The `Bash` tool accepts a `dangerouslyDisableSandbox: true` parameter. In auto mode this parameter **forces a user confirmation prompt** (auto mode intentionally refuses to auto-approve sandbox bypass, regardless of permission rules or hooks), breaking the autopilot flow. Empirical observations (2026-04-18):

- `dangerouslyDisableSandbox` is evaluated on a layer *above* permission rules and PreToolUse hooks — neither can pre-approve it.
- Auto mode's classifier auto-approves normal `Bash` calls (via `autoAllowBashIfSandboxed: true`) *inside* the sandbox, including plugin cache path bash invocations such as `bash ${CLAUDE_PLUGIN_ROOT}/scripts/*.sh` (both bare and compound forms like `PLUGIN_ROOT=... && bash $PLUGIN_ROOT/scripts/*.sh`). No additional auto-approve hook is needed. Verified empirically 2026-04-19 with an end-to-end autopilot pipeline run (40+ plugin cache path bash invocations, zero prompts).
- Most operations the pipeline runs — `autopilot-state.sh` set/get, `autopilot-ensure-issue.sh`, `pr-review-state.sh`, `git`/`gh` CLI — touch only project-directory files and work correctly inside the sandbox. They do **not** need bypass.

**Rule**: do not pass `dangerouslyDisableSandbox: true` from this skill or any phase it delegates to (sprint / simplify / ship / pr-review-team / retrospective). Let auto mode's classifier handle permissions. (The project previously bundled an `auto-approve-plugin-scripts.sh` PreToolUse hook for the same purpose; it was removed in PR #227 after empirical testing showed the classifier alone is sufficient.) The bypass is reserved for the narrow set of skills that genuinely need macOS audio/GUI system APIs (e.g. `cvi:speak` — which documents the requirement in its own skill file, tied to `say`/`afplay`/`osascript` failing inside the sandbox).

If you encounter a bash command that actually fails inside the sandbox, surface the specific failure (filesystem / network / audio / etc.) before considering bypass. Defensive bypass on unrelated commands converts a silent auto-approval path into a blocking user prompt — which is exactly the regression this note exists to prevent.

## Important Notes

- This skill runs **autonomously** in auto mode — no inter-phase confirmations
- `/code:autopilot` is the **only authorized entry** for the full pipeline. Do NOT invoke `sprint-impl` → `audit-compliance` → ... manually in sequence outside autopilot.
- The `skip_review` flag on `shipping-pr` is set automatically during the `ship` phase; do not set it manually.
- The merge step (`gh pr merge`) is NEVER automatic. It requires explicit user instruction per CLAUDE.md rules.
- **Do NOT pass `dangerouslyDisableSandbox: true`** on `Bash` tool calls. See the "Sandbox bypass policy" section above — the flag forces a blocking user prompt that auto mode intentionally refuses to auto-approve, breaking autopilot flow.
- **When /code:autopilot is not available** (bootstrap): manually follow the pipeline in the same order. The plan directive's enforcement is via Claude's reading, not a runtime check.

## Related

- `/code:plan` — creates plan files with autopilot directive baked in
- `/code:dev-cycle` — legacy, non-auto-mode pipeline
- `/code:shipping-pr --skip-review` — called by autopilot's ship phase
- `plugins/code/scripts/autopilot-state.sh` — state management
- `plugins/code/scripts/autopilot-stop.sh` — Stop hook enforcement
- `plugins/code/scripts/autopilot-detect-auto-mode.sh` — auto mode detection
- `plugins/code/scripts/autopilot-ensure-issue.sh` — Stage 3.5 Issue linkage
