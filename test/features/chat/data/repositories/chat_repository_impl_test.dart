import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../test_helpers/firebase_mocks.dart';

void main() {
  late ChatRepositoryImpl repository;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    repository = ChatRepositoryImpl(mockFirestore);
  });

  group('sendMessage', () {
    const chatId = 'chat_123';
    const senderId = 'user_123';
    const receiverId = 'user_456';
    const content = 'Hello, this is a test message';

    test('should send message successfully', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('messages')).thenReturn(MockCollectionReference());
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      );

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('should return ServerFailure when sending fails', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('messages')).thenReturn(MockCollectionReference());
      when(mockDocRef.set(any)).thenThrow(Exception('Network error'));

      // Act
      final result = await repository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('getMessages', () {
    const chatId = 'chat_123';
    const userId = 'user_123';

    test('should return list of messages', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([
        createMockQueryDocumentSnapshot(
          id: 'msg_1',
          data: {
            'id': 'msg_1',
            'chatId': chatId,
            'senderId': userId,
            'receiverId': 'user_456',
            'content': 'Hello',
            'createdAt': Timestamp.now(),
            'read': true,
          },
        ),
        createMockQueryDocumentSnapshot(
          id: 'msg_2',
          data: {
            'id': 'msg_2',
            'chatId': chatId,
            'senderId': 'user_456',
            'receiverId': userId,
            'content': 'Hi there',
            'createdAt': Timestamp.now(),
            'read': false,
          },
        ),
      ]);
      
      when(mockFirestore.collection('messages')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.getMessages(chatId, userId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return messages'),
        (messages) {
          expect(messages.length, equals(2));
          expect(messages[0]['content'], equals('Hello'));
          expect(messages[1]['content'], equals('Hi there'));
        },
      );
    });

    test('should return empty list when no messages', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([]);
      
      when(mockFirestore.collection('messages')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.getMessages(chatId, userId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return empty list'),
        (messages) => expect(messages, isEmpty),
      );
    });
  });

  group('markAsRead', () {
    const messageId = 'msg_123';

    test('should mark message as read', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('messages')).thenReturn(MockCollectionReference());
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.markAsRead(messageId);

      // Assert
      expect(result, equals(const Right(null)));
    });

    test('should return ServerFailure when update fails', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('messages')).thenReturn(MockCollectionReference());
      when(mockDocRef.update(any)).thenThrow(Exception('Network error'));

      // Act
      final result = await repository.markAsRead(messageId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('getUnreadCount', () {
    const userId = 'user_123';

    test('should return count of unread messages', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([
        createMockQueryDocumentSnapshot(id: 'msg_1', data: {}),
        createMockQueryDocumentSnapshot(id: 'msg_2', data: {}),
        createMockQueryDocumentSnapshot(id: 'msg_3', data: {}),
      ]);
      
      when(mockFirestore.collection('messages')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.getUnreadCount(userId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return count'),
        (count) => expect(count, equals(3)),
      );
    });

    test('should return zero when no unread messages', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([]);
      
      when(mockFirestore.collection('messages')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.getUnreadCount(userId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return zero'),
        (count) => expect(count, equals(0)),
      );
    });
  });
}
