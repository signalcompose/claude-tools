# YPM (Your Project Manager) - Claude Code Plugin

## Project Overview

YPM is an **English-first international open-source project** that provides multi-project progress tracking powered by Claude Code. While the project is globally accessible, internal development documentation strategically remains in Japanese for design depth and precision.

**Key Facts**:
- **Primary Language**: English (international OSS)
- **Internal Dev Docs**: Japanese (docs/development/, docs/research/)
- **Repository**: https://github.com/signalcompose/ypm
- **License**: MIT

## 🚨 Mandatory Session Start Checklist

**Execute at the start of every session without confirmation dialog**:

### STEP 1: Verify Current Branch

```bash
git branch --show-current
```

**Critical GitHub Flow Rule**:
- ✅ Work on `feature/*`, `fix/*`, `docs/*`, `chore/*` branches
- ❌ **NEVER commit directly to `main` branch** (project policy)
- ✅ Always create feature branch from `main`
- ✅ Merge via Pull Request only

**Branch Naming Convention**:
- Feature: `feature/description-in-english`
- Bugfix: `bugfix/description-in-english`
- Hotfix: `hotfix/description-in-english`

### STEP 2: Review Documentation (DDD Principle)

**Documentation is the Single Source of Truth**

1. Read `CLAUDE.md` (this file)
2. Read `docs/INDEX.md` (documentation index)
3. Load relevant documents from index
4. If Serena MCP is available, load project memories

**Important**: Always trust documentation over memory or cache.

### STEP 3: Understand Three-Level Language Configuration

YPM implements a three-level language configuration system. These are **independent settings** that work together:

#### 1. Claude Code Response Language
**Location**: `.claude/settings.json` (user setting, not in repository)
**Purpose**: Controls what language Claude uses when responding
**Example**: `"language": "japanese"`
**Scope**: All Claude responses in the session

#### 2. YPM Command Output Language
**Location**: `~/.ypm/config.yml`
**Purpose**: Controls YPM command output language (PROJECT_STATUS.md, etc.)
**Options**: `settings.language: en` (default) or `ja`
**Mechanism**: Dynamic translation by Claude when set to `ja`

#### 3. Project Documentation Language
**Location**: Project files (CLAUDE.md, README.md, guide-en.md, etc.)
**Purpose**: Language of instructions to Claude and user-facing documentation
**YPM Strategy**:
- Public docs: English (README.md, guide-en.md, command files)
- Internal dev docs: Japanese (docs/development/, docs/research/)

**Key Insight**:
- Writing this CLAUDE.md in English does NOT conflict with Japanese responses
- Set `"language": "japanese"` in your `.claude/settings.json` for Japanese responses
- This combination is **recommended** by the Japanese Claude Code community
- Avoids UTF-8/CJK character crashes and leverages Claude's better English training

## GitHub Flow Workflow

### Branch Strategy

**GitHub Flow** (simple OSS workflow)

```
main              ← Production branch (default)
  └── feature/xxx ← Feature branches
  └── fix/xxx     ← Bug fix branches
  └── docs/xxx    ← Documentation branches
  └── chore/xxx   ← Maintenance branches
```

### Creating a Feature Branch

```bash
# Ensure you're on main
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/your-feature-name

# Work on your feature...
git add .
git commit -m "feat: your feature description"

# Push and create PR
git push -u origin feature/your-feature-name
gh pr create --base main --title "feat: your feature description"
```

### Commit Message Convention

Follow **Conventional Commits** specification:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

**Format**:
```
<type>: <description>

[optional body]

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Documentation Driven Development (DDD)

### Core Principles

1. **Documentation First**: Read documentation before starting work
2. **Documentation as Truth**: When code and docs conflict, trust documentation
3. **Keep Docs Updated**: Update documentation before or alongside code changes
4. **Propose Missing Docs**: If documentation is missing, propose creating it

### Documentation Structure

```
docs/
├── INDEX.md              # Documentation index (English)
├── guide-en.md           # User guide (English, primary)
├── guide-ja.md           # User guide (Japanese, deprecated)
├── development/          # Internal design docs (Japanese)
│   ├── architecture.md
│   ├── onboarding-script-spec.md
│   ├── ypm-open-spec.md
│   └── global-export-system.md
└── research/             # Research notes (Japanese)
    ├── claude-md-loading-guarantee.md
    └── private-to-public-strategy.md
