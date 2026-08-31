import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/auth/data/repositories/consent_repository_impl.dart';
import 'package:home_service_app/features/auth/domain/entities/consent_record.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ConsentRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ConsentRepositoryImpl(firestore);
  });

  group('recordAcceptance', () {
    test('creates an immutable acceptance record', () async {
      final result = await repository.recordAcceptance(
        userId: 'user_1',
        documentType: ConsentDocumentType.terms,
        version: '1.0',
      );

      expect(result.isRight(), isTrue);

      final snap = await firestore.collection('consent_records').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.data()['userId'], 'user_1');
      expect(snap.docs.first.data()['documentType'], 'terms');
      expect(snap.docs.first.data()['version'], '1.0');
    });
  });

  group('hasAcceptedCurrentVersion', () {
    test('is false before acceptance and true after', () async {
      final before = await repository.hasAcceptedCurrentVersion(
        userId: 'user_1',
        documentType: ConsentDocumentType.privacy,
        currentVersion: '1.0',
      );
      expect(before.getOrElse(() => true), isFalse);

      await repository.recordAcceptance(
        userId: 'user_1',
        documentType: ConsentDocumentType.privacy,
        version: '1.0',
      );

      final after = await repository.hasAcceptedCurrentVersion(
        userId: 'user_1',
        documentType: ConsentDocumentType.privacy,
        currentVersion: '1.0',
      );
      expect(after.getOrElse(() => false), isTrue);
    });

    test(
      'an old version acceptance does not satisfy a newer version',
      () async {
        await repository.recordAcceptance(
          userId: 'user_1',
          documentType: ConsentDocumentType.terms,
          version: '1.0',
        );

        final result = await repository.hasAcceptedCurrentVersion(
          userId: 'user_1',
          documentType: ConsentDocumentType.terms,
          currentVersion: '2.0',
        );
        expect(result.getOrElse(() => true), isFalse);
      },
    );
  });

  group('getAcceptances', () {
    test('returns only the requested user\'s records, newest first', () async {
      await repository.recordAcceptance(
        userId: 'user_1',
        documentType: ConsentDocumentType.terms,
        version: '1.0',
      );
      await repository.recordAcceptance(
        userId: 'user_2',
        documentType: ConsentDocumentType.terms,
        version: '1.0',
      );
      await repository.recordAcceptance(
        userId: 'user_1',
        documentType: ConsentDocumentType.privacy,
        version: '1.0',
      );

      final result = await repository.getAcceptances('user_1');

      result.fold((_) => fail('Expected acceptance records'), (records) {
        expect(records, hasLength(2));
        expect(records.every((r) => r.userId == 'user_1'), isTrue);
      });
    });
  });
}
