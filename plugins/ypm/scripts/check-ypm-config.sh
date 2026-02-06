#!/bin/bash
# YPM SessionStart Hook - Config and Status Checker
# Always exits 0 (informational only, never blocks session)

YPM_DIR="$HOME/.ypm"
CONFIG_FILE="$YPM_DIR/config.yml"
STATUS_FILE="$YPM_DIR/PROJECT_STATUS.md"
STALE_DAYS=7

output=""

# Check config.yml existence
if [ ! -f "$CONFIG_FILE" ]; then
  output="YPM: config.yml not found. Run /ypm:setup to initialize."
  echo "$output"
  exit 0
fi

# Check PROJECT_STATUS.md existence and freshness
if [ ! -f "$STATUS_FILE" ]; then
  output="YPM: PROJECT_STATUS.md not found. Run /ypm:project-status-update to scan projects."
  echo "$output"
  exit 0
fi

# Check if PROJECT_STATUS.md is stale
if [ "$(uname)" = "Darwin" ]; then
  last_modified=$(stat -f %m "$STATUS_FILE")
else
  last_modified=$(stat -c %Y "$STATUS_FILE")
fi

now=$(date +%s)
age_days=$(( (now - last_modified) / 86400 ))

if [ "$age_days" -ge "$STALE_DAYS" ]; then
  output="YPM: PROJECT_STATUS.md is ${age_days} days old. Consider running /ypm:project-status-update."
  echo "$output"
  exit 0
fi

echo "YPM: Ready (status updated ${age_days} day(s) ago)"
exit 0
