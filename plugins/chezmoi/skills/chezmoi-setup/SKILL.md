---
name: chezmoi-setup
description: |
  Interactive setup wizard for chezmoi dotfiles management with age encryption and 1Password integration.
  Use when: "set up chezmoi", "configure dotfiles", "initialize chezmoi",
  "chezmoi初期設定", "dotfiles設定", "1Password連携".
user-invocable: true
---

# Chezmoi Setup Wizard

Interactive setup guide for chezmoi dotfiles management with age encryption and 1Password integration.

## Overview

This wizard guides through 5 phases:
1. Environment check (tools availability)
2. Detect existing setup
3. Setup mode selection (new vs clone)
4. Guided setup (new machine or clone existing)
5. Verification

## Execution

### Phase 1: Environment Check

See [references/phase-1-environment.md](references/phase-1-environment.md) for tool detection steps.

### Phase 2: Detect Existing Setup

See [references/phase-2-detect-existing.md](references/phase-2-detect-existing.md) for existing configuration detection.

### Phase 3: Mode Selection

See [references/phase-3-mode-selection.md](references/phase-3-mode-selection.md) for setup mode options.

### Phase 4: Setup Guide

Based on selection:
- **New setup (first machine)**: See [references/phase-4a-new-setup.md](references/phase-4a-new-setup.md)
- **Clone existing (second+ machine)**: See [references/phase-4b-clone-existing.md](references/phase-4b-clone-existing.md)

### Phase 5: Verification

See [references/phase-5-verification.md](references/phase-5-verification.md) for post-setup verification.
