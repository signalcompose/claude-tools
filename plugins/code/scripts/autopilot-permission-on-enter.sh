#!/usr/bin/env bash
# autopilot-permission-on-enter.sh — PermissionRequest hook that switches the
# session permission mode to `auto` when entering plan mode from `/code:plan`.
#
# Why this exists:
#   ExitPlanMode restores whatever permission mode was active just before
#   EnterPlanMode. So if a user invokes `/code:plan` from a non-auto session,
#   approval drops them back into non-auto — defeating autopilot's auto-mode
#   requirement. By switching to auto AT the moment EnterPlanMode triggers a
#   PermissionRequest, the "previous mode" that ExitPlanMode will restore to
#   becomes auto.
#
# Trigger guard — the sentinel file:
#   This hook must only act when the EnterPlanMode originates from /code:plan,
#   not from the built-in /plan. The distinguishing signal is a sentinel file
#   (`${CLAUDE_PROJECT_DIR}/.claude/code-plan-pending.flag`) written by the
#   /code:plan skill just before it calls EnterPlanMode. If the sentinel is
#   absent, emit nothing and exit 0 so built-in /plan behavior is unaffected.
#
# Sentinel lifecycle (one-shot):
#   1. /code:plan writes the sentinel (Step 0.5)
#   2. EnterPlanMode fires PermissionRequest, this hook reads + deletes sentinel
#   3. If for any reason PermissionRequest never fires (e.g. already in auto),
#      /code:plan's Step 1.5 deletes the sentinel unconditionally after
#      EnterPlanMode returns, preventing leak into future built-in /plan calls.
#
# Design constraints (documented in the plan's Risks table):
#   - Timing of setMode relative to EnterPlanMode's capture of the previous
#     mode is undocumented. If it turns out EnterPlanMode snapshots "previous"
#     before PermissionRequest decisions apply, this hook is a no-op. In that
#     case the risk mitigation is to fall back to ExitPlanMode-time injection
#     (separate design, not implemented here).
#   - `mode: "auto"` acceptance by setMode is not in the public docs (which
#     list default/acceptEdits/bypassPermissions). If silently rejected, the
#     hook produces no visible behavior change. Empirical verification is
#     required (see Phase 0 tests in plan generic-napping-bumblebee.md).
#
# Fail-open: any error produces no output + exit 0 so we never block or
# corrupt a legitimate EnterPlanMode call.

set -euo pipefail

# Drain stdin (hooks receive JSON but this hook doesn't need to inspect it).
cat >/dev/null 2>&1 || true

# Resolve sentinel path. CLAUDE_PROJECT_DIR is provided by Claude Code for
# hooks running in a project context.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
[ -n "$PROJECT_DIR" ] || exit 0

SENTINEL="$PROJECT_DIR/.claude/code-plan-pending.flag"
[ -f "$SENTINEL" ] || exit 0

# Consume the sentinel (one-shot) before emitting the decision. If the rm
# fails (read-only filesystem, race with /code:plan's cleanup), fail-open
# rather than double-apply.
rm -f "$SENTINEL" 2>/dev/null || exit 0

# Emit PermissionRequest allow decision with session-scoped setMode.
# The hook output format is documented in Claude Code's hooks-guide
# (auto-approve-specific-permission-prompts section).
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow","updatedPermissions":[{"type":"setMode","mode":"auto","destination":"session"}]}}}
JSON

exit 0
