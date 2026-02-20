#!/usr/bin/env bash
# Validate audit report metrics against actual test/coverage output
# Usage: bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-audit-metrics.sh"

set -euo pipefail

# Use CLAUDE_PROJECT_DIR for portability across different projects
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_ROOT" || exit 1

REPORT_DIR="$PROJECT_ROOT/docs/research"
EXIT_CODE=0

echo "Validating audit report metrics..."
echo ""

# Run test:coverage once and capture output for both test count and coverage
echo "[1/3] Running tests with coverage..."
TEST_OUTPUT=$(npm run test:coverage 2>&1)

# 1. Test count validation
echo "[2/3] Checking test count..."
ACTUAL_TESTS=$(echo "$TEST_OUTPUT" | grep -Eo '^[[:space:]]*Tests[[:space:]]+[0-9]+ passed' | grep -Eo '[0-9]+' | head -1 || echo "0")
REPORTED_TESTS=$(grep -Eo 'Total Tests[^:]*:[[:space:]]*[0-9]+' "$REPORT_DIR"/*-audit-report.md 2>/dev/null | head -1 | grep -Eo '[0-9]+$' || echo "0")

if [ "$ACTUAL_TESTS" = "0" ] || [ "$REPORTED_TESTS" = "0" ]; then
  echo "⚠️  Could not extract test count (Actual=$ACTUAL_TESTS, Reported=$REPORTED_TESTS)"
elif [ "$ACTUAL_TESTS" != "$REPORTED_TESTS" ]; then
  echo "❌ Test count mismatch: Actual=$ACTUAL_TESTS, Reported=$REPORTED_TESTS"
  EXIT_CODE=1
else
  echo "✅ Test count matches: $ACTUAL_TESTS"
fi
echo ""

# 2. Coverage validation
echo "[3/3] Checking coverage..."
ACTUAL_COVERAGE=$(echo "$TEST_OUTPUT" | grep 'All files' | awk '{print $4}' | tr -d '%' || echo "0")
REPORTED_COVERAGE=$(grep -Eo 'Coverage[^:]*:[[:space:]]*[0-9]+\.[0-9]+' "$REPORT_DIR"/*-audit-report.md 2>/dev/null | head -1 | grep -Eo '[0-9]+\.[0-9]+' || echo "0")

if [ "$ACTUAL_COVERAGE" = "0" ] || [ "$REPORTED_COVERAGE" = "0" ]; then
  echo "⚠️  Could not extract coverage (Actual=$ACTUAL_COVERAGE%, Reported=$REPORTED_COVERAGE%)"
else
  # Allow ±0.1% tolerance for floating point
  # Use awk -v for safe variable passing (prevents injection)
  DIFF=$(awk -v a="$ACTUAL_COVERAGE" -v b="$REPORTED_COVERAGE" 'BEGIN {print a - b}' 2>/dev/null || echo "0")
  DIFF_ABS=$(awk -v d="$DIFF" 'BEGIN {print (d < 0) ? -d : d}' 2>/dev/null || echo "0")
  THRESHOLD=$(awk -v d="$DIFF_ABS" 'BEGIN {print (d > 0.1) ? 1 : 0}' 2>/dev/null || echo "0")

  if [ "$THRESHOLD" = "1" ]; then
    echo "❌ Coverage mismatch: Actual=$ACTUAL_COVERAGE%, Reported=$REPORTED_COVERAGE%"
    EXIT_CODE=1
  else
    echo "✅ Coverage matches: $ACTUAL_COVERAGE%"
  fi
fi
echo ""

# 4. Files modified count (from git diff) - non-critical
echo "[Bonus] Checking files modified..."
BASE_BRANCH=$(git merge-base HEAD main 2>/dev/null || git rev-parse HEAD~10)
ACTUAL_FILES=$(git diff --stat "$BASE_BRANCH" 2>/dev/null | tail -1 | grep -Eo '^[[:space:]]*[0-9]+' | grep -Eo '[0-9]+' || echo "0")
REPORTED_FILES=$(grep -Eo 'Files Modified[^:]*:[[:space:]]*[0-9]+' "$REPORT_DIR"/*-audit-report.md 2>/dev/null | head -1 | grep -Eo '[0-9]+' || echo "0")

if [ "$ACTUAL_FILES" = "0" ] || [ "$REPORTED_FILES" = "0" ]; then
  echo "⚠️  Could not extract files modified count (non-critical)"
elif [ "$ACTUAL_FILES" != "$REPORTED_FILES" ]; then
  echo "⚠️  Files modified mismatch: Actual=$ACTUAL_FILES, Reported=$REPORTED_FILES (non-critical)"
else
  echo "✅ Files modified matches: $ACTUAL_FILES"
fi
echo ""

if [ $EXIT_CODE -ne 0 ]; then
  echo "❌ Validation failed. Please update audit reports with correct metrics:"
  echo "   1. Re-run: npm run test:coverage"
  echo "   2. Update reports in $REPORT_DIR/"
  echo "   3. Re-run: bash \"\${CLAUDE_PLUGIN_ROOT}/scripts/validate-audit-metrics.sh\""
  exit 1
fi

echo "✅ All critical metrics validated successfully."
exit 0
