# Progressive Disclosure in Claude Code Skills

## Overview

Progressive Disclosure is a design pattern for Claude Code skills that loads information incrementally as needed, rather than loading everything upfront. This improves performance, reduces context window usage, and makes skills easier to maintain.

## The Problem

Early skill implementations used Markdown relative links to reference additional documentation:

```markdown
## References

- Setup guide: [references/setup-guide.md](references/setup-guide.md)
- Troubleshooting: [references/troubleshooting.md](references/troubleshooting.md)
```

**Why this doesn't work:**

1. **Claude Code doesn't auto-resolve Markdown links** - This is by design, not a bug
2. **Relative path resolution is unreliable** - Depends on working directory context
3. **Working directory restrictions** - Plugin cache directories may be outside allowed paths
4. **Sandbox limitations** - File access outside working directories can be blocked

## The Solution: `${CLAUDE_PLUGIN_ROOT}` Pattern

Claude Code provides the `${CLAUDE_PLUGIN_ROOT}` environment variable for plugin-internal paths.

### Correct Implementation (YPM Pattern)

```markdown
## How to Execute

### Step 1: Planning Phase

Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/planning-guide.md` for detailed planning instructions.

### Step 2: Setup Phase

Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/setup-guide.md` for setup steps.

## Reference Files (read as needed)

If you need additional guidance:

- **Troubleshooting**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/troubleshooting.md`
- **Advanced options**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/advanced.md`
```

### Why This Works

1. **Runtime Resolution**: `${CLAUDE_PLUGIN_ROOT}` expands to the actual plugin installation path
   - Example: `~/.claude/plugins/cache/claude-tools/plugin-name/abc123/`

2. **Cache-Aware**: Works correctly with Claude Code's plugin caching system
   - Each commit version has its own cache directory
   - Reference files always match the skill version

3. **Working Directory Independent**: Doesn't rely on current working directory
   - Plugin can be invoked from any directory
   - Paths always resolve correctly

4. **Explicit Instructions**: "Read `${CLAUDE_PLUGIN_ROOT}/...`" tells Claude to load the file
   - Clear, actionable instruction
   - No ambiguity about when to load

## Directory Structure

```
plugins/
└── your-plugin/
    └── skills/
        └── skill-name/
            ├── SKILL.md              # Main skill file (always loaded)
            └── references/           # Additional documentation (load as needed)
                ├── topic-1.md
                ├── topic-2.md
                └── troubleshooting.md
```

## Three-Level Information Architecture

Progressive Disclosure implements a three-level architecture:

### Level 1: Frontmatter (Always Loaded)

```yaml
---
name: skill-name
description: Brief description
user-invocable: false
---
```

**Purpose**: Metadata for skill discovery and invocation

### Level 2: Main Body (Loaded on Invocation)

```markdown
# Skill Title

Brief overview of what the skill does.

## How to Execute

Step-by-step instructions with explicit "Read" directives for reference files.
```

**Purpose**: Core instructions and execution flow (~80 lines recommended)

### Level 3: References (Load as Needed)

```
references/
├── detailed-examples.md     # Loaded when examples needed
├── troubleshooting.md       # Loaded when errors occur
└── advanced-options.md      # Loaded for complex scenarios
```

**Purpose**: Detailed documentation loaded conditionally

## Migration Guide

### From Markdown Links to Environment Variables

**Before (Incorrect)**:
```markdown
## References

- Setup: [references/setup.md](references/setup.md)
- Errors: [references/errors.md](references/errors.md)
```

**After (Correct)**:
```markdown
## Reference Files (read as needed)

If you need guidance:

- **Setup**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/setup.md`
- **Error handling**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/errors.md`
```

### Step-by-Step Migration

1. **Identify Markdown Links**
   ```bash
   grep -r "\[references/" plugins/your-plugin/skills/
   ```

2. **Convert Each Link**
   - Replace `[text](references/file.md)`
   - With `Read \`${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/file.md\``

3. **Update Section Headings**
   - Change `## References` to `## Reference Files (read as needed)`
   - Add introductory text: "If you need guidance:"

4. **Verify File Paths**
   ```bash
   # Check all referenced files exist
   ls -la plugins/your-plugin/skills/skill-name/references/
   ```

