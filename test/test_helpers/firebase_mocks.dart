import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Export mocks for use in tests
export 'firebase_mocks.mocks.dart';

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

/// Helper to create mock DocumentSnapshot with data
MockDocumentSnapshot createMockDocumentSnapshot({
  required String id,
  Map<String, dynamic>? data,
  bool exists = true,
}) {
  final snapshot = MockDocumentSnapshot();
  when(snapshot.id).thenReturn(id);
  when(snapshot.exists).thenReturn(exists);
  when(snapshot.data()).thenReturn(data);
  return snapshot;
}

/// Helper to create mock QueryDocumentSnapshot with data
MockQueryDocumentSnapshot createMockQueryDocumentSnapshot({
  required String id,
  required Map<String, dynamic> data,
}) {
  final snapshot = MockQueryDocumentSnapshot();
  when(snapshot.id).thenReturn(id);
  when(snapshot.data()).thenReturn(data);
  return snapshot;
}

/// Helper to create mock QuerySnapshot
MockQuerySnapshot createMockQuerySnapshot(List<MockQueryDocumentSnapshot> docs) {
  final snapshot = MockQuerySnapshot();
  when(snapshot.docs).thenReturn(docs);
  when(snapshot.size).thenReturn(docs.length);
  when(snapshot.empty).thenReturn(docs.isEmpty);
  return snapshot;
}
