import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:home_service_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_service_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:home_service_app/features/auth/domain/entities/user_entity.dart';
import 'package:home_service_app/core/errors/failures.dart';

@GenerateMocks([AuthRepository])
import 'auth_bloc_test.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    const testPhoneNumber = '+94771234567';
    const testVerificationId = 'verification_123';
    const testSmsCode = '123456';

    final testUser = UserEntity(
      id: 'user_123',
      phoneNumber: testPhoneNumber,
      userType: 'customer',
      isOnboarded: true,
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthOtpSent] when phone number is submitted',
      build: () {
        when(mockRepository.verifyPhone(
          phoneNumber: anyNamed('phoneNumber'),
          onCodeSent: anyNamed('onCodeSent'),
          onVerificationCompleted: anyNamed('onVerificationCompleted'),
          onVerificationFailed: anyNamed('onVerificationFailed'),
        )).thenAnswer((invocation) async {
          final onCodeSent = invocation.namedArguments[#onCodeSent] as Function(String);
          onCodeSent(testVerificationId);
          return const Right(null);
        });
        return authBloc;
      },
      act: (bloc) => bloc.add(PhoneNumberSubmitted(phoneNumber: testPhoneNumber)),
      expect: () => [
        AuthLoading(),
        AuthOtpSent(phoneNumber: testPhoneNumber),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when OTP is verified successfully',
      build: () {
        when(mockRepository.verifyOTP(
          verificationId: anyNamed('verificationId'),
          smsCode: anyNamed('smsCode'),
        )).thenAnswer((_) async => Right(testUser));
        return authBloc;
      },
      seed: () => AuthOtpSent(phoneNumber: testPhoneNumber),
      act: (bloc) => bloc.add(OtpSubmitted(otpCode: testSmsCode)),
      expect: () => [
        AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when OTP verification fails',
      build: () {
        when(mockRepository.verifyOTP(
          verificationId: anyNamed('verificationId'),
          smsCode: anyNamed('smsCode'),
        )).thenAnswer((_) async => Left(AuthFailure('Invalid OTP')));
        return authBloc;
      },
      seed: () => AuthOtpSent(phoneNumber: testPhoneNumber),
      act: (bloc) => bloc.add(OtpSubmitted(otpCode: 'wrong_code')),
      expect: () => [
        AuthLoading(),
        AuthError(message: 'Invalid OTP'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when logged out',
      build: () {
        when(mockRepository.signOut()).thenAnswer((_) async {});
        return authBloc;
      },
      seed: () => AuthAuthenticated(user: testUser),
      act: (bloc) => bloc.add(LoggedOut()),
      expect: () => [
        AuthLoading(),
        AuthUnauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthNeedsOnboarding] for new user',
      build: () {
        final newUser = UserEntity(
          id: 'user_123',
          phoneNumber: testPhoneNumber,
          userType: 'unknown',
          isOnboarded: false,
        );
        when(mockRepository.verifyOTP(
          verificationId: anyNamed('verificationId'),
          smsCode: anyNamed('smsCode'),
        )).thenAnswer((_) async => Right(newUser));
        return authBloc;
      },
      seed: () => AuthOtpSent(phoneNumber: testPhoneNumber),
      act: (bloc) => bloc.add(OtpSubmitted(otpCode: testSmsCode)),
      expect: () => [
        AuthLoading(),
        isA<AuthNeedsOnboarding>(),
      ],
    );
  });
}
