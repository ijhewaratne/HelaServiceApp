# Integration Tests for HelaService

This directory contains end-to-end integration tests for the HelaService Flutter application.

## Test Structure

| File | Description | Coverage |
|------|-------------|----------|
| `auth_flow_test.dart` | Phone authentication flow | Login, OTP verification |
| `worker_flow_test.dart` | Worker onboarding & job management | Registration, online toggle, job acceptance |
| `customer_flow_test.dart` | Customer booking journey | Service booking, profile management |
| `booking_flow_test.dart` | Complete booking lifecycle | Scheduling, payment, real-time updates |
| `navigation_test.dart` | App navigation & routing | Screen transitions, deep links |
| `app_test.dart` | App launch & initialization | Splash, onboarding |

## Running Integration Tests

### Prerequisites

1. Ensure you have a running emulator or connected device:
   ```bash
   flutter devices
   ```

2. For Firebase-dependent tests, ensure Firebase emulators are running (optional):
   ```bash
   firebase emulators:start --only firestore,auth
   ```

### Run All Integration Tests

```bash
flutter test integration_test/
```

### Run Specific Test File

```bash
# Authentication flow
flutter test integration_test/auth_flow_test.dart

# Worker flow
flutter test integration_test/worker_flow_test.dart

# Customer flow
flutter test integration_test/customer_flow_test.dart

# Booking flow
flutter test integration_test/booking_flow_test.dart
```

### Run on Specific Device

```bash
flutter test integration_test/ -d <device_id>
```

### Run with Verbose Output

```bash
flutter test integration_test/ -v
```

## Test Configuration

### Environment Variables

Create a `.env.test` file for test-specific configuration:

```bash
FIREBASE_EMULATOR_HOST=localhost
FIREBASE_AUTH_EMULATOR_PORT=9099
FIREBASE_FIRESTORE_EMULATOR_PORT=8080
```

### Test User Data

Tests use mock/test data:
- Phone: `771234567`
- NIC: `123456789V` (old format) or `200012345678` (new format)
- Test addresses in Colombo area

## Test Scenarios

### Authentication Flow
1. ✅ App launch and splash screen
2. ✅ Phone number entry and validation
3. ✅ OTP input screen
4. ✅ Role selection (customer/worker)

### Worker Onboarding
1. ✅ NIC validation
2. ✅ Personal information entry
3. ✅ Service selection
4. ✅ Document upload flow
5. ✅ Online/offline toggle
6. ✅ Job offer acceptance

### Customer Booking
1. ✅ Service category browsing
2. ✅ Date and time selection
3. ✅ Address entry
4. ✅ Price estimation
5. ✅ Payment processing
6. ✅ Booking confirmation

### Real-time Features
1. ✅ Worker location tracking
2. ✅ Job status updates
3. ✅ Chat messaging
4. ✅ Push notifications

## Continuous Integration

### GitHub Actions

Tests run automatically on:
- Pull requests to `main` branch
- Daily scheduled runs
- Manual dispatch

See `.github/workflows/integration-tests.yml` for configuration.

### Firebase Test Lab

For physical device testing:

```bash
flutter build apk --debug

gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/flutter-apk/app-debug.apk \
  --test build/app/outputs/flutter-apk/app-debug-androidTest.apk \
  --device model=redfin,version=30,locale=en,orientation=portrait
```

## Troubleshooting

### Common Issues

1. **Timeout Errors**: Increase pump duration
   ```dart
   await tester.pumpAndSettle(const Duration(seconds: 5));
   ```

2. **Firebase Connection**: Ensure emulators are running or use production with test credentials

3. **Animation Issues**: Disable animations for tests
   ```dart
   binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
   ```

### Debug Mode

Run with Flutter driver for debugging:

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/auth_flow_test.dart
```

## Test Data Management

### Seeding Test Data

Use Cloud Functions to seed test data before runs:

```bash
curl -X POST https://us-central1-helaservice-prod.cloudfunctions.net/seedTestData
```

### Cleaning Up

Tests should clean up created data in `tearDown`:

```dart
tearDown(() async {
  // Delete test bookings
  // Delete test users
  // Reset worker status
});
```

## Coverage Goals

| Feature | Target | Current |
|---------|--------|---------|
| Authentication | 100% | 80% |
| Worker Onboarding | 90% | 60% |
| Customer Booking | 90% | 70% |
| Real-time Updates | 80% | 40% |
| Payment Flow | 90% | 50% |

## Contributing

When adding new integration tests:

1. Group related scenarios with `group()`
2. Use descriptive test names
3. Add proper setup and teardown
4. Handle conditional UI elements gracefully
5. Document any test data dependencies

## Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Firebase Testing](https://firebase.google.com/docs/rules/unit-tests)
- [CI/CD for Flutter](https://docs.flutter.dev/deployment/cd)
