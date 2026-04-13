import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/chat_repository.dart';

/// Implementation of ChatRepository using Firebase Firestore
class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, Map<String, dynamic>>> createChatRoom({
    required String bookingId,
    required String customerId,
    required String workerId,
  }) async {
    try {
      // Check if chat room already exists
      final existingQuery = await _firestore
          .collection('chatRooms')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return Right(existingQuery.docs.first.data());
      }

      // Create new chat room
      final docRef = _firestore.collection('chatRooms').doc();
      final chatRoomData = {
        'id': docRef.id,
        'bookingId': bookingId,
        'customerId': customerId,
        'workerId': workerId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
      };

      await docRef.set(chatRoomData);
      return Right(chatRoomData);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
      if (!doc.exists) {
        return Left(GenericFailure('Chat room not found'));
      }
      return Right(doc.data()!);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getChatRoomByBooking(
    String bookingId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('chatRooms')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Right(null);
      }
      return Right(querySnapshot.docs.first.data());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String message,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageRef = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc();

      final messageData = {
        'id': messageRef.id,
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'message': message,
        'messageType': messageType ?? 'text',
        'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [senderId],
      };

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        transaction.set(messageRef, messageData);
        transaction.update(
          _firestore.collection('chatRooms').doc(chatRoomId),
          {
            'lastMessage': message,
            'lastMessageAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      return Right(messageData);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getMessages(
    String chatRoomId, {
    int limit = 50,
    String? lastMessageId,
  }) async {
    try {
      Query query = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastMessageId != null) {
        final lastDoc = await _firestore
            .collection('chatRooms')
            .doc(chatRoomId)
            .collection('messages')
            .doc(lastMessageId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final querySnapshot = await query.get();
      return Right(querySnapshot.docs.reversed
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<Map<String, dynamic>>>> watchMessages(
    String chatRoomId,
  ) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return Right<Failure, List<Map<String, dynamic>>>(snapshot.docs.reversed
          .map((doc) => doc.data())
          .toList());
    }).handleError((e) {
      return Left<Failure, List<Map<String, dynamic>>>(
        GenericFailure('Stream error: $e'),
      );
    });
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      // Get unread messages
      final querySnapshot = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('readBy', arrayContains: userId)
          .get();

      // Batch update
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId]),
          });
        }
      }

      await batch.commit();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      // Get total messages in chat room
      final totalAggregate = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .count()
          .get();
      
      // Get read messages count
      final readAggregate = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('readBy', arrayContains: userId)
          .count()
          .get();

      final total = totalAggregate.count ?? 0;
      final read = readAggregate.count ?? 0;
      
      // Unread = total - read
      return Right(total - read);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserChatRooms(
    String userId,
  ) async {
    try {
      // Get chat rooms where user is either customer or worker
      final customerQuery = await _firestore
          .collection('chatRooms')
          .where('customerId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final workerQuery = await _firestore
          .collection('chatRooms')
          .where('workerId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      final allRooms = [
        ...customerQuery.docs,
        ...workerQuery.docs,
      ];

      // Sort by updatedAt
      allRooms.sort((a, b) {
        final aTime = a.data()['updatedAt'] as Timestamp?;
        final bTime = b.data()['updatedAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return Right(allRooms.map((doc) => doc.data()).toList());
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }
}
