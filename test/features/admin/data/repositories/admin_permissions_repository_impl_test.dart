import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/constants/admin_scope.dart';
import 'package:home_service_app/features/admin/data/repositories/admin_permissions_repository_impl.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminPermissionsRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = AdminPermissionsRepositoryImpl(firestore);
  });

  group('getScopes', () {
    test('returns an empty set when no scopes have been assigned', () async {
      final result = await repository.getScopes('admin_1');

      result.fold(
        (_) => fail('Expected an empty scope set'),
        (scopes) => expect(scopes, isEmpty),
      );
    });

    test('reads back previously stored scopes', () async {
      await firestore.collection('admin_permissions').doc('admin_1').set({
        'scopes': ['workerVerification', 'categoryManagement'],
        'grantedBy': 'super_1',
      });

      final result = await repository.getScopes('admin_1');

      result.fold(
        (_) => fail('Expected scopes'),
        (scopes) => expect(
          scopes,
          {AdminScope.workerVerification, AdminScope.categoryManagement},
        ),
      );
    });

    test('ignores unknown scope names stored by a future app version',
        () async {
      await firestore.collection('admin_permissions').doc('admin_1').set({
        'scopes': ['workerVerification', 'someFutureScope'],
      });

      final result = await repository.getScopes('admin_1');

      result.fold(
        (_) => fail('Expected scopes'),
        (scopes) => expect(scopes, {AdminScope.workerVerification}),
      );
    });
  });

  group('setScopes', () {
    test('overwrites the full scope set and records who granted it',
        () async {
      final result = await repository.setScopes(
        adminUid: 'admin_1',
        scopes: {AdminScope.disputeResolution, AdminScope.auditView},
        grantedBy: 'super_1',
      );
      expect(result.isRight(), isTrue);

      final doc =
          await firestore.collection('admin_permissions').doc('admin_1').get();
      expect(
        (doc.data()?['scopes'] as List).toSet(),
        {'disputeResolution', 'auditView'},
      );
      expect(doc.data()?['grantedBy'], 'super_1');
    });

    test('a second call fully replaces the first, not merges', () async {
      await repository.setScopes(
        adminUid: 'admin_1',
        scopes: {AdminScope.workerVerification},
        grantedBy: 'super_1',
      );
      await repository.setScopes(
        adminUid: 'admin_1',
        scopes: {AdminScope.financeView},
        grantedBy: 'super_1',
      );

      final result = await repository.getScopes('admin_1');
      result.fold(
        (_) => fail('Expected scopes'),
        (scopes) => expect(scopes, {AdminScope.financeView}),
      );
    });
  });
}
