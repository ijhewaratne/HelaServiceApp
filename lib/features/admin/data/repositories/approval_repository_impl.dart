import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/pending_approval.dart';
import '../../domain/repositories/approval_repository.dart';

class ApprovalRepositoryImpl implements ApprovalRepository {
  final FirebaseFirestore _firestore;

  ApprovalRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pending_approvals');

  @override
  Future<Either<Failure, String>> propose({
    required ApprovalType type,
    required Map<String, dynamic> payload,
    required String proposedBy,
  }) async {
    try {
      final ref = await _col.add({
        'type': type.name,
        'payload': payload,
        'proposedBy': proposedBy,
        'proposedAt': FieldValue.serverTimestamp(),
        'status': ApprovalStatus.pending.name,
      });
      return Right(ref.id);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PendingApproval>>> getPending() async {
    try {
      final snap = await _col
          .where('status', isEqualTo: ApprovalStatus.pending.name)
          .orderBy('proposedAt')
          .get();
      return Right(snap.docs.map(_toEntity).toList());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> decide({
    required String approvalId,
    required bool approve,
    required String decidedBy,
    String? reason,
  }) async {
    try {
      final doc = await _col.doc(approvalId).get();
      if (!doc.exists) {
        return const Left(NotFoundFailure('Approval not found'));
      }
      if (doc.data()?['proposedBy'] == decidedBy) {
        return const Left(
          ValidationFailure('You cannot decide your own proposal'),
        );
      }

      await _col.doc(approvalId).update({
        'status': approve
            ? ApprovalStatus.approved.name
            : ApprovalStatus.rejected.name,
        'decidedBy': decidedBy,
        'decidedAt': FieldValue.serverTimestamp(),
        if (reason != null) 'reason': reason,
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  PendingApproval _toEntity(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return PendingApproval(
      id: doc.id,
      type: ApprovalType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ApprovalType.categoryDeactivation,
      ),
      payload: Map<String, dynamic>.from(
        data['payload'] as Map<String, dynamic>? ?? {},
      ),
      proposedBy: data['proposedBy'] as String? ?? '',
      proposedAt:
          (data['proposedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ApprovalStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      decidedBy: data['decidedBy'] as String?,
      decidedAt: (data['decidedAt'] as Timestamp?)?.toDate(),
      reason: data['reason'] as String?,
    );
  }
}
