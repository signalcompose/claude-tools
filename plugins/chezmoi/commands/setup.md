---
description: "Interactive setup wizard for chezmoi dotfiles management with age encryption and 1Password integration"
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

Load and follow: !`cat ${CLAUDE_PLUGIN_ROOT}/skills/setup/references/phase-1-environment.md`

### Phase 2: Detect Existing Setup

Load and follow: !`cat ${CLAUDE_PLUGIN_ROOT}/skills/setup/references/phase-2-detect-existing.md`

### Phase 3: Mode Selection

Load and follow: !`cat ${CLAUDE_PLUGIN_ROOT}/skills/setup/references/phase-3-mode-selection.md`

### Phase 4: Setup Guide

Based on selection:
- **New setup (first machine)**: !`cat ${CLAUDE_PLUGIN_ROOT}/skills/setup/references/phase-4a-new-setup.md`
- **Clone existing (second+ machine)**: !`cat ${CLAUDE_PLUGIN_ROOT}/skills/setup/references/phase-4b-clone-existing.md`

### Phase 5: Verification

Load and follow: !`cat ${CLAUDE_PLUGIN_ROOT}/skills/setup/references/phase-5-verification.md`
