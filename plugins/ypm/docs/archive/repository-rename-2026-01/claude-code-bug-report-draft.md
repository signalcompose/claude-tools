# Bug Report Draft for Claude Code

**Target**: Anthropic Support / Claude Code GitHub Issues
**Issue Type**: Bug Report
**Component**: Plugin Marketplace - Installation
**Priority**: Medium
**Platform**: macOS (APFS filesystem)

---

## Title

macOS: Marketplace installation fails with uppercase repository names due to case-sensitive rename operation

---

## Environment

- **OS**: macOS 15.1 (Darwin 25.1.0)
- **Filesystem**: APFS (default: case-insensitive, case-preserving)
- **Claude Code Version**: 2.1.3
- **Installation Method**: Homebrew (`brew install claude`)
- **Shell**: Zsh 5.9
- **Affected Repository**: `signalcompose/YPM`

---

## Issue Description

When adding a Claude Code marketplace plugin whose GitHub repository name contains uppercase letters, the installation fails on macOS with a cryptic `ENOENT` error. The failure occurs during the "finalize marketplace cache" step when Claude Code attempts to rename a directory from mixed-case to lowercase on a case-insensitive filesystem.

This issue prevents macOS users (approximately 50% of the developer market) from installing plugins with uppercase repository names, creating a significant usability barrier.

---

## Error Message

```
Error: Failed to finalize marketplace cache.
Technical details: ENOENT: no such file or directory, rename
'/Users/yamato/.claude/plugins/marketplaces/signalcompose-YPM' ->
'/Users/yamato/.claude/plugins/marketplaces/signalcompose-ypm'
```

---

## Steps to Reproduce

### Minimal Reproduction

1. Install Claude Code on macOS via Homebrew:
   ```bash
   brew install claude
   ```

2. Launch Claude Code

3. Add a marketplace plugin with uppercase letters in the repository name:
   ```
   /plugin marketplace add signalcompose/YPM
   ```

4. Observe the error during installation

### Full Reproduction (Create Test Plugin)

1. Create a test repository on GitHub: `testuser/TestPlugin`

2. Add `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "testuser-testplugin",
     "description": "Test plugin for case sensitivity issue"
   }
   ```

3. Add `.claude-plugin/plugin.json`:
   ```json
   {
     "name": "testplugin",
     "version": "1.0.0"
   }
   ```

4. In Claude Code, run:
   ```
   /plugin marketplace add testuser/TestPlugin
   ```

5. Error occurs

6. Retry with lowercase:
   ```
   /plugin marketplace add testuser/testplugin
   ```

7. Installation succeeds

---

## Expected Behavior

Claude Code should successfully install plugins regardless of the case used in the repository name. One of the following behaviors would be acceptable:

### Option 1: Normalize Before Cloning (Recommended)
```javascript
// Normalize repository name to lowercase before any filesystem operations
const normalizedRepo = `${owner}/${repo}`.toLowerCase();
const clonePath = path.join(marketplacesDir, normalizedRepo.replace('/', '-'));
```

### Option 2: Handle Case-Insensitive Rename
```javascript
// Check if source and destination are the same (case-insensitive)
if (fs.existsSync(sourcePath)) {
  const sourceReal = fs.realpathSync(sourcePath);
  const destReal = path.resolve(destPath);

  if (sourceReal.toLowerCase() === destReal.toLowerCase()) {
    // Skip rename if paths are identical (case-insensitive)
    return;
  }
  fs.renameSync(sourcePath, destPath);
}
```

### Option 3: Better Error Message
```javascript
if (error.code === 'ENOENT' && process.platform === 'darwin') {
  const hasCaseDifference = source.toLowerCase() === dest.toLowerCase() && source !== dest;

  if (hasCaseDifference) {
    throw new Error(
      `Repository name contains uppercase letters which causes issues on macOS.\n` +
      `Please use lowercase: /plugin marketplace add ${repoName.toLowerCase()}`
    );
  }
}
```

---

## Actual Behavior

Claude Code performs the following steps:

1. **Clone repository** to `~/.claude/plugins/marketplaces/signalcompose-YPM`
   - Repository name case is preserved from user input

2. **Attempt normalization** by renaming to lowercase `signalcompose-ypm`
   - Calls `fs.renameSync(oldPath, newPath)` or equivalent

3. **Rename fails** on macOS APFS:
   - APFS treats `signalcompose-YPM` and `signalcompose-ypm` as **identical paths**
   - `rename()` system call returns `ENOENT` (No such file or directory)
   - Error: "Failed to finalize marketplace cache"

4. **User sees cryptic error** without clear guidance on resolution

---

## Root Cause Analysis

### Claude Code's Processing Flow

