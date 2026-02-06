---
name: active-projects
description: |
  This skill displays recently active projects updated within the configured threshold.
  Use when the user asks "show active projects", "what am I working on",
  "recent projects", "current projects",
  "アクティブなプロジェクト", "最近のプロジェクト", or "今やってるプロジェクト".
user-invocable: true
---

<!-- Language Handling: Check ~/.ypm/config.yml for settings.language -->
<!-- If language is not "en", translate all output to that language -->

# Active Projects

Display only active projects updated within 1 week from `~/.ypm/PROJECT_STATUS.md`.

## Prerequisites

- Run `/ypm:setup` first if `~/.ypm/config.yml` doesn't exist
- Run `/ypm:project-status-update` first if `~/.ypm/PROJECT_STATUS.md` doesn't exist

## Display Content

- Project name
- Overview
- Current branch
- Last update date
- Phase
- Implementation progress
- Next task

## Display Format

Show active projects in descending order by update date (newest first).

## Additional Information

- Total count of active projects
- Most progressed project
- Most recently updated project
