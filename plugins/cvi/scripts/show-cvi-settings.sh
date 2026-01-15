#!/bin/bash
# UserPromptSubmit: Show CVI settings (Claude interprets via skill knowledge)
CONFIG="$HOME/.cvi/config"
[ -f "$CONFIG" ] || exit 0
grep -E "^(CVI_ENABLED|VOICE_LANG|ENGLISH_PRACTICE)=" "$CONFIG" 2>/dev/null | sed 's/^/CVI: /'
