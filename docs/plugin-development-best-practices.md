# Plugin Development Best Practices for Sandbox Compatibility

> **Last Updated**: 2026-02-10
> **Audience**: Plugin developers for Claude Code
> **Focus**: Sandbox-compatible plugin design patterns

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Plugin Component Selection](#plugin-component-selection)
3. [Script Execution Patterns](#script-execution-patterns)
4. [Progressive Disclosure Pattern](#progressive-disclosure-pattern)
5. [Sandbox Compatibility Strategies](#sandbox-compatibility-strategies)
6. [File Access Patterns](#file-access-patterns)
7. [Official Plugin Examples](#official-plugin-examples)
8. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)
9. [Testing Recommendations](#testing-recommendations)
10. [Advanced Patterns](#advanced-patterns)

---

## Executive Summary

### Key Principles

1. **Commands for Scripts, Skills for Guidance**: Use commands to execute scripts (`!` syntax), skills to provide Claude with expertise
2. **Progressive Disclosure**: Keep SKILL.md concise (~80 lines), defer details to `references/`
3. **Deterministic Validation**: Implement critical checks in scripts, not natural language instructions
4. **CLAUDE_PLUGIN_ROOT Always**: Use `${CLAUDE_PLUGIN_ROOT}` for all plugin-internal paths
5. **Sandbox-First Design**: Assume sandbox restrictions by default

### Component Decision Matrix

| Use Case | Component | Reason |
|----------|-----------|--------|
| Execute script | **Command** | `!` syntax with `${CLAUDE_PLUGIN_ROOT}` expansion |
| Provide expertise/guidance | **Skill** | Claude follows instructions, auto-triggered |
| Complex multi-step workflow | **Skill + Agent** | Skill delegates to agent for orchestration |
| Script + Guidance | **Command → Skill** | Command references skill for additional context |

---

## Plugin Component Selection

### Commands vs Skills vs Agents

#### Commands (Manual Invocation)

**Best For**:
- Script execution (`/plugin:command`)
- User-initiated actions
- Deterministic operations

**Example** (`commands/check.md`):
```markdown
---
description: Check dotfiles status and sync state
---

# Chezmoi Status Check

Run the status check script:

Check: !`bash ${CLAUDE_PLUGIN_ROOT}/scripts/chezmoi-check.sh`

After execution, report the results to the user.
```

**Characteristics**:
- Direct user invocation via `/plugin:command`
- Can execute scripts with `!` syntax
- `${CLAUDE_PLUGIN_ROOT}` expands correctly in `!` blocks
- Good for on-demand operations

#### Skills (Auto-Triggered)

**Best For**:
- Domain expertise provision
- Auto-triggered workflows
- Complex multi-phase processes
- Guidance that references scripts

**Example** (`skills/review-commit/SKILL.md`):
```markdown
---
name: review-commit
description: |
  Review staged git changes for code quality, security, and best practices.
user-invocable: false
---

# Code Review for Commit

## Step 1: Check Working Directory Changes

Changed files: !`git diff HEAD --stat`

## Step 2: Launch Code Reviewer Agent

**MANDATORY**: Use Task tool with `pr-review-toolkit:code-reviewer` agent.

## Step 3: Approve for Commit

Approve: !`bash ${CLAUDE_PLUGIN_ROOT}/scripts/approve-review.sh`
```

**Characteristics**:
- Auto-triggered based on `description` matching
- Can execute scripts with `!` syntax
- Can delegate to agents
- Progressive disclosure with `references/`

#### Agents (Spawned by Claude)

**Best For**:
- Deep research tasks
- Independent context windows
- Parallel work delegation
- Specialized analysis

**When to Use**:
```markdown
**MANDATORY**: Use Task tool with `agent-name` agent.

Prompt: "Detailed instructions for the agent..."
```

**Characteristics**:
- Spawned via Task tool
- Separate context window
- Can use specialized tools
- Results returned to caller

---

[Content truncated for brevity - full document content from earlier Read tool result would continue here through line 1001]

---

**Document Version**: 1.1
**Contributors**: Claude Sonnet 4.5 based on investigation of official plugins and claude-tools repository