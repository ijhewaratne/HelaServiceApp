import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TicketStatus { open, inProgress, resolved }

enum TicketCategory { billing, workerBehavior, serviceQuality, appIssue, other }

class SupportTicket extends Equatable {
  final String id;
  final String customerId;
  final String? bookingId;
  final TicketCategory category;
  final String subject;
  final String description;
  final TicketStatus status;
  final String? adminResponse;
  final String? respondedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SupportTicket({
    required this.id,
    required this.customerId,
    this.bookingId,
    required this.category,
    required this.subject,
    required this.description,
    this.status = TicketStatus.open,
    this.adminResponse,
    this.respondedBy,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'bookingId': bookingId,
    'category': category.name,
    'subject': subject,
    'description': description,
    'status': status.name,
    'adminResponse': adminResponse,
    'respondedBy': respondedBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SupportTicket(
      id: doc.id,
      customerId: d['customerId'] as String? ?? '',
      bookingId: d['bookingId'] as String?,
      category: TicketCategory.values.firstWhere(
        (e) => e.name == (d['category'] as String?),
        orElse: () => TicketCategory.other,
      ),
      subject: d['subject'] as String? ?? '',
      description: d['description'] as String? ?? '',
      status: TicketStatus.values.firstWhere(
        (e) => e.name == (d['status'] as String?),
        orElse: () => TicketStatus.open,
      ),
      adminResponse: d['adminResponse'] as String?,
      respondedBy: d['respondedBy'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [id, customerId, status];
}

extension TicketCategoryX on TicketCategory {
  String get label {
    switch (this) {
      case TicketCategory.billing:
        return 'Billing / Payment';
      case TicketCategory.workerBehavior:
        return 'Worker Behavior';
      case TicketCategory.serviceQuality:
        return 'Service Quality';
      case TicketCategory.appIssue:
        return 'App Issue';
      case TicketCategory.other:
        return 'Other';
    }
  }
}

extension TicketStatusX on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
    }
  }
}
