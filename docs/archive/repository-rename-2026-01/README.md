# Repository Rename Archive - January 2026

This directory contains historical documentation related to the repository rename from `signalcompose/YPM` to `signalcompose/ypm`.

## Rename Summary

- **Date**: January 10, 2026
- **Old Name**: `signalcompose/YPM`
- **New Name**: `signalcompose/ypm`
- **Reason**: Resolve macOS APFS case sensitivity issue preventing plugin installation

## Documents

### 1. repository-rename-analysis.md
Comprehensive analysis document that initially proposed renaming to `your-project-manager` but ultimately we chose `ypm` for:
- Simplicity and brevity
- Consistency with marketplace name (`signalcompose-ypm`)
- Brand continuity

### 2. claude-code-bug-report-draft.md
Technical bug report draft for Claude Code/Anthropic regarding the case sensitivity issue with `rename()` system call on macOS APFS.

### 3. claudemarketplaces-issue-draft.md
Issue draft for claudemarketplaces.com regarding case sensitivity handling in plugin installation commands.

## Outcome

The rename was successfully completed:
- ✅ Repository renamed to `ypm` (all lowercase)
- ✅ GitHub automatic redirect active (1-year grace period)
- ✅ Installation command: `/plugin marketplace add signalcompose/ypm`
- ✅ macOS case sensitivity issue resolved
- ✅ Marketplace auto-discovery will update within 24 hours

## Related PRs

- PR #31: Preparation work (warning, analysis, issue drafts)
