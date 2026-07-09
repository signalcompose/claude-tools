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
# File classes:
#   code   = source-code file (test-bearing language) OR anything unrecognized (fail-open)
#   doc    = prose documentation (md, txt, rst, ...)
#   config = structured/executable config (yaml, yml, toml, json, ini, ...) — CI
#            workflows live here and CAN swallow failures / carry misleading comments,
#            so config is NOT treated as inert.
#   (lock/env/pure-data files carry no review value on their own.)
#
# Design (per measured cost + Fable review + PR #274 code review):
#   - code-reviewer          : ALWAYS (generalist safety net; its failure aborts the review)
#   - pr-test-analyzer       : run iff ≥1 code file (its value is test coverage OF code;
#                              docs/config-only PRs have nothing for it to analyze)
#   - silent-failure-hunter  : run iff ≥1 code OR config file (error-swallowing lives in
#                              code AND in CI/config yaml — e.g. `|| true`, continue-on-error)
#   - comment-analyzer       : run iff ≥1 code, doc, OR config file (all carry comments/prose)
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

# --name-only lists just the changed file paths (one per line).
FILES="$(gh pr diff "${PR_NUMBER}" --name-only 2>/dev/null)"
if [ $? -ne 0 ] || [ -z "${FILES}" ]; then
  fail_open "gh pr diff returned no files"
fi

has_code=0     # source-code file (test-bearing language) or unrecognized (fail-open)
has_doc=0      # prose documentation
has_config=0   # structured/executable config (can carry logic or comments)
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
    json|yaml|yml|toml|ini|cfg|conf|properties)
      has_config=1 ;;
    lock|env)
      : ;;  # pure data / secrets: no reviewer needs it on its own
    *)
      # any other extension: source code
      has_code=1 ;;
  esac
done <<< "${FILES}"

reviewers=""
add() { reviewers="${reviewers:+$reviewers }$1"; }

# code-reviewer: always
add "code-reviewer"
echo "DECISION: LAUNCH code-reviewer (always — generalist safety net)"

# pr-test-analyzer: only when source code changed
if [ "${has_code}" -eq 1 ]; then
  add "pr-test-analyzer"
  echo "DECISION: LAUNCH pr-test-analyzer (source-code files changed)"
else
  echo "DECISION: SKIP pr-test-analyzer (no source-code files — nothing to analyze for test coverage)"
fi

# silent-failure-hunter: code or config (CI/config yaml can swallow failures)
if [ "${has_code}" -eq 1 ] || [ "${has_config}" -eq 1 ]; then
  add "silent-failure-hunter"
  echo "DECISION: LAUNCH silent-failure-hunter (code or config files changed)"
else
  echo "DECISION: SKIP silent-failure-hunter (docs/data only — no error-handling surface)"
fi

# comment-analyzer: code, doc, or config (all carry comments/prose)
if [ "${has_code}" -eq 1 ] || [ "${has_doc}" -eq 1 ] || [ "${has_config}" -eq 1 ]; then
  add "comment-analyzer"
  echo "DECISION: LAUNCH comment-analyzer (code, doc, or config files changed)"
else
  echo "DECISION: SKIP comment-analyzer (pure data/secret files only — no comments/prose)"
fi

echo "REVIEWERS: ${reviewers}"
