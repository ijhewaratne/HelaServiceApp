# HelaService Test Suite

This directory contains all tests for the HelaService application.

## Test Structure

```
test/                           # Unit & Widget Tests
├── core/
│   └── utils/
│       ├── nic_validator_test.dart      # Sri Lankan NIC validation tests
│       └── phone_validator_test.dart    # Phone number validation tests
├── features/
│   ├── auth/
│   │   ├── auth_bloc_test.dart          # Authentication BLoC tests
│   │   └── presentation/
│   │       └── phone_auth_page_test.dart # Phone auth UI tests
│   ├── payment/
│   │   ├── payment_repository_test.dart # Payment repository tests
│   │   └── presentation/
│   │       └── payment_page_test.dart   # Payment UI tests
│   └── worker/
│       ├── worker_repository_test.dart  # Worker repository tests
│       └── presentation/
│           └── online_toggle_page_test.dart # Worker UI tests
├── test_helpers.dart                     # Test utilities and constants
└── widget_test.dart                      # Basic widget tests

integration_test/               # End-to-End Integration Tests
├── app_test.dart              # Main end-to-end flows
├── auth_flow_test.dart        # Authentication flows
├── customer_flow_test.dart    # Customer booking flows
├── worker_flow_test.dart      # Worker dashboard flows
├── navigation_test.dart       # Navigation and routing
└── README.md                  # Integration test guide
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/core/utils/nic_validator_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run tests matching a pattern
```bash
flutter test --name "NICValidator"
```

## Test Categories

### Unit Tests
- Business logic validation
- Repository method testing
- Utility function testing

### Widget Tests
- UI component rendering
- User interaction testing
- Navigation flow testing

### Integration Tests (in `integration_test/` folder)
- End-to-end user flows
- Complete feature testing

## Writing Tests

### Basic Unit Test Structure
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureName', () {
    setUp(() {
      // Setup code before each test
    });

    test('should do something specific', () {
      // Arrange
      final input = 'test';
      
      // Act
      final result = functionUnderTest(input);
      
      // Assert
      expect(result, expectedValue);
    });
  });
}
```

### BLoC Test Structure
```dart
import 'package:bloc_test/bloc_test.dart';

blocTest<AuthBloc, AuthState>(
  'emits [AuthLoading, AuthAuthenticated] when login succeeds',
  build: () => authBloc,
  act: (bloc) => bloc.add(LoginSubmitted()),
  expect: () => [
    AuthLoading(),
    AuthAuthenticated(),
  ],
);
```

### Mocking with Mockito
```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([AuthRepository])
import 'auth_bloc_test.mocks.dart';
```

## Test Data

Use constants from `test_helpers.dart`:
- `TestData.validOldFormatNIC` - Valid old NIC
- `TestData.validNewFormatNIC` - Valid new NIC
- `TestData.validPhoneNumber` - Valid phone
- `TestData.testUserId` - Test user ID

## Best Practices

1. **Arrange-Act-Assert**: Structure tests clearly
2. **One assertion per test**: Keep tests focused
3. **Descriptive names**: Test names should explain what they verify
4. **Mock external dependencies**: Don't call real APIs in tests
5. **Test edge cases**: Empty strings, null values, invalid formats

## Continuous Integration

Tests run automatically on:
- Pull request creation
- Push to main branch
- Release builds

## Coverage Goals

- Domain layer: 90%+
- Data layer: 80%+
- Presentation layer: 70%+
- Overall: 75%+
