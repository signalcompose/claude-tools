#!/bin/bash
# SessionStart hook: Check required dependencies for CVI
# Warns user if any required commands are missing

# Required commands
REQUIRED_CMDS=("flock" "md5" "say" "afplay" "osascript" "jq")
MISSING_CMDS=()

# Check each required command
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_CMDS+=("$cmd")
    fi
done

# If any commands are missing, warn the user
if [ ${#MISSING_CMDS[@]} -gt 0 ]; then
    echo "================================================" >&2
    echo "⚠️  CVI: Missing Dependencies" >&2
    echo "================================================" >&2
    echo "" >&2
    echo "The following required commands are missing:" >&2
    for cmd in "${MISSING_CMDS[@]}"; do
        echo "  - $cmd" >&2
    done
    echo "" >&2
    echo "CVI voice notifications may not work correctly." >&2
    echo "" >&2

    # Platform-specific installation instructions
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "On macOS, most commands should be available by default." >&2
        echo "If 'jq' is missing, install it with:" >&2
        echo "  brew install jq" >&2
    else
        echo "CVI is designed for macOS and may not work on other platforms." >&2
    fi

    echo "================================================" >&2

    # Log the missing dependencies
    ERROR_LOG="$HOME/.cvi/error.log"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null
    echo "[${timestamp}] [check-dependencies.sh] Missing dependencies: ${MISSING_CMDS[*]}" >> "$ERROR_LOG"
fi

exit 0
