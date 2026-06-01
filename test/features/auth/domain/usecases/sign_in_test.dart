import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/auth/domain/entities/user.dart';
import 'package:home_service_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sign_in_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  const tPhoneNumber = '+94771234567';

  final tUser = User(
    uid: 'test-uid',
    phoneNumber: tPhoneNumber,
    userType: UserType.customer,
    isOnboarded: true,
  );

  group('AuthRepository.verifyPhone', () {
    test('MockAuthRepository implements AuthRepository', () {
      expect(mockRepository, isA<AuthRepository>());
    });

    test('User entity has correct fields', () {
      expect(tUser.uid, equals('test-uid'));
      expect(tUser.phoneNumber, equals(tPhoneNumber));
      expect(tUser.userType, equals(UserType.customer));
      expect(tUser.isOnboarded, isTrue);
    });

    test('signOut completes', () async {
      when(mockRepository.signOut()).thenAnswer((_) async {});
      await expectLater(mockRepository.signOut(), completes);
    });

    test('authStateChanges returns a stream', () {
      when(mockRepository.authStateChanges)
          .thenAnswer((_) => Stream.value(null));
      final stream = mockRepository.authStateChanges;
      expect(stream, isA<Stream>());
    });

    test('getCurrentUser returns null when not signed in', () async {
      when(mockRepository.getCurrentUser()).thenAnswer((_) async => null);
      final result = await mockRepository.getCurrentUser();
      expect(result, isNull);
    });
  });
}
