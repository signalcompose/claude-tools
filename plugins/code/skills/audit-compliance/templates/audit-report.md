# Compliance Audit Report Template

```markdown
## Compliance Audit Report

**Branch**: <branch-name>
**Date**: <YYYY-MM-DD>
**Commits audited**: N

### Executive Summary

[5-10文で監査範囲、主要発見事項、総合評価を記述]

**Key Metrics**:
| Metric | Value | Status |
|--------|-------|--------|
| Coverage | XX.XX% | pass/fail |
| Test Count | NNN | pass/fail |
| Files Modified | NN | - |
| Issues Closed | N | pass/fail |

### Audit Results

| Principle | Status | Impact | Notes |
|-----------|--------|--------|-------|
| DDD       | pass/partial/fail | High/Med/Low | ... |
| TDD       | pass/partial/fail | High/Med/Low | ... |
| DRY       | pass/partial/fail | High/Med/Low | ... |
| ISSUE     | pass/partial/fail | High/Med/Low | ... |
| PROCESS   | pass/partial/fail | High/Med/Low | ... |

**Score**: X/5 compliant

### Detailed Findings

(PARTIAL/FAIL のみ記載。PASS は "No issues found" の1行で完了)

#### [Principle Name] (if partial/fail)
- 該当箇所、問題内容、推奨対応

### Required Actions
(FAIL/HIGH impact のみ)

### Recommendations
(3-5項目に絞る)

### Appendix: Raw Data

#### Coverage Output
\`\`\`
(raw coverage output)
\`\`\`

#### Test Output
\`\`\`
(raw test output)
\`\`\`

#### Commit Log
\`\`\`
(git log output)
\`\`\`
```

## Enforcement Rules

- **All pass**: Report "Compliance audit passed" — safe to ship
- **Any partial**: Report findings as warnings — can ship with acknowledgment
- **Any fail (HIGH impact)**: Report as blockers — must fix before shipping
- **Any fail (LOW/MEDIUM impact)**: Report as warnings — recommend fixing
