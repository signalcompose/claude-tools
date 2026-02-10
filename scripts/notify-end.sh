#!/bin/bash

# DEPRECATED: Stop hook voice notification
#
# This script is disabled because:
# 1. Stop hook executes BEFORE the response is written to transcript
# 2. This causes timing issues where [VOICE] tag cannot be reliably extracted
# 3. Voice notification is now handled by /cvi:speak command
#
# The /cvi:speak command:
# - Is called explicitly by Claude after writing the response
# - Includes macOS notification, Glass sound, and voice
# - Avoids double-play issues
#
# Stop hook now uses check-speak-called.sh to enforce /cvi:speak usage.

exit 0
