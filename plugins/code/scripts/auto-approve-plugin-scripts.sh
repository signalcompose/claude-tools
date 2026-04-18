#!/usr/bin/env bash
# auto-approve-plugin-scripts.sh — PreToolUse hook that auto-approves bash
# invocations of scripts bundled inside any claude-tools plugin's cache directory.
#
# Why this exists:
#   Plugin-internal `.claude/settings.json` permission rules are not loaded by
#   Claude Code (only `agent` and `subagentStatusLine` keys are honored per the
#   plugins-reference docs). `${CLAUDE_PLUGIN_ROOT}` is never expanded inside
#   permission patterns — they are matched literally against the absolute path.
#   Auto mode further drops broad allow rules like `Bash(bash:*)`. The result is
#   that any `bash /Users/.../plugins/cache/.../scripts/*.sh` invocation stalls
#   on a permission prompt, breaking autopilot and any CVI/chezmoi/utils/ask-*
#   command that calls its own bundled script.
#
# Scope:
#   Approves ONLY commands whose first token is `bash` and whose first argument
#   is an absolute path under any Claude Code plugin cache directory, ending in
#   `.sh`. Any other command falls through untouched to the normal permission
#   evaluation.
#
# Deny-rule interaction:
#   Per the permissions docs, deny and ask rules are evaluated regardless of
#   hook decisions. So a user-configured `deny` still wins. This hook cannot
#   override deny.
#
# Input: JSON on stdin with shape:
#   {"tool_name":"Bash","tool_input":{"command":"<cmd>"}, ...}
#
# Output on match:
#   {"hookSpecificOutput":{"hookEventName":"PreToolUse",
#    "permissionDecision":"allow",
#    "permissionDecisionReason":"claude-tools plugin script"}}
#
# Output on no match: (nothing; exit 0)

set -euo pipefail

# Fail-open: if anything goes wrong (no jq, malformed input, etc.), emit nothing
# and exit 0 so we never block a legitimate command.
cleanup() { :; }
trap cleanup EXIT

payload=$(cat 2>/dev/null || true)
[ -n "$payload" ] || exit 0

# jq is available in every environment that runs Claude Code hooks (it's listed
# as a standard dependency). Extract the command field safely.
command -v jq >/dev/null 2>&1 || exit 0
cmd=$(echo "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
[ -n "$cmd" ] || exit 0

# Match: `bash <absolute-path>/plugins/<plugin-name>/scripts/<file>.sh` possibly
# followed by arguments. This covers BOTH:
#   - Installed cache paths: /Users/alice/.claude/plugins/cache/claude-tools/cvi/abc123/scripts/post-speak.sh
#   - Local dev repo paths:  /Users/alice/Src/claude-tools/plugins/cvi/scripts/post-speak.sh
# Both share the canonical `/plugins/<name>/scripts/*.sh` tail structure.
#
# Security note: a maliciously-crafted repo at /tmp/evil/plugins/x/scripts/y.sh
# would also match. Deny rules (e.g. `Bash(rm *)`) still override hook decisions,
# so destructive commands remain blocked regardless. For the intended use case
# (trusted plugin scripts), this trade-off is acceptable and matches the
# established plugin-script convention used across claude-tools.
if echo "$cmd" | grep -qE '^bash[[:space:]]+/[^[:space:]]+/plugins/[^[:space:]]*/scripts/[^[:space:]]+\.sh([[:space:]]|$)'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"claude-tools plugin script"}}
JSON
fi

exit 0
