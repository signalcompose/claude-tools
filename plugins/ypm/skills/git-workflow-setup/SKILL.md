---
name: git-workflow-setup
description: |
  This skill configures Git Flow or GitHub Flow with branch protection and security settings.
  Use when the user asks "set up git flow", "configure branch protection",
  "set up git workflow", "protect branches",
  "Gitフロー設定", "ブランチ保護設定", or "ワークフロー設定".
user-invocable: true
---

# Git Workflow Setup

This skill configures a complete Git workflow for your project, including branch structure, branch protection, merge settings, and security configuration.

## What This Skill Does

1. **Project Type Selection** - Determine security level (Personal / Small OSS / Large OSS)
2. **Development Style Selection** - Solo or Team development
3. **Repository Check** - Verify or create GitHub repository
4. **Branch Structure** - Create main and develop branches
5. **Branch Protection** - Apply protection rules using templates
6. **Merge Settings** - Disable squash/rebase merge (merge commit only for Git Flow)
7. **Security Settings** - CODEOWNERS, Secret Scanning (based on project type)
8. **Verification** - Confirm all settings are correct

## Execution Steps

### Step 0: Project Type & Development Style

Ask the user about their project type to determine appropriate security settings:

| Setting | Personal | Small OSS | Large OSS |
|---------|----------|-----------|-----------|
| Visibility | Private | Public | Public |
| Secret Scanning | Not needed | Recommended | Required |
| CODEOWNERS | Not needed | Recommended | Required |
| develop protection | Optional | Recommended | Required |
| Fork PR restriction | Not needed | Optional | Recommended |

Then ask development style:
- **Solo Development** - `enforce_admins=false` (admin bypass allowed)
- **Team Development** - `enforce_admins=true` (all rules apply to everyone)

### Step 1: Repository Check

```bash
git remote -v
gh repo view --json nameWithOwner,isPrivate,defaultBranchRef 2>/dev/null
```

If no repository exists, guide the user to create one first.

### Step 2: Branch Structure

Create `develop` branch if it doesn't exist, push to remote, and verify the default branch.

### Step 3: Branch Protection

Apply branch protection using the template files:
- Solo: `${CLAUDE_PLUGIN_ROOT}/templates/.github/branch-protection/solo-development.json`
- Team: `${CLAUDE_PLUGIN_ROOT}/templates/.github/branch-protection/team-development.json`

Apply to both `main` and `develop` branches using `gh api`.

### Step 4: Repository-Level Merge Settings (REQUIRED)

```bash
gh api repos/:owner/:repo -X PATCH \
  -f allow_squash_merge=false \
  -f allow_rebase_merge=false \
  -f allow_merge_commit=true
```

**Why**: Git Flow requires merge commits. Squash/rebase destroys Git Flow history.

### Step 5: Security Settings

Based on project type, apply appropriate settings.

For CODEOWNERS template, refer to:
`${CLAUDE_PLUGIN_ROOT}/skills/git-workflow-setup/references/codeowners-template.md`

For security settings details, refer to:
`${CLAUDE_PLUGIN_ROOT}/skills/git-workflow-setup/references/security-settings.md`

### Step 6: Verification

```bash
git branch -a
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
gh api repos/:owner/:repo/branches/main/protection
gh api repos/:owner/:repo --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge}'
```

Show results to the user and confirm everything is correct.

## Completion

Report all configured settings and provide next steps for the Git workflow (branching, committing, PR creation).

## Absolute Prohibitions (Git Flow)

- main -> develop reverse flow (MOST IMPORTANT)
- Direct commits to main/develop branches
- Squash merge (destroys Git Flow history)
