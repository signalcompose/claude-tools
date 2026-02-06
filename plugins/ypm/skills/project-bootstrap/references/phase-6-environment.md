# Phase 6: Environment Configuration

**Progress Display**:
```
✅ Phase 1: Project Planning
✅ Phase 2: Directory Creation
✅ Phase 3: Documentation Setup
✅ Phase 4: GitHub Integration
✅ Phase 5: Git Workflow Setup
🔄 Phase 6: Environment Configuration  ← Current
⏳ Phase 7: Documentation Rules
⏳ Phase 8: CLAUDE.md & Final Check
```

## Steps

### 1. .gitignore Setup

- Add `.serena` (required for development projects)
- Add language/framework-specific patterns

For .gitignore templates by language, refer to:
`${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/gitignore-templates.md`

### 2. .claude/settings.json Setup

For the settings.json template, refer to:
`${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/settings-json-template.md`

**Design philosophy**: `allow` includes safe defaults (read-only + side-effect-free tools). Each user can add permissions via `.claude/settings.local.json`. The shared `settings.json` focuses on `ask` and `deny`.

**Tech-stack selection**: Based on the technology stack identified in Phase 1, add the appropriate tool blocks to `ask`. Refer to the "Tech-Stack Blocks" section in the settings template.

**Ralph Loop / Autonomous operation**: If the project uses Ralph Loop or similar autonomous workflows, refer to the "Ralph Loop Addon" section in the settings template for scoped `allow` rules.

### 3. Destructive Change Prohibition Rules

Document in settings.json and README.md:
- System file changes prohibited (/etc, /usr, etc.)
- Changes outside project directory prohibited

### Important Warning

Tell the user:

"`.claude/settings.json` is created based on official documentation and best practices, but requirements may differ per project.

When starting a Claude Code session in each project, always verify whether settings.json is appropriate. In particular:
- Permissions for project-specific tools and commands
- Handling of special directory structures
- Security requirements

Adjust manually as needed."

## Completion Criteria

Verify all of the following:
- [ ] .gitignore includes `.serena`
- [ ] .claude/settings.json created
- [ ] settings.json reflects official best practices
- [ ] Tech-stack specific tools selected and added to `ask`
- [ ] Destructive change prohibition rules documented in settings.json and README.md

## Completion Report

Report to user:

"Phase 6 (Environment Configuration) is complete.

Created artifacts:
- .gitignore (.serena included)
- .claude/settings.json (permissions configured)

Note: settings.json should be reviewed and adjusted per project.

Proceed to Phase 7 (Documentation Rules)?"

**Wait for user approval before proceeding.**
