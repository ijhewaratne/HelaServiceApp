import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../booking/domain/repositories/booking_repository.dart';
import '../../domain/repositories/chat_repository.dart';

// ==================== EVENTS ====================

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or create) the chat room for a booking and start listening for
/// messages.
class LoadChat extends ChatEvent {
  final String bookingId;

  const LoadChat(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class SendMessage extends ChatEvent {
  final String content;

  const SendMessage(this.content);

  @override
  List<Object?> get props => [content];
}

/// Internal — dispatched by the watchMessages() subscription.
class ChatMessagesUpdated extends ChatEvent {
  final List<Map<String, dynamic>> messages;

  const ChatMessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Internal — dispatched when the watchMessages() stream errors.
class ChatStreamFailed extends ChatEvent {
  final String message;

  const ChatStreamFailed(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== STATES ====================

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final String chatRoomId;
  final String currentUserId;
  final String otherPartyId;
  final List<Map<String, dynamic>> messages;
  final bool isSending;
  final String? sendError;

  const ChatLoaded({
    required this.chatRoomId,
    required this.currentUserId,
    required this.otherPartyId,
    required this.messages,
    this.isSending = false,
    this.sendError,
  });

  ChatLoaded copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isSending,
    String? sendError,
    bool clearSendError = false,
  }) {
    return ChatLoaded(
      chatRoomId: chatRoomId,
      currentUserId: currentUserId,
      otherPartyId: otherPartyId,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
    );
  }

  @override
  List<Object?> get props =>
      [chatRoomId, currentUserId, otherPartyId, messages, isSending, sendError];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== BLOC ====================

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final BookingRepository _bookingRepository;
  final FirebaseAuth _firebaseAuth;
  StreamSubscription<dynamic>? _messagesSubscription;

  ChatBloc({
    required ChatRepository chatRepository,
    required BookingRepository bookingRepository,
    FirebaseAuth? firebaseAuth,
  })  : _chatRepository = chatRepository,
        _bookingRepository = bookingRepository,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(ChatInitial()) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
    on<ChatStreamFailed>(_onStreamFailed);
  }

  Future<void> _onLoadChat(LoadChat event, Emitter<ChatState> emit) async {
    emit(ChatLoading());

    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) {
      emit(const ChatError('You must be signed in to chat.'));
      return;
    }

    final bookingResult = await _bookingRepository.getBooking(event.bookingId);
    final booking = bookingResult.fold((failure) {
      emit(ChatError(failure.message));
      return null;
    }, (booking) => booking);
    if (booking == null) return;

    final workerId = booking.workerId;
    if (workerId == null) {
      emit(const ChatError(
          'Chat becomes available once a worker is assigned to this booking.'));
      return;
    }

    final existingRoomResult =
        await _chatRepository.getChatRoomByBooking(event.bookingId);
    var room = existingRoomResult.fold((_) => null, (room) => room);

    if (room == null) {
      final createResult = await _chatRepository.createChatRoom(
        bookingId: event.bookingId,
        customerId: booking.customerId,
        workerId: workerId,
      );
      room = createResult.fold((failure) {
        emit(ChatError(failure.message));
        return null;
      }, (room) => room);
      if (room == null) return;
    }

    final chatRoomId = room['id'] as String? ?? event.bookingId;
    final otherPartyId =
        currentUserId == booking.customerId ? workerId : booking.customerId;

    await _messagesSubscription?.cancel();
    _messagesSubscription =
        _chatRepository.watchMessages(chatRoomId).listen((either) {
      either.fold(
        (failure) => add(ChatStreamFailed(failure.message)),
        (messages) => add(ChatMessagesUpdated(messages)),
      );
    });

    emit(ChatLoaded(
      chatRoomId: chatRoomId,
      currentUserId: currentUserId,
      otherPartyId: otherPartyId,
      messages: const [],
    ));

    await _chatRepository.markMessagesAsRead(
      chatRoomId: chatRoomId,
      userId: currentUserId,
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatLoaded) return;
    if (event.content.trim().isEmpty) return;

    emit(current.copyWith(isSending: true, clearSendError: true));

    final result = await _chatRepository.sendMessage(
      chatRoomId: current.chatRoomId,
      senderId: current.currentUserId,
      message: event.content.trim(),
    );

    result.fold(
      (failure) {
        final latest = state;
        if (latest is ChatLoaded) {
          emit(latest.copyWith(isSending: false, sendError: failure.message));
        }
      },
      (_) {
        final latest = state;
        if (latest is ChatLoaded) {
          emit(latest.copyWith(isSending: false, clearSendError: true));
        }
      },
    );
  }

  void _onMessagesUpdated(
    ChatMessagesUpdated event,
    Emitter<ChatState> emit,
  ) {
    final current = state;
    if (current is ChatLoaded) {
      emit(current.copyWith(messages: event.messages));
    }
  }

  void _onStreamFailed(ChatStreamFailed event, Emitter<ChatState> emit) {
    if (state is! ChatLoaded) {
      emit(ChatError(event.message));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
