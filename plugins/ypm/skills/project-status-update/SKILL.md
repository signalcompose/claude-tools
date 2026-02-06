---
name: project-status-update
description: |
  This skill scans all monitored projects and updates PROJECT_STATUS.md.
  Use when the user asks "update project status", "scan projects",
  "refresh status", "check all projects", "what changed in my projects",
  "プロジェクトのステータス更新", "プロジェクトをスキャン", or "全プロジェクトの状態確認".
user-invocable: true
---

<!-- Language Handling: Check ~/.ypm/config.yml for settings.language -->
<!-- If language is not "en", translate all output to that language -->

# Project Status Update

Scan all projects and update `~/.ypm/PROJECT_STATUS.md`.

## Prerequisites

- Run `/ypm:setup` first if `~/.ypm/config.yml` doesn't exist

## Execution Steps

1. Check that `~/.ypm/config.yml` exists. If not, prompt user to run `/ypm:setup`
2. Find the YPM plugin directory and run `python ${CLAUDE_PLUGIN_ROOT}/scripts/scan_projects.py` to collect project information
   - Git worktree detection (.git file/directory)
   - Project classification (active/developing/inactive)
3. Read scan results (JSON format)
4. Collect detailed info from `CLAUDE.md` for active projects
5. Update `~/.ypm/PROJECT_STATUS.md` in human-readable format
   - Add "(Git worktree)" to project name for worktrees
6. Complete

## Important

This skill does **NOT** perform Git operations. `~/.ypm/PROJECT_STATUS.md` is updated as a local file only.

## Notes

- Other project files are read-only (modification prohibited)
- Only YPM's own files can be modified
- Scan script automatically detects new projects
- PROJECT_STATUS.md is not Git-managed (daily operational task)

## CRITICAL: Accuracy Requirements

- **"Next task" should ONLY be obtained from**:
  - GitHub Issues (`gh issue list` command)
  - Latest commit messages
  - Content explicitly stated in project's CLAUDE.md, README.md
- **NEVER do**:
  - Create non-existent features or plans
  - Mark unimplemented features as "in progress"
  - Guess "next tasks" not documented
- **When unknown**: Honestly write "unknown", "not documented", or "no GitHub Issue found"
