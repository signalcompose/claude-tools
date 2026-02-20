# Stage 0.5: Package Security Audit

**Conditional**: Only run when adding new dependency packages (before Stage 1).

## 0.5.1: npm audit

```bash
npm audit --audit-level=high
```

- If high / critical vulnerabilities exist: resolve before proceeding
- Moderate and below: record and continue

## 0.5.2: Dependency Evaluation

For each newly added package, verify:

- **Maintenance status**: Last update date, issue response time
- **License compatibility**: Compatible with MIT project (MIT, Apache-2.0, BSD OK)
- **Supply chain risk**: Download count, GitHub stars, known vulnerabilities
- **ESM compatibility**: Works with `"type": "module"` project

## 0.5.3: Record

Record results in `docs/research/dependency-audit.md`.
