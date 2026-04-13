import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// Integration Test Helpers
/// 
/// Phase 4: Testing Infrastructure
/// 
/// Provides utilities for integration testing with Firebase mocks
class IntegrationTestHelpers {
  /// Setup a complete test environment
  static Future<TestEnvironment> setupTestEnvironment({
    bool signedIn = true,
    String uid = 'test-uid',
    String phoneNumber = '+94771234567',
  }) async {
    final mockAuth = TestHelpers.getMockAuth(
      signedIn: signedIn,
      uid: uid,
      phoneNumber: phoneNumber,
    );
    
    final mockFirestore = TestHelpers.getMockFirestore();
    await TestHelpers.setupTestData(mockFirestore);
    
    return TestEnvironment(
      auth: mockAuth,
      firestore: mockFirestore,
    );
  }

  /// Cleanup test environment
  static Future<void> cleanupTestEnvironment(TestEnvironment env) async {
    await TestHelpers.clearTestData(env.firestore);
  }
}

/// Test environment container
class TestEnvironment {
  final MockFirebaseAuth auth;
  final FakeFirebaseFirestore firestore;

  TestEnvironment({
    required this.auth,
    required this.firestore,
  });
}

/// Widget tester extensions for integration tests
extension WidgetTesterX on WidgetTester {
  /// Pump widget and wait for settle
  Future<void> pumpAndSettleWidget(Widget widget) async {
    await pumpWidget(widget);
    await pumpAndSettle();
  }

  /// Tap button by text and settle
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pumpAndSettle();
  }

  /// Enter text in text field by key
  Future<void> enterTextByKey(Key key, String text) async {
    await enterText(find.byKey(key), text);
    await pumpAndSettle();
  }

  /// Enter text in text field by label
  Future<void> enterTextByLabel(String label, String text) async {
    await enterText(find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    ), text);
    await pumpAndSettle();
  }

  /// Verify snackbar message
  void expectSnackbar(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// Verify no snackbar is shown
  void expectNoSnackbar() {
    expect(find.byType(SnackBar), findsNothing);
  }

  /// Wait for a specific condition
  Future<void> waitFor(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await pumpAndSettle();
      if (finder.evaluate().isNotEmpty) return;
    }
    
    throw Exception('Timeout waiting for $finder');
  }
}

/// Golden file comparator for integration tests
class TestGoldenFileComparator extends LocalFileComparator {
  TestGoldenFileComparator(Uri testFile) : super(testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await super.compare(imageBytes, golden);
    
    if (!result) {
      // Generate diff image for debugging
      print('Golden file mismatch: $golden');
    }
    
    return result;
  }
}

/// Test data builders
class TestDataBuilders {
  /// Build a test booking
  static Map<String, dynamic> buildBooking({
    String? id,
    String customerId = 'customer-1',
    String? workerId,
    String serviceType = 'cleaning',
    String status = 'pending',
    DateTime? scheduledDate,
    double estimatedPrice = 2500.00,
    Map<String, dynamic>? address,
  }) {
    return {
      'id': id ?? 'booking-${DateTime.now().millisecondsSinceEpoch}',
      'customerId': customerId,
      'workerId': workerId,
      'serviceType': serviceType,
      'status': status,
      'scheduledDate': (scheduledDate ?? DateTime.now().add(const Duration(days: 1))).toIso8601String(),
      'estimatedPrice': estimatedPrice,
      'address': address ?? TestFixtures.testAddress,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Build a test worker
  static Map<String, dynamic> buildWorker({
    String uid = 'worker-1',
    String nic = '853202937V',
    String phoneNumber = '0771234567',
    List<String> services = const ['cleaning'],
    bool isVerified = true,
    bool isOnline = false,
    double rating = 4.5,
  }) {
    return {
      'uid': uid,
      'nic': nic,
      'phoneNumber': phoneNumber,
      'services': services,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'rating': rating,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Build a test customer
  static Map<String, dynamic> buildCustomer({
    String uid = 'customer-1',
    String phoneNumber = '0771234567',
    String name = 'Test Customer',
    String? email,
    List<Map<String, dynamic>>? addresses,
  }) {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'userType': 'customer',
      'isOnboarded': true,
      'addresses': addresses ?? [TestFixtures.testAddress],
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

// Note: Uint8List would need dart:typed_data import in real implementation
class Uint8List {
  final List<int> bytes;
  Uint8List(this.bytes);
}
