---
description: "TruffleHog Security Scan"
---

# TruffleHog Security Scan

Run TruffleHog security scan on the current project to detect exposed secrets.

## Overview

This command:
1. Checks TruffleHog installation
2. Scans the current project's Git history
3. Displays detected issues in detail

## Execution Steps

### STEP 1: Check TruffleHog Installation

```bash
which trufflehog
```

**If not installed**:
```
TruffleHog is not installed.

Install with:
brew install trufflehog

Run this command again after installation.
```
-> **Abort**

### STEP 2: Verify Git Repository

```bash
pwd
git rev-parse --show-toplevel
```

**If not a Git repository**:
```
Current directory is not a Git repository.

TruffleHog can only scan Git repositories.
```
-> **Abort**

### STEP 3: Execute TruffleHog Scan

```bash
trufflehog git file://. --json --no-update 2>/dev/null
```

**Options**:
- `git file://.`: Scan current directory
- `--json`: JSON output format
- `--no-update`: Disable auto-update check

**Timeout**: 60 seconds (adjust for large repos)

### STEP 4: Display Results

#### 4-1. Summary

```
## TruffleHog Security Scan Results

**Project**: <project-name>
**Path**: <path>
**Branch**: <branch>
**Scan Date**: <date>

**Results**:
- Issues detected: N
```

#### 4-2. Issues Detected

```
---

## Issues Detected

### Issue #1
- **File**: src/config/database.ts
- **Line**: 42
- **Type**: Generic API Key
- **Pattern**: AIza[0-9A-Za-z-_]{35}
- **Commit**: abc123def
- **Commit Date**: 2025-10-15 14:30
- **Recommended Actions**:
  - Revoke this API key
  - Move to environment variables
  - Remove from history with git-filter-repo

### Issue #2
...

---
```

#### 4-3. No Issues

```
## No Security Issues Detected

This project is clean.
No secret patterns were found.
```

### STEP 5: Suggest Next Actions

```
## Recommended Actions

### If issues detected
1. Review each detection
2. Determine if false positive
3. For real secrets:
   - Revoke/rotate the secret
   - Move to environment variables
   - Clean Git history (git-filter-repo)

### Cleaning Git History
```bash
# Install git-filter-repo
brew install git-filter-repo

# Remove file from history
git filter-repo --path <file-path> --invert-paths

# Or replace specific strings
git filter-repo --replace-text <replacements.txt>
```

### Regular Scanning
- Run before commits
- Consider adding to CI/CD pipeline
```

---

## Important Notes

### 1. False Positives

TruffleHog uses pattern matching, which may produce false positives:
- Test data dummy keys
- Sample code in documentation
- Already revoked keys

Always verify detected content.

### 2. History Scanning

TruffleHog scans entire Git history.
Even if current code has no secrets, past commits will be detected.

### 3. Performance

Large repositories or long histories may take time to scan.

### 4. Privacy

Scan results may include portions of sensitive data.
Be careful when sharing results in logs or chat.

---

**Always display results to user after running this command.**
