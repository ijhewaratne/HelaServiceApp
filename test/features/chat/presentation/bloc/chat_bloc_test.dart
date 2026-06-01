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

  group('LoadChat', () {
    const jobId = 'job_123';

    blocTest<ChatBloc, ChatState>(
      'emits [ChatLoading, ChatLoaded] with empty messages',
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadChat(jobId)),
      expect: () => [
        ChatLoading(),
        const ChatLoaded([]),
      ],
    );
  });

  group('SendMessage', () {
    const content = 'Hello there';

    blocTest<ChatBloc, ChatState>(
      'emits nothing (stub) when SendMessage is added',
      build: () => bloc,
      act: (bloc) => bloc.add(const SendMessage(content)),
      expect: () => [],
    );
  });
}
