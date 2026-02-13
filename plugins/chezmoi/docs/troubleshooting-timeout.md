# Troubleshooting chezmoi status Timeout

This guide helps diagnose and resolve slow `chezmoi status` performance.

## Overview

The shell sync checker runs `chezmoi status` with a timeout (default: 5 seconds). If the command takes too long, you'll see:

```
⚠ chezmoi status timed out (>5s)
   → Run: /chezmoi:diagnose-timeout to investigate
```

## Quick Diagnosis

Run the diagnostic command:

```
/chezmoi:diagnose-timeout
```

This measures timing for:
- Template expansion (1Password API, Age decryption)
- Git operations
- Overall `chezmoi status` performance

## Common Causes and Solutions

### 1. 1Password API Calls (High Impact)

**Symptom**: Template expansion takes >2 seconds

**Cause**: `{{ onepasswordRead }}` functions in templates make API calls to 1Password

**Solutions**:

#### Option A: Increase Timeout (Quick Fix)
```bash
# Add to ~/.zshrc
export CHEZMOI_STATUS_TIMEOUT=10  # seconds
```

#### Option B: Reduce API Calls (Performance Fix)
```bash
# Audit template usage
chezmoi execute-template --init --promptOnce=false < /dev/null

# Example: Replace multiple onepasswordRead calls with a single document fetch
# Before (slow):
{{ (onepasswordRead "op://vault/item/field1").value }}
{{ (onepasswordRead "op://vault/item/field2").value }}

# After (faster):
{{ $item := onepasswordDocument "item" }}
{{ $item.field1 }}
{{ $item.field2 }}
```

#### Option C: Use Environment Variables
```bash
# Store secrets in environment instead of 1Password API
# .zshrc
export MY_SECRET="value"

# Template
{{ .Env.MY_SECRET }}
```

### 2. Age Encryption (Medium-High Impact)

**Symptom**: Template expansion takes 1-3 seconds

**Cause**: Age decryption overhead when reading encrypted files

**Solutions**:

#### Option A: Increase Timeout
```bash
export CHEZMOI_STATUS_TIMEOUT=8
```

#### Option B: Optimize Encrypted Files
```bash
# Audit encrypted files
chezmoi managed | grep -i encrypt

# Consider:
# - Decrypt files that don't contain secrets
# - Combine multiple small encrypted files into one
# - Use .chezmoiignore for files that don't need tracking
```

#### Option C: Use Selective Encryption
```bash
# Only encrypt truly sensitive files
# Example .chezmoiignore:
# Ignore large files that slow down status checks
large-binary-file
*.log
```

### 3. Git Operations (Low-Medium Impact)

**Symptom**: Git status takes >0.5 seconds

**Cause**: Large repository or many untracked files

**Solutions**:

#### Check Repository Size
```bash
du -sh ~/.local/share/chezmoi/.git
git -C ~/.local/share/chezmoi count-objects -vH
```

#### Optimize Git Repository
```bash
# Clean up and repack
git -C ~/.local/share/chezmoi gc --aggressive --prune=now
```

#### Add .chezmoiignore
```bash
# ~/.local/share/chezmoi/.chezmoiignore
# Ignore files that don't need tracking
.DS_Store
*.log
node_modules/
```

### 4. Network Latency (Variable Impact)

**Symptom**: Intermittent timeouts, 1Password API calls fail

**Cause**: Slow network connection to 1Password servers

**Solutions**:

#### Check Network Connectivity
```bash
curl -w "@-" -o /dev/null -s https://my.1password.com <<'EOF'
time_namelookup:  %{time_namelookup}
time_connect:     %{time_connect}
time_total:       %{time_total}
EOF
```

#### Increase Timeout for Slow Networks
```bash
# Conservative timeout for slow networks
export CHEZMOI_STATUS_TIMEOUT=15
```

#### Use Offline Mode (Advanced)
```bash
# Cache 1Password values as environment variables
# Run once per session:
eval $(op signin)
export MY_SECRET=$(op read "op://vault/item/field")

# Update templates to use .Env instead of onepasswordRead
```

## Configuration Examples

### Minimal (Fast Performance)
```bash
# ~/.zshrc
# No timeout adjustment needed
# Avoid 1Password API in templates
# Minimal Age encryption
```

### Standard (Balanced)
```bash
# ~/.zshrc
export CHEZMOI_STATUS_TIMEOUT=8  # Allow some 1Password/Age overhead
```

### High Security (Slower)
```bash
# ~/.zshrc
export CHEZMOI_STATUS_TIMEOUT=15  # Allow extensive 1Password API + Age
```

## When Timeout is Normal vs. Concerning

### Normal (Expected)
- **3-8 seconds**: Multiple 1Password API calls + Age encryption
- **2-5 seconds**: Age encryption for many files
- **1-3 seconds**: Few 1Password calls or moderate encryption

### Concerning (Investigate)
- **>10 seconds**: Likely optimization opportunity
- **>15 seconds**: Significant performance issue
- **Highly variable**: Network or system resource issue

## Advanced: Profiling chezmoi

### Measure Template Expansion
```bash
time chezmoi execute-template < /dev/null
```

### Measure Status Check
```bash
time chezmoi status
```

### Trace chezmoi Operations
```bash
chezmoi --verbose status 2>&1 | grep -i "template\|encrypt\|1password"
```

## Best Practices

1. **Start with Diagnosis**: Run `/chezmoi:diagnose-timeout` before optimizing
2. **Measure Impact**: Test timeout changes with `time chezmoi status`
3. **Optimize Gradually**: Try quick fixes (increase timeout) before major changes
4. **Document Changes**: Note why you set specific timeout values
5. **Review Periodically**: Re-evaluate as your dotfiles evolve

## Related Commands

- `/chezmoi:diagnose-timeout` - Run diagnostic
- `/chezmoi:check` - Manual status check (no timeout)
- `chezmoi doctor` - Check chezmoi configuration

## Further Reading

- [chezmoi Performance](https://www.chezmoi.io/user-guide/frequently-asked-questions/performance/)
- [1Password CLI Performance](https://developer.1password.com/docs/cli/performance)
- [Age Encryption](https://github.com/FiloSottile/age)

## Still Having Issues?

If timeout persists after following this guide:

1. Run `/chezmoi:diagnose-timeout` and share output
2. Check `chezmoi doctor` for configuration issues
3. Consider filing an issue with timing details
