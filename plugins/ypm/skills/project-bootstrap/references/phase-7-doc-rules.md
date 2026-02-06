# Phase 7: Documentation Rules

**Progress Display**:
```
✅ Phase 1: Project Planning
✅ Phase 2: Directory Creation
✅ Phase 3: Documentation Setup
✅ Phase 4: GitHub Integration
✅ Phase 5: Git Workflow Setup
✅ Phase 6: Environment Configuration
🔄 Phase 7: Documentation Rules  ← Current
⏳ Phase 8: CLAUDE.md & Final Check
```

## Steps

### 1. Documentation Update Principles

Establish the following:

- **Keep implementation and documentation in sync**
  - Update related docs when adding/changing features
  - Verify documentation updates during PR review

- **When to update**
  - New feature implementation complete
  - Architecture changes
  - API specification changes
  - Environment configuration changes
  - Major dependency updates

- **Target documents**
  - README.md (setup instructions, usage)
  - docs/specifications.md (system specs)
  - docs/architecture.md (design documents)
  - docs/development-guide.md (development guidelines)
  - API specification (if applicable)

### 2. Onboarding Support

Include in README.md:
- Quick start guide
- Development environment setup steps
- FAQ (common problems and solutions)
- Contribution guidelines

Create `docs/onboarding.md`:
- Project structure explanation
- Coding conventions
- How to write and run tests
- Deployment process

### 3. Documentation Update Checklist

- Add "Documentation update status" to PR template
- CI/CD link checking (if possible)

## Completion Criteria

Verify all of the following:
- [ ] Documentation management principles established
- [ ] README.md includes onboarding information
- [ ] docs/onboarding.md created
- [ ] PR template created

## Completion Report

Report to user:

"Phase 7 (Documentation Rules) is complete.

Created artifacts:
- README.md (onboarding information added)
- docs/onboarding.md
- PR template (.github/pull_request_template.md)

Proceed to Phase 8 (CLAUDE.md & Final Check)?"

**Wait for user approval before proceeding.**
