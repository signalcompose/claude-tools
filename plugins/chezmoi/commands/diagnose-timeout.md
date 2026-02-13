---
description: Diagnose slow chezmoi status performance and identify bottlenecks
---

# Diagnose chezmoi status Timeout

This command helps diagnose why `chezmoi status` is slow by measuring timing for different operations.

## Usage

以下のBashコマンドを**即座に実行**してください:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/diagnose-timeout.sh
```

## What it measures

The diagnostic script measures:

1. **Template Expansion**: Time to expand templates (includes 1Password API, Age decryption)
2. **Git Status**: Time for git operations in the chezmoi source directory
3. **Overall chezmoi status**: Total time for the full status check
4. **Network Connectivity**: Checks if network latency affects 1Password API

## Output Example

```
━━━ [chezmoi] Timeout Diagnosis ━━━

1. Template expansion: 3.2s
   → High (includes 1Password API, Age decryption)

2. Git status: 0.1s
   → Normal

3. chezmoi status (total): 3.8s
   → Timeout threshold: 5s

Bottleneck: Template expansion (1Password/Age)

Recommendations:
- Increase timeout: export CHEZMOI_STATUS_TIMEOUT=10
- Optimize 1Password API calls
- Consider caching template results

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Common Causes

| Cause | Impact | Solution |
|-------|--------|----------|
| 1Password API | High | Cache results, reduce API calls |
| Age encryption | Medium-High | Optimize encrypted files |
| Git operations | Low-Medium | Check repository size |
| Network latency | Variable | Use offline mode or caching |

## Next Steps

After diagnosing:
1. If timeout is acceptable: Increase `CHEZMOI_STATUS_TIMEOUT`
2. If bottleneck identified: See `docs/troubleshooting-timeout.md` for solutions
3. If performance unexplained: Consider optimizing chezmoi configuration

## Related

- `CHEZMOI_STATUS_TIMEOUT` environment variable
- `/chezmoi:check` - Manual status check
- `docs/troubleshooting-timeout.md` - Detailed troubleshooting guide
