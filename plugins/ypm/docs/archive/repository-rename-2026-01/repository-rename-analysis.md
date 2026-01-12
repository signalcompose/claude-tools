# Repository Rename Analysis: YPM → your-project-manager

**Date**: 2026-01-10
**Author**: Hiroshi Yamato (with Claude Sonnet 4.5)
**Current Repository**: `signalcompose/YPM`
**Proposed Repository**: `signalcompose/your-project-manager`

---

## Executive Summary

This document provides a comprehensive analysis of renaming the YPM GitHub repository from `signalcompose/YPM` to `signalcompose/your-project-manager` to resolve a critical macOS installation issue with Claude Code.

**Key Findings**:
- ✅ **16 URL references** require updates across 9 files
- ✅ `.claude-plugin/plugin.json` is **critical** - directly affects marketplace registration
- ✅ GitHub automatic redirect provides **1-year grace period** for migration
- ⚠️ **Case sensitivity issue** currently blocks macOS users from installing the plugin

**Recommended Action**: Proceed with rename to `your-project-manager`
- **Benefits**: Solves case sensitivity issue, more descriptive, better SEO
- **Risks**: Minimal due to GitHub redirects and controlled migration plan
- **Timeline**: 5-phase migration over 2-3 weeks

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Problem Description](#problem-description)
3. [Proposed Change Details](#proposed-change-details)
4. [Impact Analysis](#impact-analysis)
5. [Migration Strategy](#migration-strategy)
6. [Risk Assessment](#risk-assessment)
7. [Recommendations](#recommendations)
8. [Appendix](#appendix)

---

## Current State Analysis

### Repository Information

**GitHub Repository**:
- Name: `signalcompose/YPM`
- Created: 2025-11-11
- Stars: 0 (target: 5+ for claudemarketplaces.com detail page)
- Description: "Signal Compose YPM - Multi-project progress tracking"

**Claude Code Plugin**:
- Plugin name: `ypm` (lowercase)
- Marketplace name: `signalcompose-ypm` (lowercase, hyphenated)
- Commands: `/ypm:setup`, `/ypm:update`, `/ypm:next`, etc.

**Current URLs**:
- Repository: `https://github.com/signalcompose/YPM`
- Issues: `https://github.com/signalcompose/YPM/issues`
- Security: `https://github.com/signalcompose/YPM/security/advisories/new`

### Marketplace Registration Status

**claudemarketplaces.com**:
- ✅ Indexed in search results
- ❌ Detail page: 404 (requires 5+ stars)
- ⚠️ Recommended command: `/plugin marketplace add signalcompose/YPM` (fails on macOS)
- ✅ Working command: `/plugin marketplace add signalcompose/ypm` (lowercase)

**Claude Code Installation**:
```bash
# Fails on macOS
/plugin marketplace add signalcompose/YPM
# Error: Failed to finalize marketplace cache. ENOENT

# Works on macOS
/plugin marketplace add signalcompose/ypm
```

---

## Problem Description

### Technical Issue

**Symptom**: macOS users cannot install YPM using the repository name shown in search results

**Root Cause**:
1. GitHub repository uses uppercase: `signalcompose/YPM`
2. Claude Code clones to: `~/.claude/plugins/marketplaces/signalcompose-YPM`
3. Claude Code attempts rename: `signalcompose-YPM` → `signalcompose-ypm`
4. macOS APFS filesystem treats these as identical paths (case-insensitive)
5. `rename()` system call fails with `ENOENT` error

**Impact**: Installation blocks approximately 50% of potential users (macOS market share)

### User Experience Issue

**Current Flow** (broken):
```
User searches "YPM" on claudemarketplaces.com
  ↓
Sees result: "signalcompose/YPM"
  ↓
Copies command: /plugin marketplace add signalcompose/YPM
  ↓
Runs command in Claude Code
  ↓
❌ Error: Failed to finalize marketplace cache
```

**Required Workaround** (not obvious):
```
User must manually change to lowercase: /plugin marketplace add signalcompose/ypm
```

---

## Proposed Change Details

### Option Analysis

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **your-project-manager** | ✅ Descriptive<br>✅ No case issues<br>✅ Better SEO | ⚠️ Longer to type | ⭐ **Recommended** |
| **ypm** (lowercase) | ✅ Short<br>✅ No case issues | ❌ Too generic<br>❌ Poor discoverability | Not recommended |
| **YPM** (keep current) | ✅ Brand continuity | ❌ Issue persists<br>❌ Blocks macOS users | Not viable |

### Selected Option: `your-project-manager`

**Rationale**:
1. **Solves case sensitivity issue completely**: All lowercase, no APFS conflicts
2. **More descriptive**: Users understand purpose immediately
3. **Better SEO**: Matches search terms "project manager", "your projects"
4. **Professional**: Aligns with open-source naming conventions
5. **Unique**: Less collision with existing projects

**New URLs**:
- Repository: `https://github.com/signalcompose/your-project-manager`
- Issues: `https://github.com/signalcompose/your-project-manager/issues`
- Security: `https://github.com/signalcompose/your-project-manager/security/advisories/new`

**Plugin remains unchanged**:
- Plugin name: `ypm` (maintains brand continuity)
- Commands: `/ypm:*` (no user retraining needed)
- Marketplace: `signalcompose-ypm` (already lowercase)

---

## Impact Analysis

### Files Requiring Updates

**Total**: 16 URL references across 9 files

#### Critical - Must Update (9 files, 16 references)

##### 1. `README.md` (3 references)
**File**: `/Users/yamato/Src/proj_ypm/YPM/README.md`

- **Line 198**: Development setup clone URL
  ```markdown
  git clone https://github.com/signalcompose/YPM.git
  ```
  → Change to: `https://github.com/signalcompose/your-project-manager.git`

- **Line 216**: Contributing section repository link
  ```markdown
  - **Repository**: [signalcompose/YPM](https://github.com/signalcompose/YPM)
  ```
  → Change to: `[signalcompose/your-project-manager](https://github.com/signalcompose/your-project-manager)`

- **Line 217**: Issues link
  ```markdown
  - **Bug reports & feature requests**: [GitHub Issues](https://github.com/signalcompose/YPM/issues)
  ```
  → Change to: `https://github.com/signalcompose/your-project-manager/issues`

##### 2. `SECURITY.md` (1 reference)
**File**: `/Users/yamato/Src/proj_ypm/YPM/SECURITY.md`

- **Line 8**: Security advisory URL
  ```markdown
  https://github.com/signalcompose/YPM/security/advisories/new
  ```
  → Change to: `https://github.com/signalcompose/your-project-manager/security/advisories/new`

##### 3. `.claude-plugin/plugin.json` (2 references) ⚠️ **CRITICAL**
**File**: `/Users/yamato/Src/proj_ypm/YPM/.claude-plugin/plugin.json`

- **Line 10**: Homepage field
  ```json
  "homepage": "https://github.com/signalcompose/YPM"
  ```
  → Change to: `"homepage": "https://github.com/signalcompose/your-project-manager"`

- **Line 11**: Repository field
  ```json
  "repository": "https://github.com/signalcompose/YPM"
  ```
  → Change to: `"repository": "https://github.com/signalcompose/your-project-manager"`

**Impact**: This file directly affects marketplace registration. Must be updated immediately after rename.

##### 4. `scripts/export-to-public.sh` (2 references)
**File**: `/Users/yamato/Src/proj_ypm/YPM/scripts/export-to-public.sh`

- **Line 5**: Public repository URL variable
  ```bash
  PUBLIC_REPO_URL="https://github.com/signalcompose/YPM.git"
  ```
  → Change to: `PUBLIC_REPO_URL="https://github.com/signalcompose/your-project-manager.git"`

- **Line 58**: Verification URL
  ```bash
  echo "https://github.com/signalcompose/YPM"
  ```
  → Change to: `echo "https://github.com/signalcompose/your-project-manager"`

##### 5. `commands/help.md` (1 reference)
**File**: `/Users/yamato/Src/proj_ypm/YPM/commands/help.md`

- **Line 147**: LICENSE link
  ```markdown
  [LICENSE](https://github.com/signalcompose/YPM/blob/main/LICENSE)
  ```
  → Change to: `https://github.com/signalcompose/your-project-manager/blob/main/LICENSE`

##### 6. `docs/guide-en.md` (3 references)
**File**: `/Users/yamato/Src/proj_ypm/YPM/docs/guide-en.md`

- **Line 67**: Old installation command (outdated)
  ```markdown
  /plugin marketplace add signalcompose/YPM
  ```
  → Change to: `/plugin marketplace add signalcompose/ypm`
  (Note: Lowercase for consistency)

- **Line 555**: FAQ installation example
  ```markdown
  /plugin marketplace add signalcompose/YPM
  ```
  → Change to: `/plugin marketplace add signalcompose/ypm`

- **Line 597**: Issues link
  ```markdown
  https://github.com/signalcompose/YPM/issues
  ```
  → Change to: `https://github.com/signalcompose/your-project-manager/issues`

##### 7. `docs/guide-ja.md` (1 reference)
**File**: `/Users/yamato/Src/proj_ypm/YPM/docs/guide-ja.md`

- **Line 594**: Issues link
  ```markdown
  https://github.com/signalcompose/YPM/issues
  ```
  → Change to: `https://github.com/signalcompose/your-project-manager/issues`

##### 8. `docs/research/private-to-public-strategy.md` (4 references)
**File**: `/Users/yamato/Src/proj_ypm/YPM/docs/research/private-to-public-strategy.md`

- Internal research document with multiple references
- Update all URL instances for consistency

##### 9. `docs/development/global-export-system.md` (3 references)
**File**: `/Users/yamato/Src/proj_ypm/YPM/docs/development/global-export-system.md`

- Internal development documentation
- Update all URL instances for consistency

##### 10. `templates/scripts/export-to-community.sh` (1 reference)
**File**: `/Users/yamato/Src/proj_ypm/YPM/templates/scripts/export-to-community.sh`

- Template script file
- Update example URL

#### Not Requiring Updates

**Files with "YPM" as project name (not URLs)**:
- All files: "YPM" as brand name in titles, descriptions → **Keep as-is**
- Commands: `/ypm:*` pattern → **No changes needed**
- Config files: `.ypm` directory references → **No changes needed**

**User-specific configuration files (templates only)**:
- `.export-config.yml.example` → User-configured, no changes
- `config.example.yml` → Example file, user customizes

---

## Migration Strategy

### Five-Phase Approach

#### Phase 1: Preparation (This PR) - **Current Phase**

**Objective**: Warn users and prepare migration documentation

**Tasks**:
- [x] Add warning to README.md about case sensitivity
- [x] Create comprehensive analysis report (this document)
- [ ] Create Issue draft for claudemarketplaces.com
- [ ] Create bug report draft for Claude Code
- [ ] Commit and create PR for review

**Duration**: 1 day
**Risk**: None (documentation only)

---

#### Phase 2: GitHub Repository Rename

**Objective**: Execute the rename on GitHub

**Tasks**:
1. Navigate to Repository Settings
2. Change name from `YPM` to `your-project-manager`
3. Confirm automatic redirect setup (GitHub provides 1-year redirect)
4. Update local git remote:
   ```bash
   git remote set-url origin https://github.com/signalcompose/your-project-manager.git
   ```
5. Verify redirect works:
   ```bash
   curl -I https://github.com/signalcompose/YPM
   # Should show 301 redirect
   ```

**Duration**: 30 minutes
**Risk**: Low (GitHub handles redirects automatically)

---

#### Phase 3: Code Updates

**Objective**: Update all 19 URL references in code

**Tasks**:
1. Create new feature branch: `feature/update-repository-urls`
2. Update all 10 files (see Impact Analysis)
3. Priority order:
   - **First**: `.claude-plugin/plugin.json` (CRITICAL)
   - **Second**: README.md, SECURITY.md
   - **Third**: Documentation files
   - **Fourth**: Scripts and templates
4. Test all updated URLs manually
5. Verify no broken links

**Automation Option**:
```bash
# Automated URL replacement (verify manually afterwards)
find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.sh" \) \
  -exec sed -i '' 's|signalcompose/YPM|signalcompose/your-project-manager|g' {} +
```

**Manual Verification Required**: Always review changes to ensure:
- No unintended replacements
- Proper URL formatting
- Markdown link syntax intact

**Duration**: 2-3 hours
**Risk**: Medium (manual verification reduces error risk)

---

#### Phase 4: Marketplace Update

**Objective**: Ensure plugin installation works with new repository name

**Tasks**:
1. Verify `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "signalcompose-ypm",
     "description": "Signal Compose YPM - Multi-project progress tracking"
   }
   ```
   (Already lowercase, no changes needed)

2. Test installation with new URL:
   ```bash
   # Should work (lowercase)
   /plugin marketplace add signalcompose/ypm

   # Should also work after rename (lowercase)
   /plugin marketplace add signalcompose/your-project-manager
   ```

3. Verify plugin detection:
   ```bash
   /plugin list
   # Should show: ypm
   ```

4. Test all commands:
   ```bash
   /ypm:help
   /ypm:start
   ```

**Duration**: 1 hour
**Risk**: Low (marketplace name already lowercase)

---

#### Phase 5: Rollout & Communication

**Objective**: Inform users and complete migration

**Tasks**:
1. **PR Review & Merge**:
   - Create PR: `feature/update-repository-urls` → `develop`
   - Review all changes
   - Merge to `develop`
   - Create PR: `develop` → `main`
   - Merge to `main`

2. **Release**:
   - Tag new version (e.g., `v1.4.0`)
   - Create GitHub Release with migration notes:
     ```markdown
     ## What's Changed
     - Repository renamed to `signalcompose/your-project-manager`
     - Installation: Use `/plugin marketplace add signalcompose/ypm` (lowercase)
     - Old URL automatically redirects (1 year)

     ## Breaking Changes
     None - all commands remain the same
     ```

3. **User Communication**:
   - Update README.md with migration notice (temporary, 1 month)
   - Add to `/ypm:start` welcome message
   - Announce on social media (if applicable)

4. **Submit Issues**:
   - Submit to claudemarketplaces.com (using draft)
   - Submit to Claude Code (using draft)

**Duration**: 2-3 hours
**Risk**: Low (clear communication reduces confusion)

---

### Total Migration Timeline

- **Phase 1** (Preparation): 1 day → **Current**
- **Phase 2** (Rename): 30 minutes → After approval
- **Phase 3** (Code updates): 1 day → After rename
- **Phase 4** (Testing): 1 day → After updates
- **Phase 5** (Rollout): 1 day → After testing

**Total Duration**: 4-5 days (actual work)
**Calendar Duration**: 2-3 weeks (including reviews and approvals)

---

## Risk Assessment

### Risk Matrix

| Risk ID | Description | Severity | Probability | Mitigation | Recovery |
|---------|-------------|----------|-------------|------------|----------|
| R1 | Plugin installation fails after rename | HIGH | MEDIUM | GitHub auto-redirect (1 year) | Use old URL temporarily |
| R2 | Marketplace delists plugin | MEDIUM | LOW | Update plugin.json immediately | Re-submit to marketplace |
| R3 | User confusion | MEDIUM | MEDIUM | Clear communication, release notes | FAQ and support |
| R4 | Documentation links break | LOW | LOW | GitHub redirects handle | Manual redirect notices |
| R5 | git clone fails | LOW | LOW | GitHub redirects handle | Update URLs |

### Risk Detail

#### R1: Plugin Installation Fails After Rename
- **Severity**: HIGH (blocks new users)
- **Probability**: MEDIUM (depends on marketplace caching)
- **Impact**: New users cannot install plugin
- **Mitigation**:
  - GitHub provides automatic redirects for 1 year
  - Test both old and new URLs before announcement
  - Keep lowercase marketplace name (`signalcompose-ypm`) unchanged
- **Recovery**:
  - Users can use old URL: `/plugin marketplace add signalcompose/ypm`
  - Old URL redirects to new repository
  - Worst case: Revert rename (GitHub allows)

#### R2: Marketplace Delists Plugin
- **Severity**: MEDIUM (temporary disruption)
- **Probability**: LOW (marketplace scans GitHub regularly)
- **Impact**: Plugin not discoverable in search
- **Mitigation**:
  - Update `.claude-plugin/plugin.json` immediately after rename
  - Commit and push before announcing
  - Wait for marketplace re-scan (1-hour cycle)
- **Recovery**:
  - Manually trigger re-scan (if supported)
  - Contact claudemarketplaces.com maintainer
  - Direct installation still works

#### R3: User Confusion
- **Severity**: MEDIUM (support burden)
- **Probability**: MEDIUM (some users will be surprised)
- **Impact**: Increased support questions
- **Mitigation**:
  - Clear migration notice in README
  - Release notes explain why
  - Update `/ypm:start` with notice (temporary)
  - Social media announcement
- **Recovery**:
  - FAQ entry for migration
  - Support template responses
  - Migration guide link

#### R4: Documentation Links Break
- **Severity**: LOW (minor inconvenience)
- **Probability**: LOW (GitHub handles redirects)
- **Impact**: External links to docs may break
- **Mitigation**:
  - GitHub redirects handle most cases
  - Update all internal links (Phase 3)
  - Test all documentation URLs
- **Recovery**:
  - Add redirect notices to old docs
  - Update external references manually

#### R5: git clone Fails
- **Severity**: LOW (rare case)
- **Probability**: LOW (GitHub redirects work)
- **Impact**: Developers cannot clone
- **Mitigation**:
  - GitHub redirects `git clone` automatically
  - Update all documentation
  - Test clone with both URLs
- **Recovery**:
  - Provide new URL in error message
  - Update documentation immediately

---

## Recommendations

### Immediate Actions (This PR)

- [x] **Add README warning** about case sensitivity ✅ **COMPLETED**
- [x] **Create comprehensive analysis** (this document) ✅ **COMPLETED**
- [ ] **Create Issue drafts** for claudemarketplaces.com and Claude Code
- [ ] **Review and merge** this preparation PR

**Rationale**: Warn users immediately while preparing full migration

---

### Do Not Include in This PR

- ❌ **Do not rename** the repository (requires user approval first)
- ❌ **Do not update** URL references (wait for rename completion)
- ❌ **Do not modify** `.claude-plugin/plugin.json` (wait for rename)

**Rationale**: Preparation phase only - keep changes reversible

---

### Post-Approval Actions (Future PRs)

#### After User Approval:
1. **Execute GitHub rename** (Phase 2)
2. **Update all URLs** (Phase 3)
3. **Test marketplace installation** (Phase 4)
4. **Announce migration** (Phase 5)

#### Monitor for 1 Month:
- GitHub star count (target: 5+)
- Installation success rate
- User feedback
- Link integrity

#### Submit External Reports:
- Issue to claudemarketplaces.com
- Bug report to Claude Code / Anthropic

---

## Appendix

### A. Automated Update Script

```bash
#!/bin/bash
# Automated URL replacement script
# WARNING: Review all changes manually after running

set -e

echo "🔄 Updating repository URLs..."

# Backup files first
git status
read -p "Commit all changes before running? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add -A
    git commit -m "checkpoint: before URL updates"
fi

# Replace URLs in markdown files
find . -type f -name "*.md" \
  -not -path "./.git/*" \
  -not -path "./node_modules/*" \
  -exec sed -i '' 's|signalcompose/YPM|signalcompose/your-project-manager|g' {} +

# Replace URLs in JSON files
find . -type f -name "*.json" \
  -not -path "./.git/*" \
  -not -path "./node_modules/*" \
  -exec sed -i '' 's|signalcompose/YPM|signalcompose/your-project-manager|g' {} +

# Replace URLs in shell scripts
find . -type f -name "*.sh" \
  -not -path "./.git/*" \
  -exec sed -i '' 's|signalcompose/YPM|signalcompose/your-project-manager|g' {} +

echo "✅ URL replacement complete"
echo ""
echo "⚠️  CRITICAL: Review all changes with 'git diff' before committing!"
echo "   Pay special attention to .claude-plugin/plugin.json"
```

### B. Manual Verification Checklist

After running automated script:

```bash
# 1. Verify plugin.json
cat .claude-plugin/plugin.json | grep signalcompose

# 2. Count replacements
git diff | grep -c "your-project-manager"
# Expected: 38+ (19 removals + 19 additions)

# 3. Check for unintended replacements
git diff | grep -i ypm | grep -v your-project-manager
# Should only show "/ypm:" commands and "ypm" plugin name

# 4. Test all URLs manually
grep -r "github.com/signalcompose" . --include="*.md" --include="*.json" --include="*.sh" | grep -v node_modules | grep -v ".git"
# All should show "your-project-manager"

# 5. Verify no broken links
# (Use link checker or manual spot checks)
```

### C. Communication Template

**GitHub Release Notes Template**:

```markdown
## 🎉 YPM v1.4.0 - Repository Rename

### What's Changed

**Repository Name Update**:
- Old: `signalcompose/YPM`
- New: `signalcompose/your-project-manager`

**Why the change?**:
This fixes a critical macOS installation issue where uppercase letters in the repository name caused installation failures. The new name is also more descriptive and improves discoverability.

**What you need to do**:
✅ **Nothing!** All existing installations continue working.

**Installation command** (for new users):
```bash
/plugin marketplace add signalcompose/ypm
```

**Note**: Old URLs automatically redirect for 1 year. All `/ypm:*` commands remain unchanged.

### Full Changelog
- docs: add case sensitivity warning to installation instructions
- docs: comprehensive repository rename analysis
- feat: update all repository URLs to new name
- fix: resolve macOS installation issue

**Full Diff**: https://github.com/signalcompose/your-project-manager/compare/v1.3.0...v1.4.0
```

### D. FAQ Entries

**Q: Why did the repository name change?**
A: The uppercase "YPM" caused installation failures on macOS due to filesystem case-sensitivity issues. "your-project-manager" is lowercase and more descriptive.

**Q: Do I need to reinstall the plugin?**
A: No. Existing installations continue working without any changes.

**Q: Will my commands break?**
A: No. All `/ypm:*` commands remain exactly the same.

**Q: What about old links to the repository?**
A: GitHub automatically redirects `signalcompose/YPM` to `signalcompose/your-project-manager` for 1 year.

**Q: Can I still use the old installation command?**
A: Yes, but use lowercase: `/plugin marketplace add signalcompose/ypm`

---

## Conclusion

Renaming the repository from `signalcompose/YPM` to `signalcompose/your-project-manager` is the recommended solution to resolve the macOS installation issue and improve overall user experience.

**Key Benefits**:
- ✅ Fixes blocking issue for macOS users (~50% of potential users)
- ✅ More descriptive and professional name
- ✅ Better SEO and discoverability
- ✅ Maintains plugin brand (`ypm` commands unchanged)

**Migration is low-risk** due to:
- GitHub automatic redirects (1 year)
- Controlled 5-phase rollout
- No impact on existing users
- Clear communication plan

**Recommended Timeline**:
- **Phase 1** (This PR): Documentation and warnings → **1 day**
- **Phase 2-5** (Future PR): Rename and updates → **2-3 weeks**

---

**Next Steps**: Review this analysis, approve migration plan, and proceed with Phase 2 (GitHub rename) after merging this preparation PR.

**Document Version**: 1.0
**Last Updated**: 2026-01-10
