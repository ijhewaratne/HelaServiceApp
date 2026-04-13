import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:home_service_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_bloc_test.mocks.dart';

@GenerateMocks([ChatRepository])
void main() {
  late ChatBloc bloc;
  late MockChatRepository mockRepository;

  setUp(() {
    mockRepository = MockChatRepository();
    bloc = ChatBloc(chatRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('LoadMessages', () {
    const chatId = 'chat_123';
    const userId = 'user_123';

    final messages = [
      {
        'id': 'msg_1',
        'chatId': chatId,
        'senderId': userId,
        'content': 'Hello',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'read': true,
      },
      {
        'id': 'msg_2',
        'chatId': chatId,
        'senderId': 'user_456',
        'content': 'Hi there!',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(),
        'read': true,
      },
      {
        'id': 'msg_3',
        'chatId': chatId,
        'senderId': userId,
        'content': 'How are you?',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
        'read': false,
      },
    ];

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, ChatMessagesLoaded] when successful',
      build: () {
        when(mockRepository.getMessages(chatId, userId))
            .thenAnswer((_) async => Right(messages));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadMessages(chatId: chatId, userId: userId)),
      expect: () => [
        ChatLoading(),
        ChatMessagesLoaded(messages: messages),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, ChatError] when repository fails',
      build: () {
        when(mockRepository.getMessages(chatId, userId))
            .thenAnswer((_) async => Left(ServerFailure('Network error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadMessages(chatId: chatId, userId: userId)),
      expect: () => [
        ChatLoading(),
        const ChatError(message: 'Network error'),
      ],
    );
  });

  group('SendMessage', () {
    const chatId = 'chat_123';
    const senderId = 'user_123';
    const receiverId = 'user_456';
    const content = 'Test message';

    blocTest<ChatBloc, ChatState>(
      'emits [ChatMessageSending, ChatMessageSent] when successful',
      build: () {
        when(mockRepository.sendMessage(
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          content: content,
        )).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const SendMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      )),
      expect: () => [
        ChatMessageSending(),
        ChatMessageSent(),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits [ChatMessageSending, ChatError] when sending fails',
      build: () {
        when(mockRepository.sendMessage(
          chatId: anyNamed('chatId'),
          senderId: anyNamed('senderId'),
          receiverId: anyNamed('receiverId'),
          content: anyNamed('content'),
        )).thenAnswer((_) async => Left(ServerFailure('Send failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(const SendMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
      )),
      expect: () => [
        ChatMessageSending(),
        const ChatError(message: 'Send failed'),
      ],
    );
  });

  group('MarkAsRead', () {
    const messageId = 'msg_123';

    blocTest<ChatBloc, ChatState>(
      'emits nothing but marks message as read',
      build: () {
        when(mockRepository.markAsRead(messageId))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const MarkAsRead(messageId: messageId)),
      expect: () => [],
    );
  });

  group('LoadChats', () {
    const userId = 'user_123';

    final chats = [
      {
        'id': 'chat_1',
        'participantIds': [userId, 'user_456'],
        'lastMessage': 'Hello',
        'lastMessageTime': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        'unreadCount': 2,
      },
      {
        'id': 'chat_2',
        'participantIds': [userId, 'user_789'],
        'lastMessage': 'Thanks!',
        'lastMessageTime': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'unreadCount': 0,
      },
    ];

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, ChatListLoaded] when successful',
      build: () {
        when(mockRepository.getChats(userId))
            .thenAnswer((_) async => Right(chats));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadChats(userId: userId)),
      expect: () => [
        ChatLoading(),
        ChatListLoaded(chats: chats),
      ],
    );
  });

  group('StartChat', () {
    const currentUserId = 'user_123';
    const otherUserId = 'user_456';

    final chat = {
      'id': 'chat_new',
      'participantIds': [currentUserId, otherUserId],
      'createdAt': DateTime.now().toIso8601String(),
    };

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, ChatStarted] when successful',
      build: () {
        when(mockRepository.createChat(currentUserId, otherUserId))
            .thenAnswer((_) async => Right(chat));
        return bloc;
      },
      act: (bloc) => bloc.add(const StartChat(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      )),
      expect: () => [
        ChatLoading(),
        ChatStarted(chatId: 'chat_new'),
      ],
    );
  });
}
