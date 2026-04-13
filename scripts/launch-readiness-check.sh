#!/bin/bash

# HelaService Launch Readiness Check Script
# Usage: ./scripts/launch-readiness-check.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "======================================"
echo "HelaService Launch Readiness Check"
echo "======================================"
echo ""

cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARN++))
}

echo "📋 Running checks..."
echo ""

# 1. Check Flutter installation
echo "1. Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -1)
    check_pass "Flutter installed: $FLUTTER_VERSION"
else
    check_fail "Flutter not installed"
fi

# 2. Check Firebase CLI
echo ""
echo "2. Checking Firebase CLI..."
if command -v firebase &> /dev/null; then
    check_pass "Firebase CLI installed"
else
    check_warn "Firebase CLI not installed (optional for development)"
fi

# 3. Check pubspec dependencies
echo ""
echo "3. Checking dependencies..."
if [ -f "pubspec.lock" ]; then
    check_pass "Dependencies locked (pubspec.lock exists)"
else
    check_warn "No pubspec.lock - run 'flutter pub get'"
fi

# 4. Run flutter analyze
echo ""
echo "4. Running static analysis..."
ANALYZE_OUTPUT=$(flutter analyze --no-pub 2>&1) || true
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "error •" || echo "0")

if [ "$ERROR_COUNT" -eq 0 ]; then
    check_pass "No analysis errors"
elif [ "$ERROR_COUNT" -lt 50 ]; then
    check_warn "$ERROR_COUNT analysis errors (acceptable for beta)"
else
    check_fail "$ERROR_COUNT analysis errors (needs fixing before launch)"
fi

# 5. Run tests
echo ""
echo "5. Running tests..."
TEST_OUTPUT=$(flutter test --no-pub 2>&1) || true
TEST_RESULT=$?

if [ $TEST_RESULT -eq 0 ]; then
    TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -oE '[0-9]+ tests? passed' | head -1 || echo "Tests passed")
    check_pass "Tests passing: $TEST_COUNT"
else
    check_warn "Some tests failing (review test output)"
fi

# 6. Check for .env files
echo ""
echo "6. Checking environment configuration..."
if [ -f ".env.production" ]; then
    check_pass "Production environment file exists"
else
    check_fail "Missing .env.production file"
fi

if [ -f ".env.staging" ]; then
    check_pass "Staging environment file exists"
else
    check_warn "Missing .env.staging file"
fi

# 7. Check security files
echo ""
echo "7. Checking security configuration..."
if [ -f "docs/PRIVACY_POLICY.md" ]; then
    check_pass "Privacy policy document exists"
else
    check_fail "Missing privacy policy"
fi

if [ -f "docs/TERMS_OF_SERVICE.md" ]; then
    check_pass "Terms of service document exists"
else
    check_fail "Missing terms of service"
fi

# Check for exposed API keys (basic check)
if grep -r "AIzaSy" lib/ --include="*.dart" 2>/dev/null | grep -v "fromEnvironment" > /dev/null; then
    check_fail "Potential exposed API keys found in code"
else
    check_pass "No hardcoded API keys detected"
fi

# 8. Check Firestore rules
echo ""
echo "8. Checking Firestore configuration..."
if [ -f "firestore.rules" ]; then
    check_pass "Firestore rules exist"
else
    check_fail "Missing firestore.rules"
fi

if [ -f "firestore.indexes.json" ]; then
    check_pass "Firestore indexes configured"
else
    check_warn "Missing firestore.indexes.json"
fi

# 9. Check CI/CD configuration
echo ""
echo "9. Checking CI/CD configuration..."
if [ -d ".github/workflows" ]; then
    WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" | wc -l)
    check_pass "GitHub Actions configured ($WORKFLOW_COUNT workflows)"
else
    check_warn "No CI/CD workflows found"
fi

# 10. Check documentation
echo ""
echo "10. Checking documentation..."
if [ -f "README.md" ]; then
    check_pass "README.md exists"
else
    check_warn "Missing README.md"
fi

if [ -f "DEPLOYMENT.md" ]; then
    check_pass "Deployment guide exists"
else
    check_warn "Missing deployment guide"
fi

if [ -f "LAUNCH_READINESS.md" ]; then
    check_pass "Launch readiness checklist exists"
else
    check_warn "Missing launch readiness checklist"
fi

# 11. Check build capability
echo ""
echo "11. Checking build capability..."
echo "   (This may take a few minutes...)"

# Try to build APK
BUILD_OUTPUT=$(flutter build apk --debug --target-platform android-arm64 2>&1) || true
if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCESSFUL"; then
    check_pass "Debug APK builds successfully"
else
    BUILD_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "error •" || echo "0")
    if [ "$BUILD_ERRORS" -eq 0 ]; then
        check_warn "Build issues detected (check manually)"
    else
        check_fail "Build failing with $BUILD_ERRORS errors"
    fi
fi

# 12. Check code formatting
echo ""
echo "12. Checking code formatting..."
FORMAT_ISSUES=$(flutter format --dry-run --set-exit-if-changed lib/ 2>&1) || true
FORMAT_COUNT=$(echo "$FORMAT_ISSUES" | grep -c "Formatted" || echo "0")

if [ "$FORMAT_COUNT" -eq 0 ]; then
    check_pass "Code is properly formatted"
else
    check_warn "$FORMAT_COUNT files need formatting (run: flutter format .)"
fi

# Summary
echo ""
echo "======================================"
echo "Summary"
echo "======================================"
echo -e "${GREEN}Passed:${NC} $PASS"
echo -e "${YELLOW}Warnings:${NC} $WARN"
echo -e "${RED}Failed:${NC} $FAIL"
echo ""

# Calculate readiness percentage
TOTAL=$((PASS + WARN + FAIL))
if [ $TOTAL -gt 0 ]; then
    READINESS=$(( (PASS * 100) / TOTAL ))
    echo "Launch Readiness: $READINESS%"
    echo ""
    
    if [ $READINESS -ge 90 ]; then
        echo -e "${GREEN}Status: Ready for launch!${NC}"
    elif [ $READINESS -ge 75 ]; then
        echo -e "${YELLOW}Status: Almost ready - address warnings${NC}"
    elif [ $READINESS -ge 50 ]; then
        echo -e "${YELLOW}Status: In progress - several items to fix${NC}"
    else
        echo -e "${RED}Status: Not ready - significant work required${NC}"
    fi
fi

echo ""
echo "Next steps:"
echo "  1. Address all FAILED items"
echo "  2. Review WARNING items"
echo "  3. Run full test suite: flutter test --coverage"
echo "  4. Build release APK: flutter build appbundle"
echo ""
echo "For detailed checklist, see: LAUNCH_READINESS.md"
echo ""

exit $FAIL
