# .gitignore Security Patterns

## Marker Block

The following block should be appended to `.gitignore` when the marker `code:security-patterns` is not found.

```gitignore
# [code:security-patterns:fbe2794b]
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

## Content Hash

The hash `fbe2794b` is the first 8 characters of the SHA-256 of the pattern content (lines between markers, excluding markers themselves).

To recompute:

```bash
printf '.env\n.env.*\n!.env.example\n!.env.sample\n!.env.template\n*.key\n*.pem\n*.p12\n*.pfx\ncredentials*\n!credentials.example.*\n' | shasum -a 256 | cut -c1-8
```

When patterns are updated, the hash must also be updated in this file and in the opening marker.

## Rules

- **Marker**: `# [code:security-patterns:<hash>]` ~ `# [/code:security-patterns]`
- **Detection (presence)**: `grep -q "code:security-patterns" .gitignore`
- **Detection (version)**: Extract hash from marker, compare with hash in this reference file
- **Idempotent**: If the marker with matching hash already exists, do nothing
- **Update**: If marker exists but hash differs, replace the entire marker block with the latest version
- **Append-only (new)**: If no marker exists, append to the end of `.gitignore`

## Auto-fix Behavior

| Condition | Action |
|-----------|--------|
| `.gitignore` does not exist | Create file with marker block |
| `.gitignore` exists, no marker | Append marker block to end of file |
| `.gitignore` exists, marker with matching hash | No action (idempotent) |
| `.gitignore` exists, marker with outdated hash | Replace marker block with latest version |

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
