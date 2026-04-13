import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/chat_repository.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadChat extends ChatEvent {
  final String jobId;
  
  const LoadChat(this.jobId);
  
  @override
  List<Object?> get props => [jobId];
}

class SendMessage extends ChatEvent {
  final String content;
  
  const SendMessage(this.content);
  
  @override
  List<Object?> get props => [content];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Map<String, dynamic>> messages;
  
  const ChatLoaded(this.messages);
  
  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;
  
  const ChatError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  
  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInitial()) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
  }
  
  Future<void> _onLoadChat(LoadChat event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    // TODO: Implement chat loading
    emit(const ChatLoaded([]));
  }
  
  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    // TODO: Implement message sending
  }
}
