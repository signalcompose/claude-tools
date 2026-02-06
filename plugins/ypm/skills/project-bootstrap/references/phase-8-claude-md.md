# Phase 8: CLAUDE.md & Final Check

**Progress Display**:
```
✅ Phase 1: Project Planning
✅ Phase 2: Directory Creation
✅ Phase 3: Documentation Setup
✅ Phase 4: GitHub Integration
✅ Phase 5: Git Workflow Setup
✅ Phase 6: Environment Configuration
✅ Phase 7: Documentation Rules
🔄 Phase 8: CLAUDE.md & Final Check  ← Current
```

## Steps

### 1. Create CLAUDE.md

Create the project-specific CLAUDE.md. **Recommended**: Write in English (leverage Claude Code 2.1.0+ language settings).

Include the following sections:
- Project overview
- Tech stack
- Development principles (DDD, TDD, DRY)
- Session start procedures
- **Git Workflow (detailed procedure)** - Include absolute prohibitions:
  - No reverse flow (main -> develop)
  - No direct commits to main/develop
  - No squash merge (destroys Git Flow history)
  - No branch names without ISSUE numbers
- **Commit/PR/ISSUE conventions (language rules emphasized)**:
  - Title (line 1): Always English (Conventional Commits)
  - Body (line 2+): Always Japanese (or user's chosen language)
- **Language settings explanation** (Claude Code 2.1.0+):
  - CLAUDE.md in English for stability/performance
  - Claude responses in user's language via `"language"` setting
  - Set in `.claude/settings.json` (user setting)
- Directory structure
- Implementation approach
- Troubleshooting
- Reference resources

### 2. Review CLAUDE.md

- Show the created CLAUDE.md to the user
- Ask: "Is this CLAUDE.md content acceptable?"
- Important note to user: "CLAUDE.md changes should be made while consulting Claude Code in each project, or edited manually. Adjust as needed for project-specific requirements."

### 3. Additional Rules Check

Ask: "Are there any other rules or settings you'd like to add?"

### 4. Final Commit & Push

- Commit all changes
- Push to GitHub

### 5. Setup Completion

Confirm:
- Project is in a development-ready state

Present next steps:

```
[Project Name] setup is complete!

Important: YPM's work ends here.

YPM only handles preparation. It does not create implementation or test code.

Next steps:
1. Navigate to project directory: cd [path]
2. Start a new Claude Code session
3. Follow CLAUDE.md instructions to begin development:
   - DDD principle: Start from documentation
   - TDD principle: Write tests first
   - Create the first ISSUE
   - Branch from develop for development

Implementation should be done in each project.
```

## Completion Criteria

Verify all of the following:
- [ ] CLAUDE.md created and reviewed by user
- [ ] All changes committed
- [ ] Pushed to GitHub
- [ ] Project is in development-ready state

## Final Report

Report to user:

"All 8 phases of bootstrap are complete!

[Project Name] is ready for development.

Created artifacts:
- Project directory and Git repository
- docs/ base documentation
- GitHub repository (Private)
- Git Workflow settings (develop/main, branch protection)
- Environment config (.gitignore, .claude/settings.json)
- Documentation rules (PR template, etc.)
- CLAUDE.md

Important: YPM's work ends here.
Implementation should be done in each project.

Next steps:
1. Navigate to project directory: cd [path]
2. Start a new Claude Code session
3. Follow CLAUDE.md instructions to begin development"
