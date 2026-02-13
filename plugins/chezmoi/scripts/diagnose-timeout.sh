#!/usr/bin/env bash
# chezmoi status timeout diagnostic script
# Source: https://github.com/signalcompose/claude-tools

set -euo pipefail

CHEZMOI_DIR="$HOME/.local/share/chezmoi"
TIMEOUT_THRESHOLD=${CHEZMOI_STATUS_TIMEOUT:-5}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if chezmoi directory exists
if [[ ! -d "$CHEZMOI_DIR" ]]; then
  echo -e "${RED}✗${NC} chezmoi directory not found: $CHEZMOI_DIR"
  exit 1
fi

echo -e "${YELLOW}━━━ [chezmoi] Timeout Diagnosis ━━━${NC}"
echo ""

# Measure template expansion
echo -e "${CYAN}1. Template expansion${NC}"
TEMPLATE_START=$(date +%s.%N)
chezmoi execute-template < /dev/null >/dev/null 2>&1 || true
TEMPLATE_END=$(date +%s.%N)
TEMPLATE_TIME=$(awk "BEGIN {printf \"%.2f\", $TEMPLATE_END - $TEMPLATE_START}")

echo -e "   Time: ${TEMPLATE_TIME}s"
if (( $(awk "BEGIN {print ($TEMPLATE_TIME > 2.0)}") )); then
  echo -e "   ${YELLOW}→ High${NC} (includes 1Password API, Age decryption)"
elif (( $(awk "BEGIN {print ($TEMPLATE_TIME > 1.0)}") )); then
  echo -e "   ${YELLOW}→ Medium${NC}"
else
  echo -e "   ${GREEN}→ Normal${NC}"
fi
echo ""

# Measure git status
echo -e "${CYAN}2. Git status${NC}"
GIT_START=$(date +%s.%N)
git -C "$CHEZMOI_DIR" status --short >/dev/null 2>&1 || true
GIT_END=$(date +%s.%N)
GIT_TIME=$(awk "BEGIN {printf \"%.2f\", $GIT_END - $GIT_START}")

echo -e "   Time: ${GIT_TIME}s"
if (( $(awk "BEGIN {print ($GIT_TIME > 1.0)}") )); then
  echo -e "   ${YELLOW}→ High${NC} (check repository size)"
elif (( $(awk "BEGIN {print ($GIT_TIME > 0.5)}") )); then
  echo -e "   ${YELLOW}→ Medium${NC}"
else
  echo -e "   ${GREEN}→ Normal${NC}"
fi
echo ""

# Measure overall chezmoi status
echo -e "${CYAN}3. chezmoi status (total)${NC}"
STATUS_START=$(date +%s.%N)
chezmoi status >/dev/null 2>&1 || true
STATUS_END=$(date +%s.%N)
STATUS_TIME=$(awk "BEGIN {printf \"%.2f\", $STATUS_END - $STATUS_START}")

echo -e "   Time: ${STATUS_TIME}s"
echo -e "   Timeout threshold: ${TIMEOUT_THRESHOLD}s"

if (( $(awk "BEGIN {print ($STATUS_TIME > $TIMEOUT_THRESHOLD)}") )); then
  echo -e "   ${RED}→ Exceeds timeout${NC}"
elif (( $(awk "BEGIN {print ($STATUS_TIME > ($TIMEOUT_THRESHOLD * 0.8))}") )); then
  echo -e "   ${YELLOW}→ Close to timeout${NC}"
else
  echo -e "   ${GREEN}→ Within timeout${NC}"
fi
echo ""

# Network check
echo -e "${CYAN}4. Network connectivity${NC}"
if curl -s --connect-timeout 2 --max-time 3 https://my.1password.com >/dev/null 2>&1; then
  echo -e "   ${GREEN}→ 1Password reachable${NC}"
else
  echo -e "   ${YELLOW}→ 1Password unreachable${NC} (may affect template expansion)"
fi
echo ""

# Identify bottleneck
echo -e "${YELLOW}━━━ Analysis ━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

BOTTLENECK=""
if (( $(awk "BEGIN {print ($TEMPLATE_TIME > 2.0)}") )); then
  BOTTLENECK="Template expansion (1Password/Age)"
elif (( $(awk "BEGIN {print ($GIT_TIME > 1.0)}") )); then
  BOTTLENECK="Git operations"
elif (( $(awk "BEGIN {print ($STATUS_TIME > $TIMEOUT_THRESHOLD)}") )); then
  BOTTLENECK="Overall chezmoi status (unknown cause)"
else
  BOTTLENECK="None (performance is good)"
fi

echo -e "${CYAN}Bottleneck:${NC} $BOTTLENECK"
echo ""

# Recommendations
echo -e "${CYAN}Recommendations:${NC}"
if (( $(awk "BEGIN {print ($STATUS_TIME > $TIMEOUT_THRESHOLD)}") )); then
  echo -e "  • Increase timeout: ${GREEN}export CHEZMOI_STATUS_TIMEOUT=$((TIMEOUT_THRESHOLD + 5))${NC}"
fi

if (( $(awk "BEGIN {print ($TEMPLATE_TIME > 2.0)}") )); then
  echo -e "  • Optimize 1Password API calls (cache results, reduce usage)"
  echo -e "  • Consider reducing Age-encrypted files"
fi

if (( $(awk "BEGIN {print ($GIT_TIME > 1.0)}") )); then
  echo -e "  • Check repository size: ${GREEN}du -sh $CHEZMOI_DIR/.git${NC}"
  echo -e "  • Consider git gc: ${GREEN}git -C $CHEZMOI_DIR gc${NC}"
fi

echo ""
echo -e "${CYAN}For detailed guidance:${NC}"
echo -e "  Read: ${GREEN}docs/troubleshooting-timeout.md${NC}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
