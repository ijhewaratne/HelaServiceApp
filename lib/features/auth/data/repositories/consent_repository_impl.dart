import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/consent_record.dart';
import '../../domain/repositories/consent_repository.dart';

class ConsentRepositoryImpl implements ConsentRepository {
  final FirebaseFirestore _firestore;

  ConsentRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('consent_records');

  @override
  Future<Either<Failure, void>> recordAcceptance({
    required String userId,
    required ConsentDocumentType documentType,
    required String version,
  }) async {
    try {
      await _col.add({
        'userId': userId,
        'documentType': documentType.name,
        'version': version,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasAcceptedCurrentVersion({
    required String userId,
    required ConsentDocumentType documentType,
    required String currentVersion,
  }) async {
    try {
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .where('documentType', isEqualTo: documentType.name)
          .where('version', isEqualTo: currentVersion)
          .limit(1)
          .get();
      return Right(snap.docs.isNotEmpty);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ConsentRecord>>> getAcceptances(
    String userId,
  ) async {
    try {
      final snap = await _col
          .where('userId', isEqualTo: userId)
          .orderBy('acceptedAt', descending: true)
          .get();
      return Right(snap.docs.map(_toRecord).toList());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  ConsentRecord _toRecord(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ConsentRecord(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      documentType: ConsentDocumentType.values.firstWhere(
        (t) => t.name == data['documentType'],
        orElse: () => ConsentDocumentType.terms,
      ),
      version: data['version'] as String? ?? '',
      acceptedAt:
          (data['acceptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
