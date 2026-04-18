#!/usr/bin/env bash
# autopilot-detect-auto-mode.sh — Detect whether Claude Code is in auto mode.
#
# Usage: autopilot-detect-auto-mode.sh
#
# Detection order (first hit wins, exits 0 with the source on stdout):
#   1. Explicit opt-in flag:  .claude/autopilot.auto-mode-confirmed exists
#   2. Project settings:      .claude/settings.json permissions.defaultMode == "auto"
#   3. Project local:         .claude/settings.local.json permissions.defaultMode == "auto"
#   4. User global:           ~/.claude/settings.json permissions.defaultMode == "auto"
#
# Disable conditions (any match -> exit 1, "disabled" on stdout):
#   - any of the scanned settings has permissions.disableAutoMode == "disable"
#
# Exit codes:
#   0 — auto mode detected (source echoed to stdout)
#   1 — auto mode disabled by managed setting
#   2 — auto mode not detected
#
# No side effects. Read-only scan.

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "autopilot-detect: jq required" >&2; exit 2; }

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
OPT_IN_FLAG="${PROJECT_DIR}/.claude/autopilot.auto-mode-confirmed"

# 1. Opt-in flag
if [ -f "$OPT_IN_FLAG" ]; then
  echo "opt-in-flag"
  exit 0
fi

# Helper: read a JSON field safely
get_field() {
  local file="$1" path="$2"
  [ -f "$file" ] || return 1
  jq -r "$path // empty" "$file" 2>/dev/null || return 1
}

# First check disable conditions across all layers
for f in \
  "${PROJECT_DIR}/.claude/settings.json" \
  "${PROJECT_DIR}/.claude/settings.local.json" \
  "${HOME}/.claude/settings.json"
do
  disable=$(get_field "$f" '.permissions.disableAutoMode')
  if [ "$disable" = "disable" ]; then
    echo "disabled"
    exit 1
  fi
done

# 2–4. Scan layers for defaultMode == "auto"
for f in \
  "${PROJECT_DIR}/.claude/settings.json:project" \
  "${PROJECT_DIR}/.claude/settings.local.json:local" \
  "${HOME}/.claude/settings.json:user"
do
  path="${f%%:*}"
  label="${f##*:}"
  mode=$(get_field "$path" '.permissions.defaultMode')
  if [ "$mode" = "auto" ]; then
    echo "$label"
    exit 0
  fi
done

# Not detected
echo "not-detected"
exit 2
