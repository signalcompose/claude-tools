---
description: "Show YPM welcome message and quick commands"
---

<!-- Language Handling: Check ~/.ypm/config.yml for settings.language -->
<!-- If language is not "en", translate all output to that language -->

**YPM (Your Project Manager)** - Multi-project progress tracking system.

This system monitors multiple projects in configured directories and centralizes progress management.

**Key Features**:
- Automatic information collection from Git history and documentation
- Organize next tasks and priorities

**Natural Language (say these to auto-trigger)**:
1. **"Update project status"** - Scan all projects and update `PROJECT_STATUS.md`
2. **"What's the next task?"** - Show next actions for active projects
3. **"Show active projects"** - View recently updated projects
4. **"Create a new project"** - Launch the 8-phase project setup wizard
5. **"Set up git flow"** - Configure branch protection and workflow

**Skills** (use `ypm:` prefix):
- `/ypm:project-status-update` - Update project status
- `/ypm:next-tasks` - Show next tasks
- `/ypm:active-projects` - Show active projects
- `/ypm:project-bootstrap` - Project setup wizard
- `/ypm:git-workflow-setup` - Git workflow setup

**Commands** (use `ypm:` prefix):
- `/ypm:start` - Show this welcome message
- `/ypm:help` - Show detailed help
- `/ypm:setup` - Initial setup
- `/ypm:open` - Open project in editor
- `/ypm:export-community` - Export to community version
- `/ypm:trufflehog-scan` - Security scan

What would you like to do?

---

*YPM is MIT licensed. Provided "AS IS" without warranty. See `/ypm:help` for details.*
