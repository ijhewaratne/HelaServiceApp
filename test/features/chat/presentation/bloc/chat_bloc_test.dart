import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/customer/domain/entities/address.dart';
import 'package:home_service_app/features/booking/domain/entities/booking.dart';
import 'package:home_service_app/features/booking/domain/repositories/booking_repository.dart';
import 'package:home_service_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:home_service_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_bloc_test.mocks.dart';

@GenerateMocks([ChatRepository, BookingRepository])
void main() {
  late MockChatRepository mockChatRepository;
  late MockBookingRepository mockBookingRepository;
  late MockFirebaseAuth mockFirebaseAuth;

  const bookingId = 'booking_1';
  const customerId = 'customer_1';
  const workerId = 'worker_1';

  Booking buildBooking({String? workerId}) {
    return Booking(
      id: bookingId,
      customerId: customerId,
      workerId: workerId,
      serviceType: ServiceType.cleaning,
      status: BookingStatus.confirmed,
      address: Address(
        id: 'addr_1',
        customerId: customerId,
        label: 'Home',
        houseNumber: '1',
        street: 'Main St',
        city: 'Colombo',
        district: 'Colombo',
        zoneId: 'colombo',
        latitude: 6.9271,
        longitude: 79.8612,
        createdAt: DateTime(2026, 1, 1),
      ),
      scheduledDate: DateTime(2026, 3, 1),
      estimatedPrice: 2000.0,
      heldAmount: 0.0,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  ChatBloc buildBloc() => ChatBloc(
    chatRepository: mockChatRepository,
    bookingRepository: mockBookingRepository,
    firebaseAuth: mockFirebaseAuth,
  );

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockBookingRepository = MockBookingRepository();
    mockFirebaseAuth = MockFirebaseAuth(
      mockUser: MockUser(uid: customerId),
      signedIn: true,
    );

    when(
      mockChatRepository.markMessagesAsRead(
        chatRoomId: anyNamed('chatRoomId'),
        userId: anyNamed('userId'),
      ),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockChatRepository.watchMessages(any),
    ).thenAnswer((_) => const Stream.empty());
  });

  group('LoadChat', () {
    blocTest<ChatBloc, ChatState>(
      'creates a chat room and emits ChatLoaded when none exists yet',
      build: () {
        when(
          mockBookingRepository.getBooking(bookingId),
        ).thenAnswer((_) async => Right(buildBooking(workerId: workerId)));
        when(
          mockChatRepository.getChatRoomByBooking(bookingId),
        ).thenAnswer((_) async => const Right(null));
        when(
          mockChatRepository.createChatRoom(
            bookingId: bookingId,
            customerId: customerId,
            workerId: workerId,
          ),
        ).thenAnswer((_) async => const Right({'id': 'room_1'}));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadChat(bookingId)),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>()
            .having((s) => s.chatRoomId, 'chatRoomId', 'room_1')
            .having((s) => s.currentUserId, 'currentUserId', customerId)
            .having((s) => s.otherPartyId, 'otherPartyId', workerId)
            .having((s) => s.messages, 'messages', isEmpty),
      ],
      verify: (_) {
        verify(
          mockChatRepository.createChatRoom(
            bookingId: bookingId,
            customerId: customerId,
            workerId: workerId,
          ),
        ).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'reuses an existing chat room instead of creating a new one',
      build: () {
        when(
          mockBookingRepository.getBooking(bookingId),
        ).thenAnswer((_) async => Right(buildBooking(workerId: workerId)));
        when(
          mockChatRepository.getChatRoomByBooking(bookingId),
        ).thenAnswer((_) async => const Right({'id': 'existing_room'}));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadChat(bookingId)),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>().having(
          (s) => s.chatRoomId,
          'chatRoomId',
          'existing_room',
        ),
      ],
      verify: (_) {
        verifyNever(
          mockChatRepository.createChatRoom(
            bookingId: anyNamed('bookingId'),
            customerId: anyNamed('customerId'),
            workerId: anyNamed('workerId'),
          ),
        );
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits ChatError when no worker has been assigned yet',
      build: () {
        when(
          mockBookingRepository.getBooking(bookingId),
        ).thenAnswer((_) async => Right(buildBooking(workerId: null)));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadChat(bookingId)),
      expect: () => [isA<ChatLoading>(), isA<ChatError>()],
      verify: (_) {
        verifyNever(mockChatRepository.getChatRoomByBooking(any));
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits ChatError when no user is signed in',
      build: () {
        mockFirebaseAuth = MockFirebaseAuth(signedIn: false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadChat(bookingId)),
      expect: () => [isA<ChatLoading>(), isA<ChatError>()],
      verify: (_) {
        verifyNever(mockBookingRepository.getBooking(any));
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits ChatError when the booking cannot be loaded',
      build: () {
        when(mockBookingRepository.getBooking(bookingId)).thenAnswer(
          (_) async => const Left(NotFoundFailure('Booking not found')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadChat(bookingId)),
      expect: () => [isA<ChatLoading>(), isA<ChatError>()],
    );

    blocTest<ChatBloc, ChatState>(
      'updates messages as they arrive from the watchMessages stream',
      build: () {
        final controller =
            StreamController<Either<Failure, List<Map<String, dynamic>>>>();
        when(
          mockBookingRepository.getBooking(bookingId),
        ).thenAnswer((_) async => Right(buildBooking(workerId: workerId)));
        when(
          mockChatRepository.getChatRoomByBooking(bookingId),
        ).thenAnswer((_) async => const Right({'id': 'room_1'}));
        when(
          mockChatRepository.watchMessages('room_1'),
        ).thenAnswer((_) => controller.stream);
        addTearDown(controller.close);
        // Feed one message shortly after subscription starts.
        Future.microtask(
          () => controller.add(
            Right([
              {'senderId': workerId, 'message': 'hi there'},
            ]),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadChat(bookingId)),
      wait: const Duration(milliseconds: 50),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>().having((s) => s.messages, 'messages', isEmpty),
        isA<ChatLoaded>().having((s) => s.messages, 'messages', [
          {'senderId': workerId, 'message': 'hi there'},
        ]),
      ],
    );
  });

  group('SendMessage', () {
    blocTest<ChatBloc, ChatState>(
      'sends the message and clears the sending flag on success',
      build: () {
        when(
          mockChatRepository.sendMessage(
            chatRoomId: anyNamed('chatRoomId'),
            senderId: anyNamed('senderId'),
            message: anyNamed('message'),
          ),
        ).thenAnswer((_) async => const Right({}));
        return buildBloc();
      },
      seed: () => const ChatLoaded(
        chatRoomId: 'room_1',
        currentUserId: customerId,
        otherPartyId: workerId,
        messages: [],
      ),
      act: (bloc) => bloc.add(const SendMessage('Hello there')),
      expect: () => [
        isA<ChatLoaded>().having((s) => s.isSending, 'isSending', isTrue),
        isA<ChatLoaded>()
            .having((s) => s.isSending, 'isSending', isFalse)
            .having((s) => s.sendError, 'sendError', isNull),
      ],
      verify: (_) {
        verify(
          mockChatRepository.sendMessage(
            chatRoomId: 'room_1',
            senderId: customerId,
            message: 'Hello there',
          ),
        ).called(1);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'surfaces a sendError without discarding existing messages on failure',
      build: () {
        when(
          mockChatRepository.sendMessage(
            chatRoomId: anyNamed('chatRoomId'),
            senderId: anyNamed('senderId'),
            message: anyNamed('message'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('network down')));
        return buildBloc();
      },
      seed: () => const ChatLoaded(
        chatRoomId: 'room_1',
        currentUserId: customerId,
        otherPartyId: workerId,
        messages: [
          {'senderId': workerId, 'message': 'earlier message'},
        ],
      ),
      act: (bloc) => bloc.add(const SendMessage('will fail')),
      expect: () => [
        isA<ChatLoaded>().having((s) => s.isSending, 'isSending', isTrue),
        isA<ChatLoaded>()
            .having((s) => s.isSending, 'isSending', isFalse)
            .having((s) => s.sendError, 'sendError', 'network down')
            .having((s) => s.messages, 'messages', hasLength(1)),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'does nothing when the chat has not loaded yet',
      build: buildBloc,
      act: (bloc) => bloc.add(const SendMessage('too early')),
      expect: () => [],
      verify: (_) {
        verifyNever(
          mockChatRepository.sendMessage(
            chatRoomId: anyNamed('chatRoomId'),
            senderId: anyNamed('senderId'),
            message: anyNamed('message'),
          ),
        );
      },
    );

    blocTest<ChatBloc, ChatState>(
      'ignores blank messages',
      build: buildBloc,
      seed: () => const ChatLoaded(
        chatRoomId: 'room_1',
        currentUserId: customerId,
        otherPartyId: workerId,
        messages: [],
      ),
      act: (bloc) => bloc.add(const SendMessage('   ')),
      expect: () => [],
    );
  });
}
