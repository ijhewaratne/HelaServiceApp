import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:home_service_app/features/auth/domain/entities/user_entity.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../test_helpers/firebase_mocks.dart';

@GenerateMocks([FirebaseAuth, FirebaseFirestore, User, UserCredential])
void main() {
  late AuthRepositoryImpl repository;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    repository = AuthRepositoryImpl(mockAuth, mockFirestore);
  });

  group('verifyPhone', () {
    const phoneNumber = '+94771234567';

    test('should return Right when phone verification is initiated', () async {
      // Arrange
      when(mockAuth.verifyPhoneNumber(
        phoneNumber: anyNamed('phoneNumber'),
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
      )).thenAnswer((_) async {});

      // Act
      final result = await repository.verifyPhone(
        phoneNumber: phoneNumber,
        onCodeSent: (_) {},
        onVerificationCompleted: (_) {},
        onVerificationFailed: (_) {},
      );

      // Assert
      expect(result, equals(const Right(null)));
    });

    test('should return ServerFailure when verification fails', () async {
      // Arrange
      when(mockAuth.verifyPhoneNumber(
        phoneNumber: anyNamed('phoneNumber'),
        verificationCompleted: anyNamed('verificationCompleted'),
        verificationFailed: anyNamed('verificationFailed'),
        codeSent: anyNamed('codeSent'),
        codeAutoRetrievalTimeout: anyNamed('codeAutoRetrievalTimeout'),
      )).thenThrow(Exception('Network error'));

      // Act
      final result = await repository.verifyPhone(
        phoneNumber: phoneNumber,
        onCodeSent: (_) {},
        onVerificationCompleted: (_) {},
        onVerificationFailed: (_) {},
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('verifyOTP', () {
    const verificationId = 'test_verification_id';
    const smsCode = '123456';
    const uid = 'test_uid';
    const phone = '+94771234567';

    test('should return UserEntity when OTP verification succeeds', () async {
      // Arrange
      final mockUserCredential = MockUserCredential();
      when(mockUser.uid).thenReturn(uid);
      when(mockUser.phoneNumber).thenReturn(phone);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockAuth.signInWithCredential(any)).thenAnswer((_) async => mockUserCredential);
      
      // Mock Firestore user document
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = createMockDocumentSnapshot(
        id: uid,
        data: {'id': uid, 'phoneNumber': phone, 'isOnboarded': false},
      );
      when(mockFirestore.collection('users')).thenReturn(MockCollectionReference());
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);

      // Act
      final result = await repository.verifyOTP(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return user'),
        (user) {
          expect(user.id, equals(uid));
          expect(user.phoneNumber, equals(phone));
        },
      );
    });

    test('should return ServerFailure when OTP verification fails', () async {
      // Arrange
      when(mockAuth.signInWithCredential(any))
          .thenThrow(FirebaseAuthException(code: 'invalid-verification-code'));

      // Act
      final result = await repository.verifyOTP(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('signOut', () {
    test('should sign out successfully', () async {
      // Arrange
      when(mockAuth.signOut()).thenAnswer((_) async {});

      // Act & Assert
      expect(() => repository.signOut(), returnsNormally);
    });

    test('should throw when sign out fails', () async {
      // Arrange
      when(mockAuth.signOut()).thenThrow(Exception('Sign out failed'));

      // Act & Assert
      expect(() => repository.signOut(), throwsException);
    });
  });

  group('authStateChanges', () {
    test('should emit UserEntity when user is signed in', () async {
      // Arrange
      when(mockUser.uid).thenReturn('uid');
      when(mockUser.phoneNumber).thenReturn('+94771234567');
      when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
      
      final mockDocSnap = createMockDocumentSnapshot(
        id: 'uid',
        data: {'id': 'uid', 'phoneNumber': '+94771234567', 'isOnboarded': true},
      );
      when(mockFirestore.collection('users')).thenReturn(MockCollectionReference());

      // Act
      final stream = repository.authStateChanges;

      // Assert
      expect(stream, emits(isA<UserEntity>()));
    });

    test('should emit null when user is signed out', () async {
      // Arrange
      when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));

      // Act
      final stream = repository.authStateChanges;

      // Assert
      expect(stream, emits(null));
    });
  });
}
