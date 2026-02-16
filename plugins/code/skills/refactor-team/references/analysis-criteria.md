# Analysis Criteria for Refactoring

Criteria for the analyzer agent to evaluate code and produce prioritized proposals.

## Analysis Categories

### 1. DRY Violations
- Duplicated code blocks (3+ lines repeated 2+ times)
- Copy-paste patterns with minor variations
- Logic that could be extracted into shared functions
- Repeated configuration or constants

### 2. Complexity
- Cyclomatic complexity > 10 per function
- Nesting depth > 3 levels
- Functions exceeding 50 lines
- Files exceeding 300 lines
- Complex conditional chains that could be simplified

### 3. Naming
- Ambiguous variable names (e.g., `data`, `temp`, `x`)
- Inconsistent naming conventions within the same file
- Names that don't reflect purpose or intent
- Abbreviations that reduce readability

### 4. Structure
- Files with mixed responsibilities (SRP violation)
- Module boundaries that could be clearer
- Import cycles or circular dependencies
- Dead code (unused exports, unreachable branches)

## Using code-simplifier Agent

The `pr-review-toolkit:code-simplifier` agent can be used to analyze files.
Provide it with the target file paths and ask for simplification opportunities.

## Proposal Report Format

Present findings in this table format:

| # | Category | File:Line | Description | Priority | Risk |
|---|----------|-----------|-------------|----------|------|
| 1 | DRY | src/a.ts:42 | Extract duplicated validation into shared util | High | Low |
| 2 | Complexity | src/b.ts:15 | Simplify nested conditionals with early returns | Medium | None |
| 3 | Naming | src/c.ts:8 | Rename `d` to `userDisplayName` | Low | None |

### Priority Levels
- **High**: Actively harms maintainability; should be done
- **Medium**: Noticeable improvement; recommended
- **Low**: Nice-to-have; optional

### Risk Levels
- **None**: Pure rename, formatting, or comment change
- **Low**: Logic restructuring with existing test coverage
- **Needs Review**: Behavior could change; requires careful testing

## Rules for Refactorer

1. **1 refactoring = 1 commit** — each change is individually revertible
2. **No functional changes** — behavior must be identical before and after
3. **Run tests after each change** — revert if tests fail
4. **Commit message**: `refactor: <description>` (Conventional Commits)
