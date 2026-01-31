---
description: "Run code review and approve for commit (integrates with check-code-review.sh hook)"
---

# Code Review Skill

Review staged changes using the code-reviewer agent and approve them for commit.

## Overview

This skill delegates code review to the `pr-review-toolkit:code-reviewer` agent via Task tool. Manual review is NOT allowed - always use the agent.

## Execution Steps

### Step 1: Check Staged Changes

First, verify there are staged changes to review:

```bash
git diff --cached --stat
```

**If no staged changes**: Report "No staged changes to review" and exit.

### Step 2: Launch Code Reviewer Agent

**MANDATORY**: You MUST use the Task tool to launch the agent. Do NOT review code manually.

```
Task tool call:
- subagent_type: "pr-review-toolkit:code-reviewer"
- prompt: "Review the staged changes (git diff --cached) for this commit. Check for CLAUDE.md compliance, bugs, and code quality issues. Report only issues with confidence >= 80."
- description: "Review staged changes"
```

Wait for the agent to complete and return results.

### Step 3: Handle Review Results

**If issues found (confidence >= 80)**:
- Present the issues to the user
- Do NOT approve the commit
- Suggest fixes

**If no issues found**:
- Report that the review passed
- Proceed to Step 4

### Step 4: Approve for Commit

**MANDATORY**: If review passes, you MUST save the approval hash. Do NOT skip this step.

Run the following commands to save the approval:

```bash
# Determine approval file location
# Prefer project-local .claude/ for project-specific tracking
# Fall back to /tmp/claude/ for projects without .claude directory (ephemeral but functional)
if [[ -d ".claude" ]]; then
    if [[ ! -w ".claude" ]]; then
        echo "Error: .claude directory exists but is not writable" >&2
        exit 1
    fi
    REVIEW_FILE=".claude/review-approved"
else
    if ! mkdir -p /tmp/claude; then
        echo "Failed to create /tmp/claude directory" >&2
        exit 1
    fi
    REVIEW_FILE="/tmp/claude/review-approved"
fi

# Get staged changes hash (capture stderr for error reporting)
GIT_OUTPUT=$(git diff --cached --raw 2>&1)
GIT_STATUS=$?
if [[ $GIT_STATUS -ne 0 ]]; then
    echo "Git error: $GIT_OUTPUT" >&2
    exit 1
fi

# Calculate hash with explicit error checking
HASH_OUTPUT=$(echo "$GIT_OUTPUT" | shasum -a 256 2>&1)
HASH_STATUS=$?
if [[ $HASH_STATUS -ne 0 ]]; then
    echo "Hash calculation failed: $HASH_OUTPUT" >&2
    exit 1
fi
HASH=$(echo "$HASH_OUTPUT" | cut -d' ' -f1)

# Validate hash (reject empty or no-changes hash)
# e3b0c44... is SHA-256 of empty string - when git diff --cached --raw outputs nothing, this hash is produced
if [[ -z "$HASH" || "$HASH" == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]]; then
    echo "No staged changes found." >&2
    exit 1
fi

# Save approved hash
if ! echo "$HASH" > "$REVIEW_FILE"; then
    echo "Failed to save approval hash to $REVIEW_FILE" >&2
    exit 1
fi
# Display truncated hash for readability (full hash saved to file)
echo "Review approved. Hash: ${HASH:0:16}..."
echo "You can now commit the staged changes."
```

This saves a hash of the staged changes that the pre-commit hook can verify.

## Integration with Pre-commit Hook

This skill works with `check-code-review.sh` as a pre-commit hook:

1. Hook blocks `git commit` if no review approval exists
2. User runs `/code:review-commit`
3. This skill launches code-reviewer agent
4. If passed, approval hash is saved
5. Subsequent `git commit` proceeds if hash matches

## Important

- ALWAYS use Task tool with `pr-review-toolkit:code-reviewer` agent
- NEVER review code manually - delegate to the agent
- ALWAYS save the approval hash after review passes (Step 4 commands)
- NEVER skip the approval step
- Hash changes if staged content changes (requires re-review)
