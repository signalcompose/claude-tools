# Phase 5: Git Workflow Setup

**Progress Display**:
```
✅ Phase 1: Project Planning
✅ Phase 2: Directory Creation
✅ Phase 3: Documentation Setup
✅ Phase 4: GitHub Integration
🔄 Phase 5: Git Workflow Setup  ← Current
⏳ Phase 6: Environment Configuration
⏳ Phase 7: Documentation Rules
⏳ Phase 8: CLAUDE.md & Final Check
```

## Steps

### 1. Workflow Necessity Check

Ask: "Do you want to introduce Git Flow? (Recommended for multi-person development)"

### 2. If Introducing Git Flow

#### 2.1 Set Default Branch to `develop`

```bash
gh api repos/:owner/:repo -X PATCH -f default_branch=develop
```

Reason: `main` is for releases (production), `develop` is for development work.

#### 2.2 Development Style Selection

Ask the user:

```
Select your development style:

1. Solo Development (recommended)
   - You develop alone
   - Admin bypass enabled
   - Review recommended but not enforced

2. Team Development
   - Multiple developers
   - Admin also subject to protection rules
   - Review required
```

#### 2.3 Branch Protection Rules

**Important design principle**: Git Flow requires merge commits. Set `required_linear_history: false` (squash merge prohibited).

Use the branch protection templates from:
- Solo: `${CLAUDE_PLUGIN_ROOT}/templates/.github/branch-protection/solo-development.json`
- Team: `${CLAUDE_PLUGIN_ROOT}/templates/.github/branch-protection/team-development.json`

Apply to both `main` and `develop` branches:

```bash
# Apply protection (example for main)
gh api repos/:owner/:repo/branches/main/protection \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  --input <protection-json-file>
```

**Solo development notes**:
- `enforce_admins: false` - Admin can bypass
- Review settings present but bypassable
- Easy transition to team development later

**Team development notes**:
- `enforce_admins: true` - Everyone follows rules
- Reviews are mandatory for all

#### 2.4 Repository-Level Merge Settings (REQUIRED)

Disable squash and rebase merge at repository level:

```bash
gh api repos/:owner/:repo \
  -X PATCH \
  -f allow_squash_merge=false \
  -f allow_rebase_merge=false \
  -f allow_merge_commit=true
```

**Why**: Branch protection controls linear history, but repository settings control which merge methods are available. Both must be set to prevent squash merge in PRs.

### 3. Git Worktree (Optional)

Ask: "Do you want to use Git Worktree?"

**If yes**:
- Main (develop): project directory as-is
- main worktree: `[project-name]_main/` (release, read-only)

```bash
cd /path/to/project
git worktree add ../[project-name]_main main
```

**If no**: Use normal branch switching.

### 4. Workflow Rules

- Always create an ISSUE before working
- Branch from `develop` by default
- If already on a working branch, confirm branching point

### 5. Naming Conventions

- Commit/PR/ISSUE title: English
- Body: Ask user preference (Japanese or English)

## Post-Setup Verification

Execute and show results to user:

```bash
# Default branch
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'

# Branch protection
gh api repos/:owner/:repo/branches/main/protection
gh api repos/:owner/:repo/branches/develop/protection

# Worktree (if configured)
git worktree list
```

## Completion Criteria

Verify all of the following:
- [ ] Default branch set to `develop` (verified)
- [ ] main/develop branch protection configured (verified)
- [ ] Git Worktree set up (if chosen, verified)
- [ ] Workflow rules established

## Completion Report

Report to user:

"Phase 5 (Git Workflow Setup) is complete.

Configured:
- Default branch: develop
- Branch protection: main/develop
- Git Worktree: [configuration if applicable]
- Commit/PR/ISSUE naming: [title English / body preference]

Proceed to Phase 6 (Environment Configuration)?"

**Wait for user approval before proceeding.**
