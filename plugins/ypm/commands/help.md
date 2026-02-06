---
description: "Show detailed YPM help with all available commands and skills"
---

<!-- Language Handling: Check ~/.ypm/config.yml for settings.language -->
<!-- If language is not "en", translate all output to that language -->

# YPM (Your Project Manager) - Help

## Overview

YPM monitors multiple projects in configured directories and centralizes progress management.

---

## Available Skills (Auto-triggered)

Skills are automatically activated when you ask related questions in natural language.

| Skill | Trigger Examples |
|-------|-----------------|
| `/ypm:project-status-update` | "update project status", "scan projects", "プロジェクトのステータス更新" |
| `/ypm:next-tasks` | "what should I work on next", "next tasks", "次何やる" |
| `/ypm:active-projects` | "show active projects", "what am I working on", "アクティブなプロジェクト" |
| `/ypm:project-bootstrap` | "create a new project", "bootstrap project", "新しいプロジェクト作成" |
| `/ypm:git-workflow-setup` | "set up git flow", "protect branches", "Gitフロー設定" |

---

## Available Commands (Manual invocation)

### Project Management

#### `/ypm:start`
Show welcome message and quick commands.

#### `/ypm:setup`
Initialize YPM data directory and configuration.

#### `/ypm:open`
Open project in preferred editor.
- Basic: Select from project list
- `<project>`: Open with default editor
- `<project> <editor>`: Open with specific editor
- `--editor`: View/set default editor
- `all`: Show all including ignored
- `add-ignore`/`remove-ignore`: Manage ignore list

---

### Legacy Commands (Redirected to Skills)

These commands still work but redirect to their skill equivalents:

| Legacy Command | Redirects To |
|---------------|--------------|
| `/ypm:update` | `/ypm:project-status-update` |
| `/ypm:next` | `/ypm:next-tasks` |
| `/ypm:active` | `/ypm:active-projects` |
| `/ypm:new` | `/ypm:project-bootstrap` |
| `/ypm:setup-gitflow` | `/ypm:git-workflow-setup` |

---

### Security & Export

#### `/ypm:export-community`
Export private repository to public community version.
- Interactive setup on first run
- Automatic export on subsequent runs
- TruffleHog security scan integration

#### `/ypm:trufflehog-scan`
Run TruffleHog security scan on all managed projects.

---

### Help

#### `/ypm:help`
Show this help message.

---

## YPM Principles

### Read-Only
YPM monitors other projects in **read-only** mode. Only YPM's own files can be modified.

### Role Separation
- **YPM**: Project monitoring, progress management, new project setup support
- **Each Project**: Implementation, development, testing (in dedicated Claude Code sessions)

---

## Reference Documents

- **CLAUDE.md** - YPM project instructions
- **config.example.yml** - Configuration file sample

---

## Common Usage

### 1. Session Start
```
/ypm:start
```
Show welcome message to see available options.

### 2. Check Project Status
Say "update project status" or use `/ypm:project-status-update`.

### 3. Find Next Task
Say "what should I work on next" or use `/ypm:next-tasks`.

### 4. Start New Project
Say "create a new project" or use `/ypm:project-bootstrap`.

---

## License

YPM is licensed under the **MIT License**.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.

See [LICENSE](https://github.com/signalcompose/YPM/blob/main/LICENSE) for full details.

---

**Manage your projects efficiently with YPM!**
