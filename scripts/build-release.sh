#!/bin/bash

# HelaService Release Build Script
# Usage: ./scripts/build-release.sh [platform]
# Platforms: android, ios, web, all

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PLATFORM=${1:-all}
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HelaService Release Build             ${NC}"
echo -e "${BLUE}  Version: $VERSION                     ${NC}"
echo -e "${BLUE}  Platform: $PLATFORM                   ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Pre-build checks
echo -e "${YELLOW}Running pre-build checks...${NC}"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter not found${NC}"
    exit 1
fi

# Check environment files
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Run: cp .env.example .env && edit with your credentials"
    exit 1
fi

# Check Firebase config
if [ "$PLATFORM" == "android" ] || [ "$PLATFORM" == "all" ]; then
    if [ ! -f "android/app/google-services.json" ]; then
        echo -e "${RED}Error: android/app/google-services.json not found${NC}"
        exit 1
    fi
fi

if [ "$PLATFORM" == "ios" ] || [ "$PLATFORM" == "all" ]; then
    if [ ! -f "ios/Runner/GoogleService-Info.plist" ]; then
        echo -e "${RED}Error: ios/Runner/GoogleService-Info.plist not found${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Pre-build checks passed${NC}"
echo ""

# Clean and get dependencies
echo -e "${YELLOW}Cleaning and getting dependencies...${NC}"
flutter clean
flutter pub get
echo -e "${GREEN}✓ Dependencies ready${NC}"
echo ""

# Build Android
build_android() {
    echo -e "${BLUE}Building Android AppBundle...${NC}"
    
    cd android
    
    # Check for signing config
    if [ ! -f "key.properties" ]; then
        echo -e "${RED}Error: android/key.properties not found${NC}"
        echo "Create key.properties with your keystore info"
        exit 1
    fi
    
    cd ..
    
    # Build AppBundle
    flutter build appbundle --release
    
    # Build APK for testing
    flutter build apk --release
    
    echo -e "${GREEN}✓ Android builds complete${NC}"
    echo ""
    echo "Outputs:"
    echo "  AppBundle: build/app/outputs/bundle/release/app-release.aab"
    echo "  APK:       build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    
    # Show file sizes
    ls -lh build/app/outputs/bundle/release/app-release.aab
    ls -lh build/app/outputs/flutter-apk/app-release.apk
}

# Build iOS
build_ios() {
    echo -e "${BLUE}Building iOS...${NC}"
    
    cd ios
    
    # Install pods
    if [ ! -d "Pods" ]; then
        pod install
    fi
    
    cd ..
    
    # Build iOS
    flutter build ios --release
    
    echo -e "${GREEN}✓ iOS build complete${NC}"
    echo ""
    echo "Output: build/ios/iphoneos/Runner.app"
    echo ""
    echo "Next steps:"
    echo "  1. Open ios/Runner.xcworkspace in Xcode"
    echo "  2. Product → Archive"
    echo "  3. Upload to App Store Connect"
    echo ""
}

# Build Web
build_web() {
    echo -e "${BLUE}Building Web...${NC}"
    
    flutter build web --release
    
    echo -e "${GREEN}✓ Web build complete${NC}"
    echo ""
    echo "Output: build/web/"
    echo ""
    echo "Deploy with: firebase deploy --only hosting"
    echo ""
}

# Run builds based on platform
case $PLATFORM in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    web)
        build_web
        ;;
    all)
        build_android
        build_ios
        build_web
        ;;
    *)
        echo "Usage: ./scripts/build-release.sh [android|ios|web|all]"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Build Complete!                       ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""

if [ "$PLATFORM" == "android" ] || [ "$PLATFORM" == "all" ]; then
    echo "Android:"
    echo "  1. Test APK on device"
    echo "  2. Upload AAB to Play Console"
    echo "  3. Or: cd android && fastlane deploy_internal"
    echo ""
fi

if [ "$PLATFORM" == "ios" ] || [ "$PLATFORM" == "all" ]; then
    echo "iOS:"
    echo "  1. Open Xcode: open ios/Runner.xcworkspace"
    echo "  2. Product → Archive"
    echo "  3. Upload to App Store Connect"
    echo "  4. Or: cd ios && fastlane deploy_beta"
    echo ""
fi

if [ "$PLATFORM" == "web" ] || [ "$PLATFORM" == "all" ]; then
    echo "Web:"
    echo "  1. Test locally: firebase emulators:start"
    echo "  2. Deploy: firebase deploy --only hosting"
    echo ""
fi

echo -e "${BLUE}Version: $VERSION${NC}"
echo ""
