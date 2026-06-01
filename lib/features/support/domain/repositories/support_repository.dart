import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/support_ticket.dart';

abstract class SupportRepository {
  Future<Either<Failure, SupportTicket>> createTicket(SupportTicket ticket);
  Future<Either<Failure, List<SupportTicket>>> getCustomerTickets(String customerId);
  Future<Either<Failure, List<SupportTicket>>> getAllOpenTickets();
  Future<Either<Failure, void>> respondToTicket({
    required String ticketId,
    required String adminId,
    required String response,
    required TicketStatus newStatus,
  });
}
