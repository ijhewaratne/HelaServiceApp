import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../test_helpers/firebase_mocks.dart';

@GenerateMocks([FirebaseAuth, FirebaseFirestore, User, UserCredential])
void main() {
  late AuthRepositoryImpl repository;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    repository = AuthRepositoryImpl(mockAuth, mockFirestore);
  });

  group('AuthRepositoryImpl', () {
    test('can be instantiated', () {
      expect(repository, isNotNull);
    });
  });

  group('signOut', () {
    test('completes without error', () async {
      when(mockAuth.signOut()).thenAnswer((_) async {});
      await expectLater(repository.signOut(), completes);
    });
  });

  group('authStateChanges', () {
    test('emits null when Firebase emits null (signed-out state)', () {
      when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
      expect(repository.authStateChanges, emits(null));
    });
  });

  group('getCurrentUser', () {
    test('returns null when no user is signed in', () async {
      when(mockAuth.currentUser).thenReturn(null);
      final result = await repository.getCurrentUser();
      expect(result, isNull);
    });
  });
}
