# Issue Draft for claudemarketplaces.com

**Target Repository**: https://github.com/mertbuilds/claudemarketplaces.com
**Issue Type**: Bug Report / Feature Request
**Priority**: Medium
**Affects**: All plugins with uppercase repository names

---

## Title

Case sensitivity issue: Recommended installation command fails for plugins with capital letters

---

## Description

When a GitHub repository uses uppercase letters in its name (e.g., `signalcompose/YPM`), the recommended installation command shown on claudemarketplaces.com does not work in Claude Code on macOS.

This creates a poor user experience where users copy the recommended command from the website, paste it into Claude Code, and encounter an error without understanding why.

---

## Steps to Reproduce

1. Create a Claude Code plugin with uppercase letters in the GitHub repository name
   - Example: `signalcompose/YPM` (capital "YPM")

2. Add `.claude-plugin/marketplace.json` to the repository:
   ```json
   {
     "name": "signalcompose-ypm",
     "description": "Signal Compose YPM - Multi-project progress tracking"
   }
   ```

3. Wait for claudemarketplaces.com to index the plugin (automatic, ~1 hour)

4. Search for the plugin on claudemarketplaces.com
   - Result appears in search: "signalcompose/YPM"

5. Copy the recommended installation command from search results:
   ```
   /plugin marketplace add signalcompose/YPM
   ```

6. Paste and run the command in Claude Code on macOS

7. Observe the error:
   ```
   Error: Failed to finalize marketplace cache.
   Technical details: ENOENT: no such file or directory, rename
   '/Users/username/.claude/plugins/marketplaces/signalcompose-YPM' ->
   '/Users/username/.claude/plugins/marketplaces/signalcompose-ypm'
   ```

---

## Expected Behavior

The recommended installation command shown on claudemarketplaces.com should use **lowercase** repository names to match Claude Code's internal processing:

```
/plugin marketplace add signalcompose/ypm
```

**OR** claudemarketplaces.com should display a warning when a repository name contains uppercase letters:

```
⚠️ Note: Use lowercase when installing: /plugin marketplace add signalcompose/ypm
```

---

## Actual Behavior

- **Search results display**: `signalcompose/YPM` (uppercase, matching GitHub)
- **Recommended command**: `/plugin marketplace add signalcompose/YPM` (fails on macOS)
- **Working command**: `/plugin marketplace add signalcompose/ypm` (succeeds, but not shown)
- **Detail page**: 404 (requires 5+ stars, but relevant for future)

**Result**: Users encounter an error and don't understand the workaround.

---

## Root Cause Analysis

### claudemarketplaces.com Behavior

1. **Indexing**: Scans GitHub for repositories with `.claude-plugin/marketplace.json`
2. **Search index**: Shows repository name as-is from GitHub (`signalcompose/YPM`)
3. **Recommended command**: Constructed from repository name (uppercase preserved)

### Claude Code Behavior

1. **Input**: Receives `/plugin marketplace add signalcompose/YPM`
2. **Clone**: Creates directory `~/.claude/plugins/marketplaces/signalcompose-YPM`
3. **Internal processing**: Attempts to rename to lowercase `signalcompose-ypm`
4. **Filesystem conflict**: macOS APFS is case-insensitive but case-preserving
   - `signalcompose-YPM` and `signalcompose-ypm` are considered identical
   - `rename()` system call fails with `ENOENT`

### The Gap

claudemarketplaces.com displays repository names from GitHub (which allows uppercase), but Claude Code requires lowercase for internal processing. This mismatch causes installation failures on macOS.

---

## Proposed Solutions

### Solution 1: Normalize Repository Names (Recommended)

**Implementation**: Automatically convert repository names to lowercase when generating installation commands.

**Changes**:
```javascript
// Before
const command = `/plugin marketplace add ${owner}/${repo}`;

// After
const command = `/plugin marketplace add ${owner.toLowerCase()}/${repo.toLowerCase()}`;
```

**Pros**:
- Fixes issue for all plugins
- No user confusion
- Works immediately

**Cons**:
- Repository name in search results may not match command (minor discoverability issue)

---

### Solution 2: Add Warning for Uppercase Names

