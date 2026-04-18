#!/usr/bin/env bash
# autopilot-ensure-issue.sh — Ensure the plan has a linked OPEN GitHub Issue.
#
# Usage: autopilot-ensure-issue.sh <plan-file>
#
# Behavior:
#   - Reads YAML frontmatter `issue` field from the plan file.
#   - If `issue` is null or missing:
#       → Create a new issue via `gh issue create` using plan Goal as title
#         and the full plan as body; update plan frontmatter with the new number.
#   - If `issue` is a number:
#       → Verify via `gh issue view <N> --json state`. Must be OPEN.
#       → If CLOSED or missing: exit 1 with error.
#   - Emits the resolved issue number on stdout.
#
# Requires: yq (v4+), gh, jq.
# Exit codes:
#   0 — OK, issue number on stdout
#   1 — referenced issue is closed or missing
#   2 — usage error / dependency missing

set -euo pipefail

die() { echo "autopilot-ensure-issue: $*" >&2; exit "${2:-1}"; }

command -v gh >/dev/null 2>&1 || die "gh CLI required" 2
command -v jq >/dev/null 2>&1 || die "jq required" 2

PLAN="${1:-}"
[ -n "$PLAN" ] || die "usage: autopilot-ensure-issue.sh <plan-file>" 2
[ -f "$PLAN" ] || die "plan file not found: $PLAN" 2

# Temp file cleanup on any exit
TMP_PLAN=""
cleanup() { [ -n "$TMP_PLAN" ] && rm -f "$TMP_PLAN"; }
trap cleanup EXIT

# Read frontmatter block (between first two --- markers) - scoped lookup only
frontmatter=$(awk '/^---$/{count++; if (count==2) exit; next} count==1' "$PLAN")

# Look up `issue:` only inside frontmatter (prevents false match on body text)
issue_raw=$(echo "$frontmatter" | awk '/^issue:/{sub(/^issue:[[:space:]]*/,""); print; exit}' | tr -d '[:space:]')

# Normalize null/empty
case "$issue_raw" in
  ""|null|None|nil) issue="" ;;
  *) issue="$issue_raw" ;;
esac

if [ -n "$issue" ]; then
  # Validate OPEN
  state=$(gh issue view "$issue" --json state --jq '.state' 2>/dev/null || true)
  if [ -z "$state" ]; then
    die "issue #$issue not found"
  fi
  if [ "$state" != "OPEN" ]; then
    die "issue #$issue is $state, not OPEN — human review needed"
  fi
  echo "$issue"
  exit 0
fi

# Create new issue from plan
# Title: first H1 or derived from Goal section, max 70 chars
title=$(awk '/^## Goal/{flag=1; next} /^## /{flag=0} flag && NF{print; exit}' "$PLAN" \
        | sed -E 's/^[-*][[:space:]]*//' | head -c 70)
if [ -z "$title" ]; then
  # Fallback: first H1 from file
  title=$(grep -m1 -E '^# ' "$PLAN" | sed -E 's/^#[[:space:]]*//' | head -c 70)
fi
[ -n "$title" ] || die "could not derive title from plan" 2

# Body: strip the MANDATORY autopilot directive block and frontmatter before posting.
# The directive is an internal routing signal; the GitHub issue should carry only
# the human-readable content (Goal, Acceptance, Files, Test Strategy, Risks, References).
body=$(awk '
  /^🔴 \*\*MANDATORY\*\*/{skip_directive=1; next}
  skip_directive && /^---$/{skip_directive=0; in_frontmatter=1; next}
  in_frontmatter && /^---$/{in_frontmatter=0; next}
  !skip_directive && !in_frontmatter{print}
' "$PLAN")

# If the directive/frontmatter strip resulted in an empty body, fall back to full content.
[ -n "$body" ] || body=$(cat "$PLAN")

# Create issue (label is optional - omit if repository lacks it)
gh_args=(--title "$title" --body "$body")
if gh label list --limit 50 --json name --jq '.[].name' 2>/dev/null | grep -qx enhancement; then
  gh_args+=(--label enhancement)
fi
url=$(gh issue create "${gh_args[@]}" 2>&1 | tail -1)
new_num=$(echo "$url" | grep -oE '[0-9]+$')
[ -n "$new_num" ] || die "failed to parse issue number from: $url"

# Update plan frontmatter: set issue: <new_num>. Use trap-tracked temp file.
TMP_PLAN=$(mktemp)
# Detect whether the frontmatter already contains an issue line
has_issue=$(echo "$frontmatter" | awk '/^issue:/{found=1} END{print found+0}')
if [ "$has_issue" = "1" ]; then
  awk -v num="$new_num" '
    /^---$/{count++; print; next}
    count==1 && /^issue:/{print "issue: " num; updated=1; next}
    {print}
    END{if (!updated) exit 2}
  ' "$PLAN" > "$TMP_PLAN" && mv "$TMP_PLAN" "$PLAN" && TMP_PLAN=""
else
  awk -v num="$new_num" '
    /^---$/{count++; print; if (count==1) print "issue: " num; next}
    {print}
  ' "$PLAN" > "$TMP_PLAN" && mv "$TMP_PLAN" "$PLAN" && TMP_PLAN=""
fi

echo "$new_num"
