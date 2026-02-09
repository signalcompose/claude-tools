# Chezmoi Sync Error Handling

## Network Error

```
Cannot reach github.com
```

Please check your internet connection and try again.

## Git Conflict

```
Git conflict detected!
```

You have local changes that conflict with remote changes.
Resolve conflicts manually:

1. `cd ~/.local/share/chezmoi`
2. `git status`
3. Resolve conflicts
4. `git add .`
5. `git commit`
6. `chezmoi apply`

## Notes

- `chezmoi update` automatically runs git pull and chezmoi apply
- If there are uncommitted local changes, an error may occur
- In that case, run `/chezmoi:commit` first
