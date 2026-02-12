# Skill Template

Template for creating new Claude Code skills with Progressive Disclosure.

## Basic Skill Template

```markdown
---
name: skill-name
description: |
  Brief description of what the skill does.
  Use when: "trigger phrase 1", "trigger phrase 2",
  "Japanese trigger", "別のトリガー".
user-invocable: false
---

# Skill Title

Brief overview of the skill's purpose and functionality.

## Core Principles

List key principles that guide skill execution (if applicable):
1. Principle 1
2. Principle 2
3. Principle 3

## How to Execute

### Step 1: [First Step Name]

Clear, actionable instructions for the first step.

Run: !`command-to-execute`

### Step 2: [Second Step Name]

Instructions for the second step.

### Step 3: [Third Step Name]

Instructions for the third step.

## Reference Files (read as needed)

If you need additional guidance:

- **Topic 1**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/topic-1.md`
- **Topic 2**: Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/topic-2.md`
```

## Progressive Disclosure Template

For skills with substantial reference documentation:

```markdown
---
name: complex-skill
description: |
  Multi-phase skill with extensive documentation.
  Use when: "trigger phrases".
user-invocable: false
---

# Complex Skill Title

Overview of the skill's multi-phase workflow.

## Phase Overview

| Phase | Name | Key Actions |
|-------|------|-------------|
| 1 | Phase Name | Key action summary |
| 2 | Phase Name | Key action summary |
| 3 | Phase Name | Key action summary |

## How to Execute

For each phase, read the corresponding reference file:

- **Phase 1**: Read `${CLAUDE_PLUGIN_ROOT}/skills/complex-skill/references/phase-1.md`
- **Phase 2**: Read `${CLAUDE_PLUGIN_ROOT}/skills/complex-skill/references/phase-2.md`
- **Phase 3**: Read `${CLAUDE_PLUGIN_ROOT}/skills/complex-skill/references/phase-3.md`

**Additional references** (load as needed during relevant phases):
- **Troubleshooting**: Read `${CLAUDE_PLUGIN_ROOT}/skills/complex-skill/references/troubleshooting.md`
- **Advanced options**: Read `${CLAUDE_PLUGIN_ROOT}/skills/complex-skill/references/advanced.md`

## Phase Transition Protocol

At the end of each phase:

1. Verify completion criteria are met
2. Report completed artifacts to the user
3. Ask: "Phase N is complete. Proceed to Phase N+1?"
4. **Wait for user approval** before continuing
```

## Directory Structure Template

```
plugins/
└── your-plugin/
    └── skills/
        └── skill-name/
            ├── SKILL.md              # Main skill file (use template above)
            └── references/           # Reference documentation
                ├── phase-1.md        # For multi-phase skills
                ├── phase-2.md
                ├── troubleshooting.md
                ├── advanced.md
                └── examples.md
```

## Frontmatter Guidelines

### Required Fields

```yaml
---
name: skill-name                    # Must match directory name
description: |                      # Multi-line description
  What the skill does.
  Trigger phrases for invocation.
user-invocable: false              # Usually false for skills
---
```

### Optional Fields

```yaml
---
name: skill-name
description: |
  Skill description.
user-invocable: false
allowed-tools:                     # ⚠ CAUTION: May conflict with ! execution syntax
  - Bash                           # Known to be unstable in some configurations
  - Read                           # Use only if absolutely necessary
  - Write
---
```

**Note**: The `allowed-tools` field can cause intermittent issues when combined with `!` execution syntax. Use with caution and test thoroughly. Prefer skills without tool restrictions when possible.

## Best Practices

### 1. Keep Main Body Concise

**Target**: ~80 lines for SKILL.md main body
- Core instructions only
- Step-by-step execution flow
- References to detailed documentation

