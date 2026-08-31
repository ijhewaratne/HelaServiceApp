import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:home_service_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_service_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:home_service_app/features/auth/domain/entities/user.dart'
    as app;
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/core/services/analytics_service.dart';
import 'package:home_service_app/core/monitoring/crash_reporting.dart';

@GenerateMocks([AuthRepository, AnalyticsService, CrashReportingService])
import 'auth_bloc_test.mocks.dart';

void main() {
  late MockAuthRepository mockRepository;
  late MockAnalyticsService mockAnalytics;
  late MockCrashReportingService mockCrashReporting;
  late AuthBloc authBloc;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockAnalytics = MockAnalyticsService();
    mockCrashReporting = MockCrashReportingService();

    // Stub AuthBloc startup dependencies.
    when(
      mockRepository.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());

    // Stub analytics calls used in OTP/login flows.
    when(
      mockAnalytics.logLogin(
        method: anyNamed('method'),
        userType: anyNamed('userType'),
      ),
    ).thenAnswer((_) async {});
    when(
      mockAnalytics.logSignUp(
        method: anyNamed('method'),
        userType: anyNamed('userType'),
      ),
    ).thenAnswer((_) async {});
    when(
      mockAnalytics.logError(
        error: anyNamed('error'),
        context: anyNamed('context'),
      ),
    ).thenAnswer((_) async {});
    when(
      mockAnalytics.setUserProperties(userId: anyNamed('userId')),
    ).thenAnswer((_) async {});
    when(mockAnalytics.logLogout()).thenAnswer((_) async {});

    authBloc = AuthBloc(
      authRepository: mockRepository,
      analytics: mockAnalytics,
      crashReporting: mockCrashReporting,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    const testPhoneNumber = '+94771234567';
    const testVerificationId = 'verification_123';
    const testSmsCode = '123456';

    final testUser = app.User(
      uid: 'user_123',
      phoneNumber: testPhoneNumber,
      userType: app.UserType.customer,
      isOnboarded: true,
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthOtpSent] when phone number is submitted',
      build: () {
        when(
          mockRepository.verifyPhone(
            phoneNumber: anyNamed('phoneNumber'),
            onCodeSent: anyNamed('onCodeSent'),
            onVerificationCompleted: anyNamed('onVerificationCompleted'),
            onVerificationFailed: anyNamed('onVerificationFailed'),
          ),
        ).thenAnswer((invocation) async {
          final onCodeSent =
              invocation.namedArguments[#onCodeSent] as Function(String);
          onCodeSent(testVerificationId);
          return const Right(null);
        });
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(PhoneNumberSubmitted(phoneNumber: testPhoneNumber)),
      expect: () => [AuthLoading(), AuthOtpSent(phoneNumber: testPhoneNumber)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when OTP is verified successfully',
      build: () {
        when(
          mockRepository.verifyPhone(
            phoneNumber: anyNamed('phoneNumber'),
            onCodeSent: anyNamed('onCodeSent'),
            onVerificationCompleted: anyNamed('onVerificationCompleted'),
            onVerificationFailed: anyNamed('onVerificationFailed'),
          ),
        ).thenAnswer((inv) async {
          final cb = inv.namedArguments[#onCodeSent] as Function(String);
          cb(testVerificationId);
          return const Right(null);
        });
        when(
          mockRepository.verifyOTP(
            verificationId: testVerificationId,
            smsCode: testSmsCode,
          ),
        ).thenAnswer((_) async => Right(testUser));
        return authBloc;
      },
      act: (bloc) async {
        bloc.add(PhoneNumberSubmitted(phoneNumber: testPhoneNumber));
        await Future<void>.delayed(Duration.zero);
        bloc.add(OtpSubmitted(otpCode: testSmsCode));
      },
      expect: () => [
        AuthLoading(),
        AuthOtpSent(phoneNumber: testPhoneNumber),
        AuthLoading(),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when OTP verification fails',
      build: () {
        when(
          mockRepository.verifyPhone(
            phoneNumber: anyNamed('phoneNumber'),
            onCodeSent: anyNamed('onCodeSent'),
            onVerificationCompleted: anyNamed('onVerificationCompleted'),
            onVerificationFailed: anyNamed('onVerificationFailed'),
          ),
        ).thenAnswer((inv) async {
          final cb = inv.namedArguments[#onCodeSent] as Function(String);
          cb(testVerificationId);
          return const Right(null);
        });
        when(
          mockRepository.verifyOTP(
            verificationId: testVerificationId,
            smsCode: 'wrong_code',
          ),
        ).thenAnswer((_) async => Left(AuthFailure('Invalid OTP')));
        return authBloc;
      },
      act: (bloc) async {
        bloc.add(PhoneNumberSubmitted(phoneNumber: testPhoneNumber));
        await Future<void>.delayed(Duration.zero);
        bloc.add(OtpSubmitted(otpCode: 'wrong_code'));
      },
      expect: () => [
        AuthLoading(),
        AuthOtpSent(phoneNumber: testPhoneNumber),
        AuthLoading(),
        AuthError(message: 'Invalid OTP'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthMfaRequired (not AuthError) when the account has a second factor enrolled',
      build: () {
        when(
          mockRepository.verifyPhone(
            phoneNumber: anyNamed('phoneNumber'),
            onCodeSent: anyNamed('onCodeSent'),
            onVerificationCompleted: anyNamed('onVerificationCompleted'),
            onVerificationFailed: anyNamed('onVerificationFailed'),
          ),
        ).thenAnswer((inv) async {
          final cb = inv.namedArguments[#onCodeSent] as Function(String);
          cb(testVerificationId);
          return const Right(null);
        });
        when(
          mockRepository.verifyOTP(
            verificationId: testVerificationId,
            smsCode: testSmsCode,
          ),
        ).thenAnswer((_) async => const Left(MfaRequiredFailure()));
        return authBloc;
      },
      act: (bloc) async {
        bloc.add(PhoneNumberSubmitted(phoneNumber: testPhoneNumber));
        await Future<void>.delayed(Duration.zero);
        bloc.add(OtpSubmitted(otpCode: testSmsCode));
      },
      expect: () => [
        AuthLoading(),
        AuthOtpSent(phoneNumber: testPhoneNumber),
        AuthLoading(),
        isA<AuthMfaRequired>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when the authenticator code completes sign-in',
      build: () {
        when(
          mockRepository.completeMfaChallenge(totpCode: '654321'),
        ).thenAnswer((_) async => Right(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(MfaCodeSubmitted(totpCode: '654321')),
      expect: () => [AuthLoading(), isA<AuthAuthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthError when the authenticator code is wrong',
      build: () {
        when(
          mockRepository.completeMfaChallenge(totpCode: '000000'),
        ).thenAnswer((_) async => Left(AuthFailure('Invalid code')));
        return authBloc;
      },
      act: (bloc) => bloc.add(MfaCodeSubmitted(totpCode: '000000')),
      expect: () => [AuthLoading(), AuthError(message: 'Invalid code')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when logged out',
      build: () {
        when(mockRepository.signOut()).thenAnswer((_) async {});
        return authBloc;
      },
      seed: () => AuthAuthenticated(user: testUser),
      act: (bloc) => bloc.add(LoggedOut()),
      expect: () => [AuthLoading(), AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthNeedsOnboarding] for new user (not onboarded)',
      build: () {
        final newUser = app.User(
          uid: 'user_123',
          phoneNumber: testPhoneNumber,
          userType: app.UserType.unknown,
          isOnboarded: false,
        );
        when(
          mockRepository.verifyPhone(
            phoneNumber: anyNamed('phoneNumber'),
            onCodeSent: anyNamed('onCodeSent'),
            onVerificationCompleted: anyNamed('onVerificationCompleted'),
            onVerificationFailed: anyNamed('onVerificationFailed'),
          ),
        ).thenAnswer((inv) async {
          final cb = inv.namedArguments[#onCodeSent] as Function(String);
          cb(testVerificationId);
          return const Right(null);
        });
        when(
          mockRepository.verifyOTP(
            verificationId: testVerificationId,
            smsCode: testSmsCode,
          ),
        ).thenAnswer((_) async => Right(newUser));
        return authBloc;
      },
      act: (bloc) async {
        bloc.add(PhoneNumberSubmitted(phoneNumber: testPhoneNumber));
        await Future<void>.delayed(Duration.zero);
        bloc.add(OtpSubmitted(otpCode: testSmsCode));
      },
      expect: () => [
        AuthLoading(),
        AuthOtpSent(phoneNumber: testPhoneNumber),
        AuthLoading(),
        isA<AuthNeedsOnboarding>(),
      ],
    );
  });
}