5. **Test the Skill**
   - Invoke the skill
   - Verify reference files load correctly
   - Check that `${CLAUDE_PLUGIN_ROOT}` expands properly

## Best Practices

### 1. Use Descriptive Labels

```markdown
## Reference: Diff Interpretation

[Inline reference content explaining diff interpretation]
```

Not just the section name - explain what the reference provides in the section header.

### 2. Group Related References

```markdown
## Reference Files (read as needed)

**For setup issues**:
- Read `${CLAUDE_PLUGIN_ROOT}/skills/setup/references/troubleshooting.md`

**For advanced configuration**:
- Read `${CLAUDE_PLUGIN_ROOT}/skills/setup/references/advanced-config.md`
```

### 3. Make Loading Conditional

```markdown
If the installation fails, read troubleshooting guide:
`${CLAUDE_PLUGIN_ROOT}/skills/setup/references/troubleshooting.md`
```

Only suggest loading when actually needed.

### 4. Keep Main Body Concise

- Target: ~80 lines for main SKILL.md body
- Move detailed examples to references/
- Move troubleshooting to references/
- Move advanced options to references/

### 5. Maintain Reference Files

- Keep reference files focused on one topic
- Update references when code changes
- Delete obsolete references
- Verify all referenced files exist

## Verification Checklist

Before committing Progressive Disclosure changes:

- [ ] All `${CLAUDE_PLUGIN_ROOT}` paths use curly braces (not `$CLAUDE_PLUGIN_ROOT`)
- [ ] All referenced files exist in the references/ directory
- [ ] No Markdown link references (`[text](references/file.md)`) remain
- [ ] Section headings clearly indicate optional loading
- [ ] Instructions explicitly say "Read `${CLAUDE_PLUGIN_ROOT}/...`"
- [ ] File paths are correct (skill name matches directory name)
- [ ] References are organized logically (grouped by purpose)

## Examples from claude-tools

### YPM project-bootstrap (10 references)

```markdown
## How to Execute

For each phase, read the corresponding reference file to get detailed instructions:

- **Phase 1**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-1-planning.md`
- **Phase 2**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-2-directory.md`
...
```

### chezmoi sync (2 inline references)

```markdown
## Reference: Diff Interpretation

**Important**: `chezmoi diff` shows "what would happen if you run `chezmoi apply`".

- `-` lines = Current **local** file content (destination)
- `+` lines = **Chezmoi source** content (what would be applied)

## Reference: Error Handling

### Network Error

```
Cannot reach github.com
```

Please check your internet connection and try again.
```

### code review-commit (1 reference)

```markdown
For detailed review criteria, read `${CLAUDE_PLUGIN_ROOT}/skills/review-commit/references/review-criteria.md`.
```

## Troubleshooting

### Issue: "File not found" errors

**Cause**: Incorrect file path in `${CLAUDE_PLUGIN_ROOT}/...` reference

**Solution**:
1. Verify file exists: `ls plugins/plugin-name/skills/skill-name/references/file.md`
2. Check skill name matches directory: `skills/skill-name/` in path
3. Verify spelling of filename

### Issue: References not loading

**Cause**: Missing "Read" instruction

**Solution**: Ensure you use explicit "Read `${CLAUDE_PLUGIN_ROOT}/...`" pattern

### Issue: Variable not expanding

**Cause**: Missing curly braces or incorrect syntax

**Solution**: Use `${CLAUDE_PLUGIN_ROOT}` (with braces), not `$CLAUDE_PLUGIN_ROOT`

## Further Reading

- [CLAUDE.md](../CLAUDE.md) - Project conventions and skill development guidelines
- [skill-template.md](./skill-template.md) - Template for new skills with Progressive Disclosure
- [Claude Code Plugins Documentation](https://code.claude.com/docs/en/plugins)

## Changelog

- **2026-02-12**: Phase 2 - Created comprehensive documentation
  - Added progressive-disclosure.md (this document)
  - Added skill-template.md for new skill development
  - Updated CLAUDE.md with Progressive Disclosure guidelines
  - Phase 1 (PR #104): Migrated 5 skills from Markdown links to `${CLAUDE_PLUGIN_ROOT}` pattern
