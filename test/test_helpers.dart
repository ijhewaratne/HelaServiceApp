import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';

/// Helper class for widget testing with BLoCs
class TestableWidget extends StatelessWidget {
  final Widget child;
  final List<BlocProvider> providers;

  const TestableWidget({
    Key? key,
    required this.child,
    this.providers = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: providers,
      child: MaterialApp(
        home: child,
      ),
    );
  }
}

/// Mock helper for repositories
class MockHelpers {
  /// Creates a mock response for async repository calls
  static Future<T> mockAsyncResponse<T>(T data, {int delayMs = 100}) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    return data;
  }

  /// Creates a mock error response for async repository calls
  static Future<T> mockAsyncError<T>(Exception error, {int delayMs = 100}) async {
    await Future.delayed(Duration(milliseconds: delayMs));
    throw error;
  }
}

/// Test data constants
class TestData {
  // Valid Sri Lankan NICs for testing
  static const validOldFormatNIC = '853202937V';
  static const validNewFormatNIC = '198532029372';
  static const invalidNIC = '123456789';

  // Valid Sri Lankan phone numbers
  static const validPhoneNumber = '+94771234567';
  static const validPhoneNumberLocal = '0771234567';
  static const invalidPhoneNumber = '123456789';

  // Test user data
  static const testUserId = 'user_123';
  static const testWorkerId = 'worker_123';
  static const testBookingId = 'booking_123';

  // Test payment data
  static const testPaymentId = 'pay_123';
  static const testAmount = 150000; // LKR 1,500 in cents
}
