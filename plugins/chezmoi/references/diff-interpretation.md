# Chezmoi Diff Interpretation Guide

## Recommended: Use `--reverse` Flag

For `/chezmoi:commit`, always use:

```bash
chezmoi diff --reverse
```

This produces **git-like output** that shows what commit will do:
- `-` lines will be **removed** from source
- `+` lines will be **added** to source

**No special interpretation rules needed.** Read it like a normal `git diff`.

---

## Why `--reverse`?

### Normal `chezmoi diff` (without flag)

Shows what `chezmoi apply` would do (source → local):
- `-` = content in LOCAL
- `+` = content in SOURCE

This is counterintuitive when committing (local → source).

### `chezmoi diff --reverse`

Shows what commit will do (local → source):
- `-` = will be **removed** from source
- `+` = will be **added** to source

This matches git diff semantics exactly.

---

## Example Comparison

Local has `hookify`, source has `sigcomintra`:

### Without `--reverse`:
```diff
-    "hookify@...": true,      ← Local has this
+    "sigcomintra@...": true,  ← Source has this
```
Confusing: `-` means "will be added to source" (counterintuitive)

### With `--reverse`:
```diff
-    "sigcomintra@...": true,  ← Will be removed from source
+    "hookify@...": true,      ← Will be added to source
```
Clear: Standard git diff semantics

---

## Reference: Normal Diff (Legacy)

If you must use `chezmoi diff` without `--reverse`:

| Symbol | Meaning | For commit |
|--------|---------|------------|
| `-` | Content in LOCAL | Will be **ADDED** to source |
| `+` | Content in SOURCE | Will be **REMOVED** from source |

**Note:** This is the opposite of git diff conventions.
