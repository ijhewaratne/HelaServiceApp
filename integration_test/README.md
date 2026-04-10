# HelaService Integration Tests

This directory contains end-to-end integration tests for the HelaService application.

## Test Structure

```
integration_test/
├── app_test.dart              # Main end-to-end flows
├── auth_flow_test.dart        # Authentication flows
├── customer_flow_test.dart    # Customer booking flows
├── worker_flow_test.dart      # Worker dashboard flows
├── navigation_test.dart       # Navigation and routing
└── README.md                  # This file
```

## Running Integration Tests

### Prerequisites

Ensure you have a device or emulator running:
```bash
flutter devices
```

### Run All Integration Tests

```bash
flutter test integration_test/
```

### Run Specific Test File

```bash
flutter test integration_test/auth_flow_test.dart
```

### Run on Specific Device

```bash
flutter test integration_test/ -d <device_id>
```

### Run with Verbose Output

```bash
flutter test integration_test/ --verbose
```

### Run in Release Mode (Faster)

```bash
flutter test integration_test/ --release
```

## Test Environment Setup

### Firebase Configuration

Integration tests use the actual Firebase configuration. Ensure:
1. `google-services.json` is in `android/app/`
2. `GoogleService-Info.plist` is in `ios/Runner/`
3. `firebase_options.dart` is in `lib/`

### Test Data

Tests assume certain UI text exists. If you change UI text, update tests accordingly.

### Mock Data

For reliable tests without external dependencies, consider:
1. Using Firebase Auth emulator
2. Using Firebase Firestore emulator
3. Mocking PayHere in test mode

## Test Categories

### 1. Authentication Flow (`auth_flow_test.dart`)
- Phone number entry
- Form validation
- Loading states
- Error handling

### 2. Customer Flow (`customer_flow_test.dart`)
- Service selection
- Booking form
- Date/time pickers
- Price estimates

### 3. Worker Flow (`worker_flow_test.dart`)
- Dashboard navigation
- Online/offline toggle
- Stats display
- Profile access

### 4. Navigation (`navigation_test.dart`)
- Routing between screens
- Back button behavior
- Error boundaries
- Responsive layout

### 5. Main App Flow (`app_test.dart`)
- Complete user journeys
- Cross-feature interactions
- End-to-end scenarios

## Writing Integration Tests

### Basic Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:home_service_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test description', (tester) async {
    // Start app
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Interact with UI
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();

    // Verify results
    expect(find.text('Expected'), findsOneWidget);
  });
}
```

### Best Practices

1. **Wait for animations**: Use `pumpAndSettle()` after interactions
2. **Check existence first**: Use `if (finder.evaluate().isNotEmpty)` for optional elements
3. **Time delays**: Add delays where network calls happen: `await Future.delayed(Duration(seconds: 2))`
4. **Error handling**: Tests should pass even if some UI elements are missing
5. **Independent tests**: Each test should start fresh with `app.main()`

### Common Patterns

```dart
// Check if element exists before interacting
if (find.text('Button').evaluate().isNotEmpty) {
  await tester.tap(find.text('Button'));
}

// Handle loading states
await tester.pump(); // Start loading
expect(find.byType(CircularProgressIndicator), findsOneWidget);
await tester.pumpAndSettle(const Duration(seconds: 3)); // Wait

// Scroll to element
await tester.scrollUntilVisible(
  find.text('Target'),
  500,
  scrollable: find.byType(ListView),
);
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  integration-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Start Simulator
        uses: futureware-tech/simulator-action@v2
        with:
          model: 'iPhone 14'
      
      - name: Run Tests
        run: flutter test integration_test/
```

## Troubleshooting

### Common Issues

1. **Tests timeout**
   - Increase pump duration: `pumpAndSettle(const Duration(seconds: 5))`
   - Check for infinite animations

2. **Element not found**
   - Verify text matches exactly
   - Check if element is in a different route
   - Add pumpAndSettle before finding

3. **Firebase errors**
   - Ensure Firebase config files exist
   - Check network connectivity
   - Verify Firebase project is active

4. **Platform-specific failures**
   - iOS: Ensure simulator is booted
   - Android: Ensure emulator is running
   - Web: Use `flutter test --platform chrome`

## Performance Tips

1. **Run in release mode** for faster tests
2. **Use emulators with quick boot**
3. **Group related tests** to reduce app restarts
4. **Minimize pump delays** where possible

## Coverage Goals

- Critical user flows: 100%
- Authentication: 100%
- Payment flow: 100%
- Error handling: 80%
- Overall: 60%+
