# CI Integration & HEAD Filtering

How to collect CI results and filter out already-fixed issues.

## Collecting CI Results

### Step 1: Check Status

```bash
gh pr checks <PR番号>
```

Parse output for FAIL/PASS/PENDING status per check.

### Step 2: Get Failure Details

For each failed check:
```bash
# Get failed checks using the bucket field (pass/fail/pending/skipping/cancel)
gh pr checks <PR番号> --json name,bucket,link --jq '.[] | select(.bucket == "fail")'

# Get failed log
gh run view <run-id> --log-failed
```

### Step 3: Collect Review Comments

```bash
gh pr view <PR番号> --json comments --jq '.comments[].body'
```

Also check for Claude Code review comments (automated review feedback).

## HEAD Filtering Logic

**Purpose**: Avoid sending already-fixed issues to the fixer.

After collecting CI failure details and review comments, compare with the current diff:

### Algorithm

```
FOR each CI issue or review comment:
  1. Extract the file path and line number from the issue
  2. Get current diff: gh pr diff <PR番号>
  3. Check if the referenced line still exists in the current HEAD
  4. IF the line has been modified or removed since the issue was reported:
       → Mark as "already addressed" — do NOT send to fixer
  5. ELSE:
       → Include in the fixer's issue list
END FOR
```

### Implementation

```bash
# Get current diff to compare
gh pr diff <PR番号> > /tmp/claude/pr-diff.txt

# For each issue file:line, check if it's still in the diff
# If the line is no longer changed, the issue may be resolved
```

## Sandbox Notes

`gh` commands may fail in sandboxed environments due to TLS certificate restrictions.
Use `dangerouslyDisableSandbox: true` when calling `gh` via Bash tool.

This is safe for read-only operations like `gh pr view`, `gh pr checks`, and `gh run view`.