```

## YPM Plugin Architecture

### Skills (Auto-triggered)

Skills live in `skills/<skill-name>/SKILL.md` with YAML frontmatter:

| Skill | Purpose |
|-------|---------|
| `project-status-update` | Scan and update PROJECT_STATUS.md |
| `next-tasks` | Show next tasks in priority order |
| `active-projects` | Show recently active projects |
| `project-bootstrap` | 8-phase new project setup wizard |
| `git-workflow-setup` | Configure Git Flow with branch protection |

Skills use Progressive Disclosure: SKILL.md body (~80 lines) + `references/` for details.

### Commands (Manual invocation)

Commands live in `commands/*.md`:

| Command | Purpose |
|---------|---------|
| `setup` | Initialize YPM |
| `start` | Welcome message |
| `help` | Detailed help |
| `open` | Open project in editor |
| `export-community` | Export to public repo |
| `trufflehog-scan` | Security scan |

Legacy stub commands (`update`, `next`, `active`, `new`, `setup-gitflow`) redirect to skills.

### Hooks

- `hooks/hooks.json` - SessionStart: check config existence and status freshness

### Development Workflow

1. **Read existing skills/commands** for patterns
2. **Follow established conventions**:
   - Use `AskUserQuestion` for user input
   - Use `${CLAUDE_PLUGIN_ROOT}` for script paths
   - Implement proper error handling
3. **Test thoroughly** before committing
4. **Update documentation** (guide-en.md)

### File Naming Convention

- Commands: `command-name.md` (lowercase with hyphens)
- Skills: `skills/<skill-name>/SKILL.md`

## YPM Configuration System

### Configuration File Hierarchy

1. **User Config**: `~/.ypm/config.yml` (user-specific settings)
2. **Example Config**: `config.example.yml` (template in repository)
3. **Plugin Metadata**: `.claude-plugin/plugin.json`

### Language Setting in YPM

```yaml
settings:
  language: en  # or ja
```

**Important**: This setting controls YPM command output language only, NOT Claude's response language. For Claude's response language, use `.claude/settings.json`.

## Security and Privacy

### Handling Sensitive Information

- **NEVER** commit API keys, passwords, or tokens to git
- **ALWAYS** use `.env` files for sensitive data
- **VERIFY** `.gitignore` includes sensitive file patterns
- **PROVIDE** `.example` templates for configuration files

### Pre-Commit Verification

Before committing, verify:
1. No `.env` or `.env.local` files included
2. No `credentials.json` or similar files
3. No hardcoded API keys or tokens
4. `.gitignore` is appropriate

## Task Management

### Using TodoWrite Tool

**When to use**:
- Multi-step tasks
- Complex work requiring progress tracking
- When visualizing work status for user

**Usage Rules**:
- Create todo list at task start
- Mark task as `in_progress` when starting work
- Mark as `completed` immediately upon completion
- Keep only one task as `in_progress` at a time

## Error Handling

### Responding to Errors

**Principles**:
- Report errors honestly, never hide them
- Explain error cause clearly
- Present possible solutions
- Ask user for decision when multiple options exist

## Language Strategy Philosophy

### "English for Reach, Japanese for Depth"

YPM's bilingual strategy balances:
- **International accessibility** (English public docs)
- **Design precision** (Japanese internal docs)
- **Community contribution** (English interfaces)
- **Development efficiency** (Japanese for complex design discussions)

This is a **strategic choice**, not a limitation. The `language` setting in Claude Code (2.1.0+) enables dynamic translation, allowing contributors to work in their preferred language while maintaining English as the project's primary language.

## Session Workflow

### Typical Session Flow

1. Execute Session Start Checklist (STEP 1-3)
2. Review user request
3. Create TodoWrite list if multi-step task
4. Execute work with proper Git workflow
5. Update documentation if needed
6. Commit with proper message
7. Create PR if feature complete

### Before Session End (When Serena MCP Available)

If long session or important milestone reached:
1. Save work summary to Serena memory
2. Document next steps
3. Note important decisions
4. Format: `{work_content}_{YYYY-MM-DD}`

## Reference Documentation

For detailed information:
- User Guide: `docs/guide-en.md`
- Architecture: `docs/development/architecture.md` (Japanese)
- Command Specs: `docs/development/*.md` (Japanese)
- Research Notes: `docs/research/*.md` (Japanese)

## Additional Resources

See README.md for contribution guidelines and support channels.

---

**Last Updated**: 2026-02-06
**Claude Code Version**: 2.1.0+
