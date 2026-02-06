# Phase 3: Setup Mode Selection

Based on existing setup, ask user which mode to proceed with:

## If Existing Setup Found

```
Your chezmoi is already configured.
What would you like to do?

1. Check current status (/chezmoi:check)
2. Reconfigure from scratch (will backup existing config)
3. Cancel
```

## If No Existing Setup

```
No existing chezmoi setup found.
What would you like to do?

1. New setup (first machine) - Create new dotfiles repository
2. Clone existing (second+ machine) - Clone from existing repository
3. Cancel
```
