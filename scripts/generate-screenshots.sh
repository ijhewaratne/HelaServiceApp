#!/bin/bash

# HelaService Screenshot Generation Script
# Uses Flutter integration tests to generate screenshots

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DEVICE=${1:-all}
OUTPUT_DIR="store_assets/screenshots"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  HelaService Screenshot Generator      ${NC}"
echo -e "${BLUE}  Device: $DEVICE                        ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

mkdir -p $OUTPUT_DIR

# Android screenshots
generate_android() {
    echo -e "${YELLOW}Generating Android screenshots...${NC}"
    
    # Build screenshot test
    flutter drive \
        --driver=test_driver/screenshot_driver.dart \
        --target=integration_test/screenshot_test.dart \
        --flavor=screenshot \
        --dart-define=SCREENSHOT_MODE=true
    
    echo -e "${GREEN}✓ Android screenshots generated${NC}"
}

# iOS screenshots
generate_ios() {
    echo -e "${YELLOW}Generating iOS screenshots...${NC}"
    
    # Use simulator for screenshots
    # iPhone 14 Pro Max (6.7")
    flutter drive \
        --driver=test_driver/screenshot_driver.dart \
        --target=integration_test/screenshot_test.dart \
        --device-id="iPhone 14 Pro Max"
    
    # iPhone 14 Pro (6.1")
    flutter drive \
        --driver=test_driver/screenshot_driver.dart \
        --target=integration_test/screenshot_test.dart \
        --device-id="iPhone 14 Pro"
    
    echo -e "${GREEN}✓ iOS screenshots generated${NC}"
}

# Screenshot test template
create_screenshot_test() {
    if [ ! -f "integration_test/screenshot_test.dart" ]; then
        mkdir -p integration_test test_driver
        
        cat > integration_test/screenshot_test.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:home_service_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot auth screen', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // Wait for auth screen
    await tester.pumpAndSettle();
    
    // Take screenshot
    await takeScreenshot(tester, '01_auth_screen');
  });

  testWidgets('screenshot service selection', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Navigate to customer home
    // ... navigation logic
    
    await takeScreenshot(tester, '02_service_selection');
  });

  testWidgets('screenshot booking form', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Navigate to booking
    // ... navigation logic
    
    await takeScreenshot(tester, '03_booking_form');
  });

  testWidgets('screenshot worker dashboard', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Navigate to worker dashboard
    // ... navigation logic
    
    await takeScreenshot(tester, '04_worker_dashboard');
  });

  testWidgets('screenshot payment', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Navigate to payment
    // ... navigation logic
    
    await takeScreenshot(tester, '05_payment');
  });
}

Future<void> takeScreenshot(WidgetTester tester, String name) async {
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  await binding.convertFlutterSurfaceToImage();
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}
EOF

        cat > test_driver/screenshot_driver.dart << 'EOF'
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
EOF

        echo -e "${GREEN}Created screenshot test template${NC}"
    fi
}

# Manual screenshot guide
show_manual_guide() {
    echo ""
    echo -e "${YELLOW}Manual Screenshot Guide:${NC}"
    echo ""
    echo "Required Screenshots:"
    echo ""
    echo "1. Phone Authentication Screen"
    echo "   - Show phone input with +94 prefix"
    echo "   - Clean, welcoming UI"
    echo ""
    echo "2. Service Selection"
    echo "   - Grid of 5 services"
    echo "   - Icons and names visible"
    echo ""
    echo "3. Booking Form"
    echo "   - Date/time selection"
    echo "   - Map with location"
    echo "   - Price estimate"
    echo ""
    echo "4. Worker Dashboard"
    echo "   - Online toggle visible"
    echo "   - Stats cards"
    echo "   - Professional look"
    echo ""
    echo "5. Payment Screen"
    echo "   - Amount display"
    echo "   - Payment methods"
    echo "   - Security indicators"
    echo ""
    echo "6. Live Tracking (optional)"
    echo "   - Map with worker location"
    echo "   - Progress indicator"
    echo ""
    echo "Screenshot Sizes:"
    echo ""
    echo "Android:"
    echo "  Phone:  1080x1920 or 1080x2400"
    echo "  Tablet:  2048x2732"
    echo ""
    echo "iOS:"
    echo "  6.7\" (iPhone 14 Pro Max): 1290x2796"
    echo "  6.1\" (iPhone 14 Pro):     1179x2556"
    echo "  5.5\" (iPhone 8 Plus):     1242x2208"
    echo "  iPad Pro:                  2048x2732"
    echo ""
}

# Main
case $DEVICE in
    android)
        create_screenshot_test
        generate_android
        ;;
    ios)
        create_screenshot_test
        generate_ios
        ;;
    template)
        create_screenshot_test
        echo -e "${GREEN}Screenshot test template created${NC}"
        echo "Edit integration_test/screenshot_test.dart to customize"
        ;;
    guide)
        show_manual_guide
        ;;
    *)
        echo "Usage: ./scripts/generate-screenshots.sh [android|ios|template|guide]"
        echo ""
        echo "Options:"
        echo "  android  - Generate Android screenshots"
        echo "  ios      - Generate iOS screenshots"
        echo "  template - Create screenshot test template"
        echo "  guide    - Show manual screenshot guide"
        echo ""
        show_manual_guide
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Screenshot generation complete!${NC}"
echo ""
echo "Screenshots saved to: $OUTPUT_DIR"
echo ""
