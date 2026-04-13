import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mockito/mockito.dart';

/// Test Helpers for Firebase mocking
/// 
/// Phase 4: Testing Infrastructure
class TestHelpers {
  /// Create a mock Firebase Auth instance
  /// 
  /// [signedIn] - Whether the user is signed in
  /// [uid] - User ID
  /// [phoneNumber] - User phone number
  static MockFirebaseAuth getMockAuth({
    bool signedIn = true,
    String uid = 'test-uid',
    String phoneNumber = '+94771234567',
    String? email,
    String? displayName,
  }) {
    final user = MockUser(
      uid: uid,
      phoneNumber: phoneNumber,
      email: email,
      displayName: displayName,
    );
    return MockFirebaseAuth(
      mockUser: signedIn ? user : null,
      signedIn: signedIn,
    );
  }

  /// Create a mock Firestore instance
  static FakeFirebaseFirestore getMockFirestore() {
    return FakeFirebaseFirestore();
  }

  /// Create a signed-in mock user
  static MockUser getMockUser({
    String uid = 'test-uid',
    String phoneNumber = '+94771234567',
    String? email,
    String? displayName,
  }) {
    return MockUser(
      uid: uid,
      phoneNumber: phoneNumber,
      email: email,
      displayName: displayName,
    );
  }

  /// Setup common Firestore collections with test data
  static Future<void> setupTestData(FakeFirebaseFirestore firestore) async {
    // Add test user
    await firestore.collection('users').doc('test-uid').set({
      'phoneNumber': '+94771234567',
      'userType': 'customer',
      'isOnboarded': true,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Add test service categories
    await firestore.collection('service_categories').add({
      'name': 'Cleaning',
      'icon': 'cleaning_services',
      'description': 'House cleaning services',
    });

    await firestore.collection('service_categories').add({
      'name': 'Plumbing',
      'icon': 'plumbing',
      'description': 'Plumbing services',
    });

    // Add test zones
    await firestore.collection('zones').doc('col_03_04').set({
      'name': 'Colombo 03/04',
      'center': {'lat': 6.8940, 'lng': 79.8580},
      'radiusKm': 2.5,
    });
  }

  /// Clear all test data
  static Future<void> clearTestData(FakeFirebaseFirestore firestore) async {
    // Get all collections and delete documents
    final collections = ['users', 'bookings', 'workers', 'payments', 'incidents'];
    
    for (final collection in collections) {
      final snapshot = await firestore.collection(collection).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }
}

/// Test data fixtures
class TestFixtures {
  /// Valid Sri Lankan NIC numbers
  static const validOldNIC = '853202937V';
  static const validNewNIC = '198532029372';
  static const invalidNIC = '123456789';

  /// Valid Sri Lankan phone numbers
  static const validPhone = '0771234567';
  static const validPhoneWithCode = '+94771234567';
  static const invalidPhone = '1234567890';

  /// Test coordinates (Colombo)
  static const colomboLat = 6.9271;
  static const colomboLng = 79.8612;

  /// Test addresses
  static Map<String, dynamic> get testAddress => {
        'houseNumber': '42',
        'street': 'Galle Road',
        'landmark': 'Near Temple',
        'city': 'Colombo',
        'district': 'Colombo',
        'zoneId': 'col_03_04',
        'latitude': 6.8940,
        'longitude': 79.8580,
      };

  /// Test booking data
  static Map<String, dynamic> get testBooking => {
        'customerId': 'customer-1',
        'serviceType': 'cleaning',
        'status': 'pending',
        'scheduledDate': DateTime(2026, 4, 15).toIso8601String(),
        'estimatedPrice': 2500.00,
        'address': testAddress,
        'notes': 'Test booking',
      };

  /// Test worker data
  static Map<String, dynamic> get testWorker => {
        'uid': 'worker-1',
        'nic': '853202937V',
        'phoneNumber': '0771234567',
        'services': ['cleaning', 'plumbing'],
        'isVerified': true,
        'isOnline': false,
        'rating': 4.5,
      };

  /// Test payment data
  static Map<String, dynamic> get testPayment => {
        'bookingId': 'booking-1',
        'amount': 2500.00,
        'currency': 'LKR',
        'status': 'completed',
        'paymentMethod': 'payhere',
      };
}

/// Custom matchers for tests
class CustomMatchers {
  /// Matcher for Either Right values
  static Matcher isRight() => predicate<dynamic>(
        (value) => value.isRight(),
        'is Right',
      );

  /// Matcher for Either Left values
  static Matcher isLeft() => predicate<dynamic>(
        (value) => value.isLeft(),
        'is Left',
      );

  /// Matcher for specific failure type
  static Matcher isFailure<T>() => predicate<dynamic>(
        (value) => value.isLeft() && value.fold(
          (failure) => failure is T,
          (_) => false,
        ),
        'is $T',
      );
}
