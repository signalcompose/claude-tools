# Understanding chezmoi diff Output

**Important**: `chezmoi diff` shows "what would happen if you run `chezmoi apply`".

- `-` lines = Current **local** file content (destination)
- `+` lines = **Chezmoi source** content (what would be applied)

## Example

```diff
-    "plugin-x": true,
-    "plugin-y": true
+    "plugin-x": true
```

**Interpretation**: Local has `plugin-y`, but chezmoi source does not.

| Situation | Action |
|-----------|--------|
| Local has changes you want to keep | Run `/chezmoi:commit` to push to source |
| Source has updates you want | Run `chezmoi apply` to apply to local |
