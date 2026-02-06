---
name: project-bootstrap
description: |
  This skill launches an interactive 8-phase new project setup wizard.
  Use when the user asks "create a new project", "start a project",
  "bootstrap project", "set up a new repo", "initialize project",
  "新しいプロジェクト作成", "プロジェクトを始める", or "プロジェクト立ち上げ".
user-invocable: true
---

# Project Bootstrap Wizard

This skill guides you through an **interactive 8-phase project setup wizard**. It handles everything from initial planning to a fully configured, development-ready project.

## Core Principles

1. **Follow the phases strictly** - Execute Phase 1 through 8 in order. Do not skip or abbreviate any phase.
2. **Bootstrap only, no implementation** - YPM prepares the project. No application code, test code, or implementation is created.
3. **Safety first** - Avoid destructive operations. Always confirm with the user before proceeding at each phase boundary.
4. **Progress visualization** - Display progress at the start of each phase using this format:
   ```
   ## [Project Name] - Bootstrap Progress

   ✅ Phase 1: Project Planning
   🔄 Phase 2: Directory Creation  ← Current
   ⏳ Phase 3: Documentation Setup
   ⏳ Phase 4: GitHub Integration
   ⏳ Phase 5: Git Workflow Setup
   ⏳ Phase 6: Environment Configuration
   ⏳ Phase 7: Documentation Rules
   ⏳ Phase 8: CLAUDE.md & Final Check
   ```
5. **Efficiency** - Use templates, minimize unnecessary dialog, gather information effectively.

## Phase Overview

| Phase | Name | Key Actions |
|-------|------|-------------|
| 1 | Project Planning | Requirements gathering, tech stack selection |
| 2 | Directory Creation | Local directory, git init, initial README |
| 3 | Documentation Setup | docs/ structure, DDD/TDD/DRY principles |
| 4 | GitHub Integration | Repository creation, initial push |
| 5 | Git Workflow Setup | Branch strategy, protection rules, worktree |
| 6 | Environment Config | .gitignore, .claude/settings.json |
| 7 | Documentation Rules | Update policies, onboarding, PR templates |
| 8 | CLAUDE.md & Final | Project CLAUDE.md, final review, completion |

## How to Execute

For each phase, read the corresponding reference file to get detailed instructions:

- **Phase 1**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-1-planning.md`
- **Phase 2**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-2-directory.md`
- **Phase 3**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-3-documentation.md`
- **Phase 4**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-4-github.md`
- **Phase 5**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-5-gitflow.md`
- **Phase 6**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-6-environment.md`
- **Phase 7**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-7-doc-rules.md`
- **Phase 8**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-8-claude-md.md`

**Additional references** (load as needed during relevant phases):
- **Settings JSON template**: `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/settings-json-template.md`
- **.gitignore templates**: `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/gitignore-templates.md`

## Phase Transition Protocol

At the end of each phase:

1. Verify all phase completion criteria are met (listed in the reference file)
2. Report completed artifacts to the user
3. Ask: "Phase N is complete. Proceed to Phase N+1?"
4. **Wait for user approval** before reading the next phase reference and continuing

## After All Phases Complete

Remind the user:

- YPM's job is done (bootstrap only, no implementation)
- Navigate to the new project directory
- Start a new Claude Code session there
- Follow the CLAUDE.md instructions to begin development
- YPM will automatically detect the project on next `/ypm:project-status-update`
