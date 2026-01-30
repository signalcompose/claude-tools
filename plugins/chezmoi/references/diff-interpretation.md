# Chezmoi Diff Interpretation Guide

<!--
🚨 CRITICAL FOR CLAUDE - THIS IS THE AUTHORITATIVE REFERENCE 🚨

Read this file completely before interpreting any `chezmoi diff` output.
The `-` symbol does NOT mean "deleted" in chezmoi context!
-->

## Core Concept: State Comparison, Not Change Log

`chezmoi diff` shows a **state comparison** between two locations:
- **Local** = The actual dotfiles on your system (e.g., `~/.zshrc`)
- **Source** = The chezmoi repository (e.g., `~/.local/share/chezmoi/`)

This is fundamentally different from `git diff` which shows changes over time.

## Symbol Meanings

| Symbol | What it represents | Mental model |
|--------|-------------------|--------------|
| `-` | Content in **LOCAL** file | "LOCAL HAS THIS" |
| `+` | Content in **SOURCE** repo | "SOURCE HAS THIS" |

### Critical Warning

The `-` symbol triggers an intuitive association with "deleted" or "removed".

**THIS IS WRONG for chezmoi diff!**

- `-` does NOT mean "was deleted"
- `-` means "exists in LOCAL"

## Direction of Operations

### `chezmoi apply` (Source → Local)
- Copies SOURCE content to LOCAL
- `-` lines would be removed from local
- `+` lines would be added to local

### `chezmoi commit` / `chezmoi add` (Local → Source)
- Copies LOCAL content to SOURCE
- `-` lines will be added to source
- `+` lines will be removed from source (replaced by local)

## Interpretation Table

| Diff Pattern | Meaning | For `/chezmoi:commit` |
|--------------|---------|----------------------|
| `-` only (no `+`) | Local has content that source lacks | Content will be **ADDED** to source |
| `+` only (no `-`) | Source has content that local lacks | Content will be **REMOVED** from source |
| `-` and `+` pair | Content differs | Source will be **UPDATED** with local version |

## Reporting to User

### Correct Expressions

When reporting changes detected by `chezmoi diff`:

**For `-` only lines (local has, source lacks):**
- "ローカルに `X` があり、ソースにはありません → コミットでソースに追加されます"
- "Local has `X`, source doesn't → commit will add to source"

**For `+` only lines (source has, local lacks):**
- "ソースに `X` がありますが、ローカルにはありません → コミットでソースから削除されます"
- "Source has `X`, local doesn't → commit will remove from source"

**For `-` and `+` pairs (content differs):**
- "ローカルの変更でソースを更新します"
- "Local changes will update source"

### Wrong Expressions (DO NOT USE)

- ❌ "`X` が削除されました" — WRONG: `-` does not mean deleted
- ❌ "プラグインの削除をコミット" — WRONG: implies removal when it's addition
- ❌ "ローカルで削除された" — WRONG: confuses direction

## Worked Example

Given this `chezmoi diff` output:

```diff
-    "plugin-a": true,
-    "plugin-b": true
+    "plugin-a": true
```

### Step-by-Step Analysis

1. **Identify `-` lines**: `plugin-a` and `plugin-b` — these exist in LOCAL
2. **Identify `+` lines**: `plugin-a` only — this exists in SOURCE
3. **Compare**: `plugin-b` appears only in `-` (local), not in `+` (source)
4. **Conclusion**: Local has `plugin-b` that source doesn't have

### Correct Report

> "`plugin-b` がローカルに存在し、ソースにはありません。コミットするとソースに追加されます。"

### Wrong Report

> ❌ "`plugin-b` が削除されました" — This is backwards!

## Pre-Report Checklist

Before reporting `chezmoi diff` results to user:

1. [ ] Read the `-` lines as "LOCAL has this"
2. [ ] Read the `+` lines as "SOURCE has this"
3. [ ] For content only in `-`: Report as "will be ADDED to source"
4. [ ] For content only in `+`: Report as "will be REMOVED from source"
5. [ ] Never use "deleted" or "removed" for `-` lines
