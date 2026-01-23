#!/bin/bash
# check-kiro.sh - Verify Kiro CLI installation

set -e
set -o pipefail

if ! command -v kiro-cli &> /dev/null; then
    echo "ERROR: Kiro CLI is not installed." >&2
    echo "" >&2
    echo "To install Kiro CLI:" >&2
    echo "  Visit: https://kiro.dev" >&2
    echo "  Or download from AWS" >&2
    exit 1
fi

# Kiro CLI is available - verify it works
if ! KIRO_VERSION=$(kiro-cli --version 2>&1 | head -1); then
    echo "ERROR: Kiro CLI is installed but failed to execute." >&2
    echo "Output: $KIRO_VERSION" >&2
    echo "The installation may be corrupted or misconfigured." >&2
    exit 1
fi
echo "OK: Kiro CLI is available ($KIRO_VERSION)."
exit 0
