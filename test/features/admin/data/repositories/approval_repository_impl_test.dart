import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/admin/data/repositories/approval_repository_impl.dart';
import 'package:home_service_app/features/admin/domain/entities/pending_approval.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ApprovalRepositoryImpl repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ApprovalRepositoryImpl(firestore);
  });

  group('propose', () {
    test('creates a pending approval with the given payload', () async {
      final result = await repository.propose(
        type: ApprovalType.categoryDeactivation,
        payload: {'categoryId': 'cleaning', 'categoryName': 'Cleaning'},
        proposedBy: 'admin_1',
      );

      expect(result.isRight(), isTrue);

      final snap = await firestore.collection('pending_approvals').get();
      expect(snap.docs, hasLength(1));
      expect(snap.docs.first.data()['status'], 'pending');
      expect(snap.docs.first.data()['proposedBy'], 'admin_1');
    });
  });

  group('getPending', () {
    test('returns only approvals still pending', () async {
      await repository.propose(
        type: ApprovalType.categoryDeactivation,
        payload: {'categoryId': 'cleaning'},
        proposedBy: 'admin_1',
      );
      final decided = await repository.propose(
        type: ApprovalType.permissionGrant,
        payload: {'adminUid': 'admin_2', 'scopes': []},
        proposedBy: 'admin_1',
      );
      await repository.decide(
        approvalId: decided.getOrElse(() => ''),
        approve: true,
        decidedBy: 'admin_3',
      );

      final result = await repository.getPending();

      result.fold((_) => fail('Expected pending approvals'), (approvals) {
        expect(approvals, hasLength(1));
        expect(approvals.first.type, ApprovalType.categoryDeactivation);
      });
    });
  });

  group('decide', () {
    test('the proposer cannot decide their own proposal', () async {
      final proposed = await repository.propose(
        type: ApprovalType.categoryDeactivation,
        payload: {'categoryId': 'cleaning'},
        proposedBy: 'admin_1',
      );
      final approvalId = proposed.getOrElse(() => '');

      final result = await repository.decide(
        approvalId: approvalId,
        approve: true,
        decidedBy: 'admin_1', // same as proposer
      );

      expect(result.isLeft(), isTrue);

      final doc = await firestore
          .collection('pending_approvals')
          .doc(approvalId)
          .get();
      expect(doc.data()?['status'], 'pending'); // unchanged
    });

    test('a different admin can approve, recording who decided', () async {
      final proposed = await repository.propose(
        type: ApprovalType.categoryDeactivation,
        payload: {'categoryId': 'cleaning'},
        proposedBy: 'admin_1',
      );
      final approvalId = proposed.getOrElse(() => '');

      final result = await repository.decide(
        approvalId: approvalId,
        approve: true,
        decidedBy: 'admin_2',
      );

      expect(result.isRight(), isTrue);

      final doc = await firestore
          .collection('pending_approvals')
          .doc(approvalId)
          .get();
      expect(doc.data()?['status'], 'approved');
      expect(doc.data()?['decidedBy'], 'admin_2');
    });

    test('rejecting records a reason', () async {
      final proposed = await repository.propose(
        type: ApprovalType.categoryDeactivation,
        payload: {'categoryId': 'cleaning'},
        proposedBy: 'admin_1',
      );
      final approvalId = proposed.getOrElse(() => '');

      await repository.decide(
        approvalId: approvalId,
        approve: false,
        decidedBy: 'admin_2',
        reason: 'Category still in active use',
      );

      final doc = await firestore
          .collection('pending_approvals')
          .doc(approvalId)
          .get();
      expect(doc.data()?['status'], 'rejected');
      expect(doc.data()?['reason'], 'Category still in active use');
    });
  });
}
