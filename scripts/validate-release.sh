#!/bin/bash

# HelaService Release Validation Script
# Checks if app is ready for store submission

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HelaService Release Validation        ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

check_error() {
    echo -e "${RED}✗ $1${NC}"
    ((ERRORS++))
}

check_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARNINGS++))
}

check_ok() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Check pubspec.yaml
echo -e "${YELLOW}Checking pubspec.yaml...${NC}"

if grep -q "version:" pubspec.yaml; then
    VERSION=$(grep "version:" pubspec.yaml | awk '{print $2}')
    check_ok "Version found: $VERSION"
else
    check_error "Version not found in pubspec.yaml"
fi

if grep -q "flutter_launcher_icons" pubspec.yaml; then
    check_ok "Launcher icons configuration found"
else
    check_warning "Launcher icons not configured"
fi

# Check for debug flags
echo ""
echo -e "${YELLOW}Checking for debug code...${NC}"

if grep -r "print(" lib/ --include="*.dart" | grep -v "//" > /dev/null 2>&1; then
    check_warning "Found print statements in code"
    grep -r "print(" lib/ --include="*.dart" | head -5
else
    check_ok "No print statements found"
fi

if grep -r "debugPrint" lib/ --include="*.dart" | grep -v "//" > /dev/null 2>&1; then
    check_warning "Found debugPrint statements in code"
else
    check_ok "No debugPrint statements found"
fi

# Check for test code
echo ""
echo -e "${YELLOW}Checking for test code...${NC}"

if grep -r "TODO" lib/ --include="*.dart" > /dev/null 2>&1; then
    check_warning "Found TODO comments"
    grep -r "TODO" lib/ --include="*.dart" | head -3
else
    check_ok "No TODO comments found"
fi

if grep -r "FIXME" lib/ --include="*.dart" > /dev/null 2>&1; then
    check_warning "Found FIXME comments"
else
    check_ok "No FIXME comments found"
fi

# Check environment files
echo ""
echo -e "${YELLOW}Checking environment configuration...${NC}"

if [ -f ".env" ]; then
    check_ok ".env file exists"
    
    if grep -q "PAYHERE_SANDBOX=true" .env; then
        check_warning "PayHere is in SANDBOX mode"
    else
        check_ok "PayHere is in PRODUCTION mode"
    fi
else
    check_error ".env file not found"
fi

# Check Firebase configuration
echo ""
echo -e "${YELLOW}Checking Firebase configuration...${NC}"

if [ -f "android/app/google-services.json" ]; then
    check_ok "Android Firebase config exists"
else
    check_error "android/app/google-services.json not found"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    check_ok "iOS Firebase config exists"
else
    check_error "ios/Runner/GoogleService-Info.plist not found"
fi

if [ -f "lib/firebase_options.dart" ]; then
    check_ok "Firebase options file exists"
else
    check_error "lib/firebase_options.dart not found"
fi

# Check signing configuration
echo ""
echo -e "${YELLOW}Checking signing configuration...${NC}"

if [ -f "android/key.properties" ]; then
    check_ok "Android signing config exists"
else
    check_error "android/key.properties not found"
fi

if [ -f "android/app/upload-keystore.jks" ] || [ -f "android/app/keystore.jks" ]; then
    check_ok "Android keystore exists"
else
    check_error "Android keystore not found"
fi

# Check store assets
echo ""
echo -e "${YELLOW}Checking store assets...${NC}"

if [ -f "store_assets/privacy_policy.md" ]; then
    check_ok "Privacy policy exists"
else
    check_error "store_assets/privacy_policy.md not found"
fi

if [ -f "store_assets/terms_of_service.md" ]; then
    check_ok "Terms of service exists"
else
    check_error "store_assets/terms_of_service.md not found"
fi

if [ -f "store_assets/android/full_description.txt" ]; then
    check_ok "Play Store description exists"
else
    check_warning "Play Store description not found"
fi

# Check icons
echo ""
echo -e "${YELLOW}Checking app icons...${NC}"

if [ -f "assets/icon/icon.png" ] || [ -f "assets/icon/app_icon.png" ]; then
    check_ok "App icon source exists"
else
    check_warning "App icon source not found in assets/icon/"
fi

# Check tests
echo ""
echo -e "${YELLOW}Checking tests...${NC}"

TEST_COUNT=$(find test -name "*_test.dart" 2>/dev/null | wc -l)
if [ $TEST_COUNT -gt 0 ]; then
    check_ok "Found $TEST_COUNT test files"
else
    check_warning "No test files found"
fi

# Run flutter analyze
echo ""
echo -e "${YELLOW}Running Flutter analyze...${NC}"

if flutter analyze > /tmp/flutter_analyze.log 2>&1; then
    check_ok "Flutter analyze passed"
else
    check_error "Flutter analyze found issues"
    cat /tmp/flutter_analyze.log | head -20
fi

# Check build capability
echo ""
echo -e "${YELLOW}Checking build capability...${NC}"

echo "Testing Android build..."
if flutter build apk --release > /tmp/build.log 2>&1; then
    check_ok "Android build successful"
    APK_SIZE=$(stat -f%z build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || stat -c%s build/app/outputs/flutter-apk/app-release.apk 2>/dev/null)
    APK_SIZE_MB=$((APK_SIZE / 1024 / 1024))
    echo "  APK size: ${APK_SIZE_MB}MB"
    
    if [ $APK_SIZE_MB -gt 150 ]; then
        check_warning "APK size exceeds 150MB"
    fi
else
    check_error "Android build failed"
    tail -20 /tmp/build.log
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Validation Summary                    ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
else
    echo -e "${RED}✗ $ERRORS error(s) found${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
fi

echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}App is ready for store submission!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}App is ready but has warnings to address${NC}"
    exit 0
else
    echo -e "${RED}Please fix errors before submitting to stores${NC}"
    exit 1
fi