```
User Input: /plugin marketplace add signalcompose/YPM
    ↓
Parse repository: owner="signalcompose", repo="YPM"
    ↓
Clone to: ~/.claude/plugins/marketplaces/signalcompose-YPM
    ↓
Internal normalization: Attempt rename to signalcompose-ypm
    ↓
❌ rename() fails: ENOENT (source and dest are same on case-insensitive FS)
    ↓
Error propagates to user with technical details
```

### macOS APFS Filesystem Behavior

macOS APFS (default configuration) is:

- **Case-insensitive**: File lookups treat `YPM` and `ypm` as identical
- **Case-preserving**: Original case from creation is maintained
- **Comparison**: `stat("YPM")` and `stat("ypm")` return the same inode

When Claude Code attempts:
```c
rename("/path/signalcompose-YPM", "/path/signalcompose-ypm");
```

The system sees:
- Source: `/path/signalcompose-YPM` (exists)
- Dest: `/path/signalcompose-ypm` (resolves to same inode as source)
- Result: `ENOENT` because rename cannot move a file to itself

### Why Lowercase Works

```
User Input: /plugin marketplace add signalcompose/ypm
    ↓
Clone to: ~/.claude/plugins/marketplaces/signalcompose-ypm
    ↓
Internal normalization: Already lowercase, no rename needed
    ↓
✅ Success
```

---

## Impact Assessment

### Severity: Medium
- Blocks installation for affected plugins on macOS
- Workaround exists (use lowercase)
- Error message is unclear

### Frequency: Medium
- Affects all plugins with uppercase repository names
- macOS represents ~50% of developer market
- GitHub allows uppercase, so issue is common

### User Experience: Poor
- Cryptic error message
- No guidance on solution
- Users blame plugin author, not Claude Code
- Plugin authors receive confused support requests

---

## Proposed Fixes

### Fix 1: Normalize Repository Names Before Cloning (Recommended)

**Location**: Plugin marketplace installation handler

**Change**:
```javascript
// Before
async function addMarketplace(owner, repo) {
  const clonePath = path.join(MARKETPLACES_DIR, `${owner}-${repo}`);
  await git.clone(githubUrl, clonePath);
  // ... rest of installation
}

// After
async function addMarketplace(owner, repo) {
  // Normalize to lowercase BEFORE any filesystem operations
  const normalizedOwner = owner.toLowerCase();
  const normalizedRepo = repo.toLowerCase();
  const clonePath = path.join(MARKETPLACES_DIR, `${normalizedOwner}-${normalizedRepo}`);
  await git.clone(githubUrl, clonePath);
  // ... rest of installation (no rename needed)
}
```

**Benefits**:
- ✅ Fixes issue completely
- ✅ No special case handling needed
- ✅ Consistent with marketplace.json naming (already lowercase)
- ✅ Works on all platforms

**Drawbacks**:
- Directory name may not match repository name visually (minor)

---

### Fix 2: Case-Insensitive Rename Check

**Location**: Marketplace cache finalization

**Change**:
```javascript
function safeRename(source, dest) {
  // Check if source exists
  if (!fs.existsSync(source)) {
    throw new Error(`Source does not exist: ${source}`);
  }

  // On macOS/Windows, check for case-only difference
  if (process.platform === 'darwin' || process.platform === 'win32') {
    const sourceLower = source.toLowerCase();
    const destLower = dest.toLowerCase();

    if (sourceLower === destLower && source !== dest) {
      // Case-only rename on case-insensitive filesystem
      // Use temporary intermediate name
      const temp = `${dest}.tmp.${Date.now()}`;
      fs.renameSync(source, temp);
      fs.renameSync(temp, dest);
      return;
    }
  }

  // Normal rename
  fs.renameSync(source, dest);
}
```

**Benefits**:
- ✅ Handles edge case explicitly
- ✅ Backwards compatible
- ✅ Preserves intended behavior

**Drawbacks**:
- Requires extra filesystem operation (temporary rename)
- More complex code

---

### Fix 3: Improved Error Message

**Location**: Error handler for marketplace installation

**Change**:
```javascript
try {
  fs.renameSync(oldPath, newPath);
} catch (error) {
  if (error.code === 'ENOENT' && process.platform === 'darwin') {
    // Check if this is a case-only difference issue
    if (oldPath.toLowerCase() === newPath.toLowerCase() && oldPath !== newPath) {
      throw new Error(
        `Installation failed due to repository name case sensitivity.\n\n` +
        `The repository name contains uppercase letters which cause issues on macOS.\n` +
        `Please use lowercase when installing:\n\n` +
        `  /plugin marketplace add ${marketplaceName.toLowerCase()}\n\n` +
        `Technical details: macOS filesystem is case-insensitive.`
      );
    }
  }
  throw error; // Re-throw if not our special case
}
```

