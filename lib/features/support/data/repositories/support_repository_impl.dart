import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_repository.dart';

class SupportRepositoryImpl implements SupportRepository {
  final FirebaseFirestore _db;

  SupportRepositoryImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('support_tickets');

  @override
  Future<Either<Failure, SupportTicket>> createTicket(
    SupportTicket ticket,
  ) async {
    try {
      final ref = _col.doc();
      final withId = SupportTicket(
        id: ref.id,
        customerId: ticket.customerId,
        bookingId: ticket.bookingId,
        category: ticket.category,
        subject: ticket.subject,
        description: ticket.description,
        status: TicketStatus.open,
        createdAt: ticket.createdAt,
      );
      await ref.set(withId.toJson());
      return Right(withId);
    } catch (e) {
      return Left(ServerFailure('Failed to create ticket: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SupportTicket>>> getCustomerTickets(
    String customerId,
  ) async {
    try {
      final snap = await _col
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      return Right(snap.docs.map(SupportTicket.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load tickets: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SupportTicket>>> getAllOpenTickets() async {
    try {
      final snap = await _col
          .where('status', whereIn: ['open', 'inProgress'])
          .orderBy('createdAt', descending: false)
          .get();
      return Right(snap.docs.map(SupportTicket.fromFirestore).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load tickets: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> respondToTicket({
    required String ticketId,
    required String adminId,
    required String response,
    required TicketStatus newStatus,
  }) async {
    try {
      await _col.doc(ticketId).update({
        'adminResponse': response,
        'respondedBy': adminId,
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to respond to ticket: $e'));
    }
  }
}
