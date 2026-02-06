# Security Settings

Apply these settings based on the project type selected in Step 0.

## Secret Scanning (Public repositories only)

Enable secret scanning and push protection:

```bash
gh api repos/:owner/:repo \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -f security_and_analysis='{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}'
```

**When to apply**: Small OSS (recommended), Large OSS (required)

## Fork Settings (OSS projects)

Configure fork and auto-merge settings:

```bash
gh api repos/:owner/:repo \
  -X PATCH \
  -H "Accept: application/vnd.github+json" \
  -f allow_forking=true \
  -f allow_auto_merge=false
```

**When to apply**: Small OSS (optional), Large OSS (recommended)

## Recommended Settings by Project Type

| Setting | Personal | Small OSS | Large OSS |
|---------|----------|-----------|-----------|
| **Secret Scanning** | Skip | Enable | Enable |
| **Push Protection** | Skip | Enable | Enable |
| **CODEOWNERS** | Skip | Create | Create |
| **Allow Forking** | Skip | Enable | Enable |
| **Auto-merge** | N/A | Disable | Disable |

## Troubleshooting

### gh command not found

```bash
brew install gh
gh auth login
```

### Branch protection failed

- Admin permission required for repository
- For organizations, check organization settings

### CODEOWNERS not working

- Enable "Require review from Code Owners" in branch protection
- Settings > Branches > Branch protection rules > main
