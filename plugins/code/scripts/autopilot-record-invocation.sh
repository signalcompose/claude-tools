#!/usr/bin/env bash
# autopilot-record-invocation.sh — PostToolUse hook for the Skill tool.
#
# When the leader invokes a Skill-tool call whose skill name matches the
# current autopilot phase's expected skill, append an entry to
# .claude/autopilot.state.json / invocations[]. This is the evidence
# autopilot-state.sh `advance` checks; it closes the #253 silent-skip hole.
#
# The hook is best-effort: if state is absent (no autopilot run), if the
# invoked skill does not match the current phase, or if parsing fails, we
# exit 0 quietly. Never block Skill execution — we only record.

set -euo pipefail

# Read the hook payload from stdin. Claude Code passes a JSON object with at
# least { tool_name, tool_input, tool_use_id }. tool_input carries the Skill
# arguments when tool_name == "Skill".
payload=$(cat 2>/dev/null || true)
[ -z "$payload" ] && exit 0

# Only act on Skill tool calls. Any other tool name is ignored.
tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // ""' 2>/dev/null || echo "")
[ "$tool_name" = "Skill" ] || exit 0

# Extract skill name and tool_use_id. The Skill tool schema stores the skill
# name under tool_input.skill.
skill=$(printf '%s' "$payload" | jq -r '.tool_input.skill // ""' 2>/dev/null || echo "")
tool_use_id=$(printf '%s' "$payload" | jq -r '.tool_use_id // ""' 2>/dev/null || echo "")
[ -n "$skill" ] || exit 0

# Locate the autopilot state for the current project.
project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
state_file="${project_dir}/.claude/autopilot.state.json"
[ -f "$state_file" ] || exit 0

# Read current phase. Bail silently if state is malformed.
current_phase=$(jq -r '.phase // ""' "$state_file" 2>/dev/null || echo "")
[ -n "$current_phase" ] || exit 0
[ "$current_phase" = "complete" ] && exit 0

# Look up the skill expected for the current phase. We only record invocations
# that align with the active phase — unrelated Skill calls (e.g. cvi:speak)
# must not pollute the audit log or advance falsely.
expected=""
case "$current_phase" in
  sprint)          expected="code:sprint-impl" ;;
  audit)           expected="code:audit-compliance" ;;
  simplify)        expected="simplify" ;;
  ship)            expected="code:shipping-pr" ;;
  post-pr-review)  expected="code:pr-review-team" ;;
  retrospective)   expected="code:retrospective" ;;
  *) exit 0 ;;
esac

[ "$skill" = "$expected" ] || exit 0

# Delegate to autopilot-state.sh. Silence normal stdout (hook output is noisy
# to the user); surface errors on stderr so mis-wiring is still observable.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PROJECT_DIR="$project_dir" \
  bash "${SCRIPT_DIR}/autopilot-state.sh" record-invocation "$current_phase" "$skill" "$tool_use_id" >/dev/null || true

exit 0
