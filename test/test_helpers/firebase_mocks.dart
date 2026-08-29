import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/mockito.dart';

/// Mock classes for Firebase testing
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockReference extends Mock implements Reference {}

class MockUploadTask extends Mock implements UploadTask {}

class MockTaskSnapshot extends Mock implements TaskSnapshot {}

class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  FakeDocumentSnapshot({
    required this.snapshotId,
    required this.snapshotExists,
    required this.snapshotData,
  });

  final String snapshotId;
  final bool snapshotExists;
  final Map<String, dynamic>? snapshotData;

  @override
  String get id => snapshotId;

  @override
  bool get exists => snapshotExists;

  @override
  Map<String, dynamic>? data() => snapshotData;
}

class FakeQueryDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  FakeQueryDocumentSnapshot({
    required this.snapshotId,
    required this.snapshotData,
  });

  final String snapshotId;
  final Map<String, dynamic> snapshotData;

  @override
  String get id => snapshotId;

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => snapshotData;
}

class FakeQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  FakeQuerySnapshot(this.snapshotDocs);

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> snapshotDocs;

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs => snapshotDocs;

  @override
  int get size => snapshotDocs.length;
}

/// Helper to create mock DocumentSnapshot with data
DocumentSnapshot<Map<String, dynamic>> createMockDocumentSnapshot({
  required String id,
  Map<String, dynamic>? data,
  bool exists = true,
}) {
  return FakeDocumentSnapshot(
    snapshotId: id,
    snapshotExists: exists,
    snapshotData: data,
  );
}

/// Helper to create mock QueryDocumentSnapshot with data
QueryDocumentSnapshot<Map<String, dynamic>> createMockQueryDocumentSnapshot({
  required String id,
  required Map<String, dynamic> data,
}) {
  return FakeQueryDocumentSnapshot(
    snapshotId: id,
    snapshotData: data,
  );
}

/// Helper to create mock QuerySnapshot
QuerySnapshot<Map<String, dynamic>> createMockQuerySnapshot(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  return FakeQuerySnapshot(docs);
}