**Benefits**:
- ✅ Provides clear guidance to users
- ✅ Minimal code change
- ✅ Backwards compatible

**Drawbacks**:
- ❌ Doesn't fix the issue, only explains it

---

## Recommended Solution

**Combination of Fix 1 + Fix 3**:

1. **Primary fix** (Fix 1): Normalize repository names to lowercase before cloning
2. **Defensive fix** (Fix 3): Improve error message for any remaining edge cases

This approach:
- Prevents the issue from occurring (Fix 1)
- Provides clear guidance if any edge case arises (Fix 3)
- Maintains backwards compatibility
- Works on all platforms

---

## Workaround (For Users)

If you encounter this error:

```bash
# Fails
/plugin marketplace add signalcompose/YPM

# Works
/plugin marketplace add signalcompose/ypm
```

**Note**: You must use lowercase for both owner and repository name.

---

## Testing Recommendations

### Test Matrix

| Repository Name | macOS | Linux | Windows | Expected |
|-----------------|-------|-------|---------|----------|
| `owner/repo` | ✅ | ✅ | ✅ | Pass |
| `owner/Repo` | ⚠️ | ✅ | ⚠️ | After fix: Pass |
| `Owner/Repo` | ⚠️ | ✅ | ⚠️ | After fix: Pass |
| `OWNER/REPO` | ⚠️ | ✅ | ⚠️ | After fix: Pass |

### Automated Test Case

```javascript
describe('Marketplace installation', () => {
  it('should handle uppercase repository names on case-insensitive filesystems', async () => {
    const marketplace = 'testuser/TestPlugin'; // Mixed case

    // Should normalize to lowercase
    await addMarketplace(marketplace);

    // Verify installation directory uses lowercase
    const expectedPath = path.join(MARKETPLACES_DIR, 'testuser-testplugin');
    expect(fs.existsSync(expectedPath)).toBe(true);

    // Verify plugin loads correctly
    const plugins = await listPlugins();
    expect(plugins).toContain('testplugin');
  });

  it('should provide clear error message if normalization fails', async () => {
    // Simulate rename failure
    jest.spyOn(fs, 'renameSync').mockImplementation(() => {
      const error = new Error('ENOENT: no such file or directory');
      error.code = 'ENOENT';
      throw error;
    });

    await expect(addMarketplace('testuser/TestPlugin'))
      .rejects
      .toThrow(/use lowercase/i);
  });
});
```

---

## Additional Context

### Filesystem Details

**macOS APFS Default Settings**:
```bash
# Check filesystem case sensitivity
diskutil info / | grep "Case-sensitive"
# Output: Case-sensitive (Default): No
```

**Linux ext4** (case-sensitive):
- `YPM` and `ypm` are different files
- Issue does not occur

**Windows NTFS** (case-insensitive):
- Same issue as macOS can occur
- Less common for developer tools

### Related GitHub Discussions

- GitHub allows uppercase in repository names by design
- Ecosystem convention favors lowercase (npm, pip, cargo, etc.)
- Claude Code marketplace follows lowercase convention internally

### Related External Issues

- **claudemarketplaces.com**: Displays uppercase names from GitHub, causing user confusion
- **GitHub repository URLs**: Case-insensitive redirects work, but case-sensitive in API responses

---

## Attachments

- [Repository Rename Analysis](repository-rename-analysis.md) - Comprehensive impact analysis
- Error logs (if available)
- Screenshot of error message
- `~/.claude/logs/` diagnostic output

---

## Reproducibility

- **Reproducibility**: 100% on macOS with APFS (default configuration)
- **Frequency**: Every attempt with uppercase repository names
- **Regression**: Not applicable (existing behavior)

---

## Contact Information

**Reporter**: Hiroshi Yamato
- GitHub: @dropcontrol
- X: @yamato
- Website: https://yamato.dev/

**Affected Plugin**: YPM (Your Project Manager)
- Repository: https://github.com/signalcompose/your-project-manager
- Marketplace: signalcompose-ypm

---

## Priority Justification

**Priority: Medium**

**Why not High**:
- Workaround exists (use lowercase)
- Doesn't affect all users (Linux unaffected)
- Doesn't cause data loss or security issues

**Why not Low**:
- Affects ~50% of users (macOS)
- Poor user experience (cryptic error)
- Blocks plugin adoption
- Reflects poorly on Claude Code quality

**Suggested Timeline**: Fix in next minor release (2-4 weeks)

---

**Thank you for your attention to this issue!** I'm happy to provide additional information, test patches, or assist with implementation. 🙏
