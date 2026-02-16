# Security Checklist

PR review security checks. Core items apply to all projects; project-specific items are auto-detected.

## Core Checks (All Projects)

### Secrets & Credentials
- [ ] No hardcoded API keys, passwords, tokens, or secrets
- [ ] No `.env` files or credential files in the diff
- [ ] No private keys or certificates committed

### Fail-Closed Behavior
- [ ] Error states default to deny/safe behavior (not permissive)
- [ ] Authentication failures result in access denied (not silent pass-through)
- [ ] Unknown states treated as untrusted

### PII & Data Leakage
- [ ] No personal information logged (emails, IPs, names in debug output)
- [ ] Sensitive data not exposed in error messages
- [ ] No internal paths or system details leaked to users

## Project-Specific Checks (Auto-Detected)

Claude should detect the project's tech stack and apply relevant checks:

### AWS / Cloud (detect: `cdk.json`, `serverless.yml`, `sam-template.yaml`, `terraform/`)
- [ ] IAM policies follow least-privilege principle
- [ ] No wildcard (`*`) resource permissions in production
- [ ] S3 buckets not publicly accessible unless intended
- [ ] Secrets stored in Secrets Manager / SSM, not in code

### Database (detect: ORM libraries, query builders, `prisma/`, `drizzle/`)
- [ ] No raw SQL with string interpolation (SQL injection risk)
- [ ] Parameterized queries or ORM methods used
- [ ] Database credentials not in source code

### Web UI (detect: `react`, `vue`, `angular`, `svelte` in dependencies)
- [ ] No unsafe inner HTML rendering without sanitization
- [ ] User input sanitized before rendering
- [ ] CSRF protection enabled on state-changing endpoints
- [ ] Content-Security-Policy headers configured

### API (detect: OpenAPI spec, REST/GraphQL endpoint definitions)
- [ ] Internal fields not exposed in API responses
- [ ] Rate limiting on public endpoints
- [ ] Input validation on all API parameters
- [ ] Authentication required on sensitive endpoints

## How to Use

1. Always apply **Core Checks**
2. Scan the project for tech-stack indicators listed in each section header
3. Apply matching **Project-Specific Checks**
4. Report failures with severity: Critical (secrets, injection) > Important (config, exposure)