**Implementation**: Detect uppercase letters in repository names and show a warning.

**Changes**:
```html
<!-- Example warning UI -->
<div class="installation-warning">
  ⚠️ This repository name contains uppercase letters.
  Use lowercase when installing: <code>/plugin marketplace add signalcompose/ypm</code>
</div>
```

**Pros**:
- Educates users about the limitation
- Preserves visual consistency with GitHub

**Cons**:
- Additional UI complexity
- Users may still copy the wrong command

---

### Solution 3: Update Documentation

**Implementation**: Add note to marketplace submission guide about case sensitivity.

**Changes**:
```markdown
## Best Practices for Marketplace Plugins

- **Use lowercase repository names**: Claude Code normalizes names to lowercase.
  Uppercase letters may cause installation issues on macOS.

  ✅ Good: `signalcompose/ypm`
  ❌ Avoid: `signalcompose/YPM`
```

**Pros**:
- Prevents future submissions with uppercase
- Low implementation effort

**Cons**:
- Doesn't fix existing plugins
- Requires plugin authors to rename (GitHub operation)

---

## Recommended Approach

**Combination of Solutions 1 + 3**:

1. **Immediate fix** (Solution 1): Normalize all installation commands to lowercase
2. **Long-term prevention** (Solution 3): Document best practices for plugin authors

This provides immediate relief for users while preventing future issues.

---

## Environment

- **Platform**: macOS (APFS filesystem)
  - Case-insensitive: `YPM` and `ypm` treated as same
  - Case-preserving: Original case maintained
- **Claude Code**: 2.1.3 (Homebrew)
- **Affected Plugin**: signalcompose/YPM (Your Project Manager)
- **Browser**: Any (issue is server-side)

---

## Additional Context

### Impact

This issue affects **any plugin** with uppercase letters in the GitHub repository name. It's particularly problematic on macOS, which represents approximately 50% of the developer market.

### User Experience Flow

**Current** (broken):
```
Search "YPM" → See "signalcompose/YPM" → Copy command →
Paste in Claude Code → Error (macOS) → Confusion
```

**Desired**:
```
Search "YPM" → See "signalcompose/YPM" → Copy lowercase command →
Paste in Claude Code → Success
```

### Why This Matters

- **Discoverability**: Users find plugins via search but can't install them
- **First impressions**: Installation failure is a poor first experience
- **Support burden**: Plugin authors receive confused user reports
- **Adoption**: Friction reduces plugin adoption rates

---

## Related Issues

- **Claude Code bug report**: To be submitted separately to Anthropic
- **GitHub repository naming**: GitHub allows uppercase, but ecosystem best practices favor lowercase

---

## Workaround (For Users)

If you encounter this error:

1. Manually convert the repository name to lowercase:
   ```
   /plugin marketplace add signalcompose/ypm
   ```

2. Installation should succeed

---

## Workaround (For Plugin Authors)

1. **Option A**: Rename your GitHub repository to lowercase
   - GitHub Settings → Repository name → Change to lowercase
   - GitHub provides automatic redirects for 1 year

2. **Option B**: Add installation instructions to your README:
   ```markdown
   > ⚠️ **Important**: Use lowercase when installing:
   > `/plugin marketplace add owner/repo` (all lowercase)
   ```

---

## Testing Checklist

After implementing a fix:

- [ ] Test with repository name: `signalcompose/YPM` (mixed case)
- [ ] Test with repository name: `signalcompose/ypm` (lowercase)
- [ ] Test with repository name: `signalcompose/Ypm` (title case)
- [ ] Verify installation succeeds on macOS
- [ ] Verify installation succeeds on Linux
- [ ] Verify installation succeeds on Windows

---

## Attachments

- [Repository Rename Analysis](repository-rename-analysis.md) - Comprehensive impact analysis for YPM
- Error screenshot (if available)
- Terminal output logs

---

## Contact

If you need more information about this issue:

- **Plugin Author**: Hiroshi Yamato (@yamato)
- **Affected Plugin**: https://github.com/signalcompose/your-project-manager
- **Email**: (if available)

---

**Thank you for maintaining claudemarketplaces.com!** This platform is incredibly valuable for the Claude Code community. 🙏
