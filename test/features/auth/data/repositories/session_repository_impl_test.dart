import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/auth/data/repositories/session_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SessionRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    firestore = FakeFirebaseFirestore();
    repository = SessionRepositoryImpl(firestore);
  });

  group('recordCurrentSession', () {
    test('creates a session document with a platform and timestamps', () async {
      final result = await repository.recordCurrentSession('user_1');
      expect(result.isRight(), isTrue);

      final snap = await firestore
          .collection('users')
          .doc('user_1')
          .collection('sessions')
          .get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.data()['platform'], isNotNull);
      expect(snap.docs.first.data()['createdAt'], isNotNull);
      expect(snap.docs.first.data()['lastActiveAt'], isNotNull);
    });

    test(
      'reuses the same session id across calls on the same device',
      () async {
        await repository.recordCurrentSession('user_1');
        await repository.recordCurrentSession('user_1');

        final snap = await firestore
            .collection('users')
            .doc('user_1')
            .collection('sessions')
            .get();
        expect(snap.docs, hasLength(1)); // second call updated, not duplicated
      },
    );
  });

  group('getSessions', () {
    test('marks the current device\'s own session as isCurrent', () async {
      await repository.recordCurrentSession('user_1');

      final result = await repository.getSessions('user_1');

      result.fold((_) => fail('Expected sessions'), (sessions) {
        expect(sessions, hasLength(1));
        expect(sessions.first.isCurrent, isTrue);
      });
    });

    test('a session recorded for a different user is not returned', () async {
      await repository.recordCurrentSession('user_1');

      final result = await repository.getSessions('user_2');

      result.fold(
        (_) => fail('Expected an empty list'),
        (sessions) => expect(sessions, isEmpty),
      );
    });
  });
}
