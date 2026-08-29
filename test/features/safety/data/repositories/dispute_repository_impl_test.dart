import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/safety/data/repositories/dispute_repository_impl.dart';
import 'package:home_service_app/features/safety/domain/entities/dispute.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late DisputeRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = DisputeRepositoryImpl(firestore);
  });

  Dispute buildDispute({
    String id = '',
    String requestId = 'booking_1',
    DisputeStatus status = DisputeStatus.open,
    DisputeIssueType issueType = DisputeIssueType.qualityOfWork,
    DateTime? createdAt,
  }) {
    return Dispute(
      id: id,
      requestId: requestId,
      reportedByUserId: 'customer_1',
      reportedUserId: 'worker_1',
      issueType: issueType,
      description: 'The work was not completed to standard.',
      status: status,
      createdAt: createdAt ?? DateTime(2026, 8, 29, 9, 0),
    );
  }

  group('createDispute', () {
    test('stores a new dispute document and marks the booking disputed',
        () async {
      await firestore.collection('bookings').doc('booking_1').set({
        'status': 'completed',
      });

      final result = await repository.createDispute(buildDispute());

      expect(result.isRight(), isTrue);
      final created = result.fold((_) => throw Exception(), (d) => d);
      expect(created.id, isNotEmpty);

      final stored =
          await firestore.collection('disputes').doc(created.id).get();
      expect(stored.exists, isTrue);
      final data = stored.data()!;
      expect(data['requestId'], 'booking_1');
      expect(data['reportedByUserId'], 'customer_1');
      expect(data['reportedUserId'], 'worker_1');
      expect(data['issueType'], 'qualityOfWork');
      expect(data['status'], 'open');
      expect(data['description'], 'The work was not completed to standard.');

      final bookingDoc =
          await firestore.collection('bookings').doc('booking_1').get();
      expect(bookingDoc.data()?['status'], 'disputed');
    });
  });

  group('getDisputesByStatus', () {
    test('only returns disputes matching the requested status', () async {
      await firestore.collection('disputes').doc('d_open').set(
            buildDispute(
              id: 'd_open',
              requestId: 'booking_open',
              status: DisputeStatus.open,
              createdAt: DateTime(2026, 8, 27),
            ).toJson(),
          );
      await firestore.collection('disputes').doc('d_review').set(
            buildDispute(
              id: 'd_review',
              requestId: 'booking_review',
              status: DisputeStatus.underReview,
              createdAt: DateTime(2026, 8, 28),
            ).toJson(),
          );
      await firestore.collection('disputes').doc('d_resolved').set(
            buildDispute(
              id: 'd_resolved',
              requestId: 'booking_resolved',
              status: DisputeStatus.resolved,
              createdAt: DateTime(2026, 8, 26),
            ).toJson(),
          );

      final openResult =
          await repository.getDisputesByStatus(DisputeStatus.open);
      final reviewResult =
          await repository.getDisputesByStatus(DisputeStatus.underReview);

      expect(openResult.isRight(), isTrue);
      openResult.fold((_) => fail('expected disputes'), (disputes) {
        expect(disputes, hasLength(1));
        expect(disputes.single.id, 'd_open');
        expect(disputes.single.status, DisputeStatus.open);
      });

      expect(reviewResult.isRight(), isTrue);
      reviewResult.fold((_) => fail('expected disputes'), (disputes) {
        expect(disputes, hasLength(1));
        expect(disputes.single.id, 'd_review');
      });
    });

    test('returns an empty list when no dispute matches the status',
        () async {
      await firestore.collection('disputes').doc('d_open').set(
            buildDispute(id: 'd_open', status: DisputeStatus.open).toJson(),
          );

      final result =
          await repository.getDisputesByStatus(DisputeStatus.closed);

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected empty list'), (disputes) {
        expect(disputes, isEmpty);
      });
    });
  });

  group('updateDisputeStatus', () {
    test('persists the new status, admin note and resolvedAt when resolving',
        () async {
      await firestore.collection('disputes').doc('dispute_1').set(
            buildDispute(id: 'dispute_1').toJson(),
          );

      final result = await repository.updateDisputeStatus(
        disputeId: 'dispute_1',
        status: DisputeStatus.resolved,
        adminId: 'admin_9',
        adminNote: 'Refund issued to customer.',
      );

      expect(result.isRight(), isTrue);
      final stored =
          await firestore.collection('disputes').doc('dispute_1').get();
      final data = stored.data()!;
      expect(data['status'], 'resolved');
      expect(data['resolvedByAdminId'], 'admin_9');
      expect(data['adminNote'], 'Refund issued to customer.');
      expect(data['resolvedAt'], isNotNull);
      expect(data['updatedAt'], isNotNull);
    });

    test('does not set resolvedAt when transitioning to underReview',
        () async {
      await firestore.collection('disputes').doc('dispute_1').set(
            buildDispute(id: 'dispute_1').toJson(),
          );

      final result = await repository.updateDisputeStatus(
        disputeId: 'dispute_1',
        status: DisputeStatus.underReview,
        adminId: 'admin_9',
      );

      expect(result.isRight(), isTrue);
      final stored =
          await firestore.collection('disputes').doc('dispute_1').get();
      final data = stored.data()!;
      expect(data['status'], 'underReview');
      expect(data['resolvedByAdminId'], 'admin_9');
      expect(data['resolvedAt'], isNull);
    });

    test('writes an audit log entry recording the status change', () async {
      await firestore.collection('disputes').doc('dispute_1').set(
            buildDispute(id: 'dispute_1').toJson(),
          );

      await repository.updateDisputeStatus(
        disputeId: 'dispute_1',
        status: DisputeStatus.closed,
        adminId: 'admin_9',
      );

      final auditSnap = await firestore.collection('audit_logs').get();
      expect(auditSnap.docs, hasLength(1));
      final audit = auditSnap.docs.first.data();
      expect(audit['adminUserId'], 'admin_9');
      expect(audit['actionType'], 'update_dispute_status');
      expect(audit['entityType'], 'disputes');
      expect(audit['entityId'], 'dispute_1');
      expect(audit['newValue'], 'closed');
    });
  });

  group('getDisputeForRequest', () {
    test('returns the dispute for a booking when one exists', () async {
      await firestore.collection('disputes').doc('dispute_1').set(
            buildDispute(id: 'dispute_1', requestId: 'booking_42').toJson(),
          );

      final result = await repository.getDisputeForRequest('booking_42');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected a dispute'), (dispute) {
        expect(dispute, isNotNull);
        expect(dispute!.id, 'dispute_1');
      });
    });

    test('returns null when no dispute exists for the booking', () async {
      final result = await repository.getDisputeForRequest('booking_missing');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected null'), (dispute) {
        expect(dispute, isNull);
      });
    });
  });

  group('getAllDisputes', () {
    test('returns disputes ordered by createdAt descending', () async {
      await firestore.collection('disputes').doc('older').set(
            buildDispute(id: 'older', createdAt: DateTime(2026, 8, 1))
                .toJson(),
          );
      await firestore.collection('disputes').doc('newer').set(
            buildDispute(id: 'newer', createdAt: DateTime(2026, 8, 20))
                .toJson(),
          );

      final result = await repository.getAllDisputes();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('expected disputes'), (disputes) {
        expect(disputes.map((d) => d.id).toList(), ['newer', 'older']);
      });
    });
  });
}
