# .gitignore Security Patterns

## Marker Block

The following block should be appended to `.gitignore` when the marker `code:security-patterns` is not found.

```gitignore
# [code:security-patterns]
.env
.env.*
!.env.example
!.env.sample
!.env.template
*.key
*.pem
*.p12
*.pfx
credentials*
!credentials.example.*
# [/code:security-patterns]
```

## Rules

- **Marker**: `# [code:security-patterns]` ~ `# [/code:security-patterns]`
- **Detection**: `grep -q "code:security-patterns" .gitignore`
- **Idempotent**: If the marker already exists, do nothing
- **Append-only**: Always add to the end of `.gitignore`, never modify existing entries

## Auto-fix Behavior

| Condition | Action |
|-----------|--------|
| `.gitignore` does not exist | Create file with marker block |
| `.gitignore` exists, no marker | Append marker block to end of file |
| `.gitignore` exists, marker present | No action (idempotent) |

## Pattern Rationale

| Pattern | Purpose |
|---------|---------|
| `.env` | Environment variables (API keys, DB credentials) |
| `.env.*` | Environment variant files (.env.local, .env.production) |
| `!.env.example` | Allow example/template files |
| `!.env.sample` | Allow sample files |
| `!.env.template` | Allow template files |
| `*.key` | Private key files |
| `*.pem` | PEM certificates/keys |
| `*.p12` | PKCS#12 keystores |
| `*.pfx` | PFX certificates |
| `credentials*` | Credential files (credentials.json, credentials.yaml) |
| `!credentials.example.*` | Allow credential examples |
