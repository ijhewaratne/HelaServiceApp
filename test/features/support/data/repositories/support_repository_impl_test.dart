import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/support/data/repositories/support_repository_impl.dart';
import 'package:home_service_app/features/support/domain/entities/support_ticket.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SupportRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = SupportRepositoryImpl(firestore: firestore);
  });

  group('SupportRepositoryImpl', () {
    group('createTicket', () {
      test('stores a new ticket document with default open status', () async {
        final ticket = SupportTicket(
          id: 'ignored',
          customerId: 'customer_1',
          bookingId: 'booking_1',
          category: TicketCategory.billing,
          subject: 'Overcharged for service',
          description: 'I was charged twice for the same booking.',
          status: TicketStatus.resolved, // should be overridden to open
          createdAt: DateTime(2026, 3, 15),
        );

        final result = await repository.createTicket(ticket);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got $failure'),
          (created) {
            expect(created.id, isNotEmpty);
            expect(created.customerId, 'customer_1');
            expect(created.status, TicketStatus.open);
          },
        );

        final createdId = result.getOrElse(() => throw Exception()).id;
        final stored = await firestore
            .collection('support_tickets')
            .doc(createdId)
            .get();

        expect(stored.exists, isTrue);
        expect(stored.data()?['customerId'], 'customer_1');
        expect(stored.data()?['bookingId'], 'booking_1');
        expect(stored.data()?['category'], 'billing');
        expect(stored.data()?['subject'], 'Overcharged for service');
        expect(
          stored.data()?['description'],
          'I was charged twice for the same booking.',
        );
        expect(stored.data()?['status'], 'open');
      });
    });

    group('getCustomerTickets', () {
      test('returns only tickets belonging to the requested customer',
          () async {
        await firestore.collection('support_tickets').doc('ticket_1').set({
          'id': 'ticket_1',
          'customerId': 'customer_1',
          'bookingId': null,
          'category': 'billing',
          'subject': 'Ticket 1',
          'description': 'Description 1',
          'status': 'open',
          'adminResponse': null,
          'respondedBy': null,
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 10)),
          'updatedAt': null,
        });
        await firestore.collection('support_tickets').doc('ticket_2').set({
          'id': 'ticket_2',
          'customerId': 'customer_2',
          'bookingId': null,
          'category': 'appIssue',
          'subject': 'Ticket 2',
          'description': 'Description 2',
          'status': 'open',
          'adminResponse': null,
          'respondedBy': null,
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 11)),
          'updatedAt': null,
        });
        await firestore.collection('support_tickets').doc('ticket_3').set({
          'id': 'ticket_3',
          'customerId': 'customer_1',
          'bookingId': null,
          'category': 'serviceQuality',
          'subject': 'Ticket 3',
          'description': 'Description 3',
          'status': 'resolved',
          'adminResponse': null,
          'respondedBy': null,
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 12)),
          'updatedAt': null,
        });

        final result = await repository.getCustomerTickets('customer_1');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got $failure'),
          (tickets) {
            expect(tickets.length, 2);
            expect(tickets.every((t) => t.customerId == 'customer_1'), isTrue);
            expect(tickets.map((t) => t.id), containsAll(['ticket_1', 'ticket_3']));
            // Ordered by createdAt descending.
            expect(tickets.first.id, 'ticket_3');
          },
        );
      });

      test('returns an empty list when the customer has no tickets',
          () async {
        final result = await repository.getCustomerTickets('unknown_customer');

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got $failure'),
          (tickets) => expect(tickets, isEmpty),
        );
      });
    });

    group('respondToTicket', () {
      test('persists the admin response and updates the status', () async {
        await firestore.collection('support_tickets').doc('ticket_1').set({
          'id': 'ticket_1',
          'customerId': 'customer_1',
          'bookingId': null,
          'category': 'billing',
          'subject': 'Ticket 1',
          'description': 'Description 1',
          'status': 'open',
          'adminResponse': null,
          'respondedBy': null,
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 10)),
          'updatedAt': null,
        });

        final result = await repository.respondToTicket(
          ticketId: 'ticket_1',
          adminId: 'admin_1',
          response: 'We have issued a refund.',
          newStatus: TicketStatus.resolved,
        );

        expect(result.isRight(), isTrue);

        final stored =
            await firestore.collection('support_tickets').doc('ticket_1').get();

        expect(stored.data()?['adminResponse'], 'We have issued a refund.');
        expect(stored.data()?['respondedBy'], 'admin_1');
        expect(stored.data()?['status'], 'resolved');
        expect(stored.data()?['updatedAt'], isNotNull);
      });

      test('returns a failure when the ticket does not exist', () async {
        final result = await repository.respondToTicket(
          ticketId: 'missing_ticket',
          adminId: 'admin_1',
          response: 'Response',
          newStatus: TicketStatus.inProgress,
        );

        expect(result.isLeft(), isTrue);
      });
    });

    group('getAllOpenTickets', () {
      test('returns only open and inProgress tickets, ordered by createdAt ascending',
          () async {
        await firestore.collection('support_tickets').doc('ticket_open').set({
          'id': 'ticket_open',
          'customerId': 'customer_1',
          'bookingId': null,
          'category': 'billing',
          'subject': 'Open ticket',
          'description': 'Description',
          'status': 'open',
          'adminResponse': null,
          'respondedBy': null,
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 12)),
          'updatedAt': null,
        });
        await firestore
            .collection('support_tickets')
            .doc('ticket_in_progress')
            .set({
          'id': 'ticket_in_progress',
          'customerId': 'customer_2',
          'bookingId': null,
          'category': 'appIssue',
          'subject': 'In progress ticket',
          'description': 'Description',
          'status': 'inProgress',
          'adminResponse': null,
          'respondedBy': null,
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 10)),
          'updatedAt': null,
        });
        await firestore
            .collection('support_tickets')
            .doc('ticket_resolved')
            .set({
          'id': 'ticket_resolved',
          'customerId': 'customer_3',
          'bookingId': null,
          'category': 'serviceQuality',
          'subject': 'Resolved ticket',
          'description': 'Description',
          'status': 'resolved',
          'adminResponse': 'Done',
          'respondedBy': 'admin_1',
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 11)),
          'updatedAt': null,
        });

        final result = await repository.getAllOpenTickets();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got $failure'),
          (tickets) {
            expect(tickets.length, 2);
            expect(
              tickets.map((t) => t.status),
              everyElement(isNot(TicketStatus.resolved)),
            );
            // Ordered by createdAt ascending: in_progress (Mar 10) before open (Mar 12).
            expect(tickets.first.id, 'ticket_in_progress');
            expect(tickets.last.id, 'ticket_open');
          },
        );
      });

      test('returns an empty list when there are no open tickets', () async {
        await firestore.collection('support_tickets').doc('ticket_resolved').set({
          'id': 'ticket_resolved',
          'customerId': 'customer_1',
          'bookingId': null,
          'category': 'billing',
          'subject': 'Resolved ticket',
          'description': 'Description',
          'status': 'resolved',
          'adminResponse': 'Done',
          'respondedBy': 'admin_1',
          'createdAt': Timestamp.fromDate(DateTime(2026, 3, 10)),
          'updatedAt': null,
        });

        final result = await repository.getAllOpenTickets();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected success, got $failure'),
          (tickets) => expect(tickets, isEmpty),
        );
      });
    });
  });
}