**Move to references/**:
- Detailed examples
- Troubleshooting guides
- Advanced configuration
- Edge case handling

### 2. Use Clear Execution Instructions

**Good**:
```markdown
### Step 1: Check Status

Run: !`git status`

Verify there are changes to commit.
```

**Not as clear**:
```markdown
### Step 1

Check if there are changes.
```

### 3. Explicit Reference Loading

**Good**:
```markdown
If you encounter errors, read the troubleshooting guide:
`${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/troubleshooting.md`
```

**Avoid**:
```markdown
See troubleshooting.md for errors.
```

### 4. Group Related References

```markdown
## Reference Files (read as needed)

**For setup**:
- Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/setup-guide.md`

**For troubleshooting**:
- Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/common-errors.md`
- Read `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/debugging.md`
```

### 5. Use Descriptive Section Headers

```markdown
## Reference: Diff Interpretation

[Inline reference content explaining diff interpretation]
```

Not just the section name - explain what guidance the reference provides in the section header.

## Reference File Template

Template for individual reference files:

```markdown
# [Topic Name]

Brief introduction to this topic.

## Overview

What this reference covers and when to use it.

## Detailed Instructions

### Sub-topic 1

Detailed explanation with examples.

### Sub-topic 2

More detailed content.

## Examples

Concrete examples demonstrating the concepts.

## Common Issues

FAQ-style troubleshooting specific to this topic.

## See Also

- Related reference: `${CLAUDE_PLUGIN_ROOT}/skills/skill-name/references/related.md`
```

## Skill Naming Conventions

### Skill Names

- Use kebab-case: `project-bootstrap`, `review-commit`, `shell-sync-setup`
- Be descriptive: name should indicate purpose
- Match directory name exactly

### Reference File Names

- Use kebab-case: `phase-1-planning.md`, `diff-interpretation-guide.md`
- Be specific: indicate content clearly
- Group related files with prefixes: `phase-1-*.md`, `phase-2-*.md`

## Testing Your Skill

### Verification Checklist

Before committing a new skill:

- [ ] Frontmatter is valid YAML
- [ ] `name` field matches directory name
- [ ] All `${CLAUDE_PLUGIN_ROOT}` paths are correct
- [ ] All referenced files exist in `references/` directory
- [ ] No Markdown relative links remain
- [ ] Main body is concise (~80 lines)
- [ ] Instructions are clear and actionable
- [ ] Reference files are well-organized
- [ ] Skill invocation triggers work correctly

### Manual Testing

1. **Invoke the skill**:
   ```
   /plugin:skill-name
   ```

2. **Verify reference loading**:
   - Trigger conditions that should load references
   - Confirm files load without errors
   - Check that content is relevant

3. **Test edge cases**:
   - What happens with no input?
   - What happens with invalid input?
   - Are error messages helpful?

4. **Check working directory independence**:
   - Invoke from different directories
   - Verify `${CLAUDE_PLUGIN_ROOT}` expands correctly

## Examples from claude-tools

### Simple Skill: chezmoi/commit

```markdown
---
name: commit
description: |
  Commit and push changed dotfiles to remote repository.
  Use when: "commit dotfiles", "push dotfiles".
user-invocable: false
---

# Chezmoi Commit

Detect changed dotfiles, commit and push to remote.

## Diff Interpretation

Use `chezmoi diff --reverse` to get git-like diff output.

For detailed examples, read `${CLAUDE_PLUGIN_ROOT}/skills/commit/references/diff-interpretation.md`.

## Execution

### Step 1: Detect & Show Changes
...
```

### Complex Skill: ypm/project-bootstrap

```markdown
---
name: project-bootstrap
description: |
  Interactive 8-phase new project setup wizard.
user-invocable: false
---

# Project Bootstrap Wizard

## Phase Overview

| Phase | Name | Key Actions |
|-------|------|-------------|
| 1 | Planning | Requirements gathering |
| 2 | Directory | Local setup, git init |
...

## How to Execute

For each phase, read the corresponding reference file:

- **Phase 1**: Read `${CLAUDE_PLUGIN_ROOT}/skills/project-bootstrap/references/phase-1-planning.md`
...
```

## Migration from Old Patterns

If you have an existing skill using Markdown links:

1. See [progressive-disclosure.md](./progressive-disclosure.md) for full migration guide
2. Use the "Migration Guide" section
3. Verify all paths after migration
4. Test skill invocation thoroughly

## Further Reading

- [progressive-disclosure.md](./progressive-disclosure.md) - Progressive Disclosure pattern details
- [CLAUDE.md](../CLAUDE.md) - Project conventions
- [Anthropic Skill Building Guide](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)

## Changelog

- **2026-02-12**: Initial template after Progressive Disclosure standardization (Phase 2)
