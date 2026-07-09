#!/usr/bin/env bash
# select-reviewers.sh — Deterministically decide which review subagents to launch
# based on the file types touched by a PR, to avoid spending tokens on reviewers
# that cannot find anything in the changed files.
#
# Usage: bash select-reviewers.sh <PR番号>
#
# Output (stdout):
#   DECISION lines (LAUNCH/SKIP with reason) for audit visibility — NOT silent.
#   A final line:  REVIEWERS: <space-separated bare reviewer names>
# The leader parses the REVIEWERS line and launches exactly that set.
#
# Reviewer names map to pr-review-toolkit subagents:
#   code-reviewer  silent-failure-hunter  pr-test-analyzer  comment-analyzer
#
# Design (per measured cost + Fable review):
#   - code-reviewer          : ALWAYS (generalist safety net; its failure aborts the review)
#   - silent-failure-hunter  : run iff ≥1 source-code file changed (error handling is a code property)
#   - pr-test-analyzer       : run iff ≥1 source-code file changed (its value is test coverage OF code;
#                              a docs/config-only PR has nothing for it to analyze)
#   - comment-analyzer       : run iff ≥1 code OR doc file changed (comment/prose accuracy)
# When file classification is uncertain, the file is treated as code (fail-open:
# "when in doubt, run the reviewer"). On any error resolving the diff, launch ALL 4.

set -uo pipefail

PR_NUMBER="${1:-}"
ALL="code-reviewer silent-failure-hunter pr-test-analyzer comment-analyzer"

fail_open() {
  # Any uncertainty about the diff → launch everything (never under-review).
  echo "DECISION: could not classify changed files ($1) — launching all reviewers (fail-open)"
  echo "REVIEWERS: ${ALL}"
  exit 0
}

if [ -z "${PR_NUMBER}" ]; then
  fail_open "no PR number argument"
fi

# --relative keeps paths repo-relative; --name-only lists just the changed files.
FILES="$(gh pr diff "${PR_NUMBER}" --name-only 2>/dev/null)"
if [ $? -ne 0 ] || [ -z "${FILES}" ]; then
  fail_open "gh pr diff returned no files"
fi

has_code=0   # source-code file (test-bearing language)
has_doc=0    # documentation / prose
# Anything that is neither clearly doc nor clearly config is treated as code.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  base="$(basename -- "$f")"
  if [[ "$base" != *.* ]]; then
    # no extension (e.g. Makefile, Dockerfile, LICENSE) — treat as code (fail-open)
    has_code=1
    continue
  fi
  ext="$(printf '%s' "${base##*.}" | tr '[:upper:]' '[:lower:]')"
  case "$ext" in
    md|markdown|mdx|txt|rst|adoc|org)
      has_doc=1 ;;
    json|yaml|yml|toml|ini|cfg|conf|lock|env|properties)
      : ;;  # config/data: no reviewer needs it on its own
    *)
      # any other extension: source code
      has_code=1 ;;
  esac
done <<< "${FILES}"

set=""
add() { set="${set:+$set }$1"; }

# code-reviewer: always
add "code-reviewer"
echo "DECISION: LAUNCH code-reviewer (always — generalist safety net)"

if [ "${has_code}" -eq 1 ]; then
  add "silent-failure-hunter"
  echo "DECISION: LAUNCH silent-failure-hunter (source-code files changed)"
  add "pr-test-analyzer"
  echo "DECISION: LAUNCH pr-test-analyzer (source-code files changed)"
else
  echo "DECISION: SKIP silent-failure-hunter (no source-code files — docs/config only)"
  echo "DECISION: SKIP pr-test-analyzer (no source-code files — nothing to analyze for test coverage)"
fi

if [ "${has_code}" -eq 1 ] || [ "${has_doc}" -eq 1 ]; then
  add "comment-analyzer"
  echo "DECISION: LAUNCH comment-analyzer (code or doc files changed)"
else
  echo "DECISION: SKIP comment-analyzer (no code or doc files — config/data only)"
fi

echo "REVIEWERS: ${set}"
