import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/constants/admin_scope.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/admin_permissions_repository.dart';

class AdminPermissionsRepositoryImpl implements AdminPermissionsRepository {
  final FirebaseFirestore _firestore;

  AdminPermissionsRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('admin_permissions');

  @override
  Future<Either<Failure, Set<AdminScope>>> getScopes(String adminUid) async {
    try {
      final doc = await _col.doc(adminUid).get();
      if (!doc.exists) return Right(<AdminScope>{});

      final raw = (doc.data()?['scopes'] as List<dynamic>?) ?? [];
      final byName = {for (final s in AdminScope.values) s.name: s};
      final scopes = raw
          .map((s) => byName[s as String])
          .whereType<AdminScope>()
          .toSet();
      return Right(scopes);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setScopes({
    required String adminUid,
    required Set<AdminScope> scopes,
    required String grantedBy,
  }) async {
    try {
      await _col.doc(adminUid).set({
        'scopes': scopes.map((s) => s.name).toList(),
        'grantedBy': grantedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }
}
