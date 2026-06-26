import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dispute.dart';
import '../../domain/repositories/dispute_repository.dart';

class DisputeRepositoryImpl implements DisputeRepository {
  final FirebaseFirestore _firestore;

  DisputeRepositoryImpl(this._firestore);

  CollectionReference get _col => _firestore.collection('disputes');

  @override
  Future<Either<Failure, Dispute>> createDispute(Dispute dispute) async {
    try {
      final docRef = _col.doc();
      final newDispute = dispute.copyWith(id: docRef.id);
      await docRef.set(newDispute.toJson());
      // Mark booking as disputed
      await _firestore
          .collection('bookings')
          .doc(dispute.requestId)
          .update({'status': 'disputed'});
      return Right(newDispute);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Dispute>>> getAllDisputes() async {
    try {
      final snap =
          await _col.orderBy('createdAt', descending: true).get();
      return Right(snap.docs.map((d) => Dispute.fromFirestore(d)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Dispute>>> getDisputesByStatus(
      DisputeStatus status) async {
    try {
      final snap = await _col
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();
      return Right(snap.docs.map((d) => Dispute.fromFirestore(d)).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Dispute?>> getDisputeForRequest(
      String requestId) async {
    try {
      final snap = await _col
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return const Right(null);
      return Right(Dispute.fromFirestore(snap.docs.first));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDisputeStatus({
    required String disputeId,
    required DisputeStatus status,
    required String adminId,
    String? adminNote,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'resolvedByAdminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (adminNote != null) updates['adminNote'] = adminNote;
      if (status == DisputeStatus.resolved || status == DisputeStatus.closed) {
        updates['resolvedAt'] = FieldValue.serverTimestamp();
      }
      await _col.doc(disputeId).update(updates);
      await _firestore.collection('audit_logs').add({
        'adminUserId': adminId,
        'actionType': 'update_dispute_status',
        'entityType': 'disputes',
        'entityId': disputeId,
        'newValue': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Dispute>> watchOpenDisputes() {
    return _col
        .where('status', whereIn: ['open', 'underReview'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Dispute.fromFirestore(d)).toList());
  }
}
