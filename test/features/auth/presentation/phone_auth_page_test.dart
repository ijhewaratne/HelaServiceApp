import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';

import 'package:home_service_app/features/auth/presentation/pages/phone_auth_page.dart';
import 'package:home_service_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_service_app/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

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

  Widget createTestableWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const PhoneAuthPage(),
      ),
    );
  }

  group('PhoneAuthPage', () {
    testWidgets('shows phone input initially', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(find.text('Welcome to HelaService'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('SEND CODE'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
    });

    testWidgets('shows helper text for phone input', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      expect(
        find.text('Enter 9-digit number without leading 0'),
        findsOneWidget,
      );
    });

    testWidgets('shows error for empty phone number', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      await tester.tap(find.text('SEND CODE'));
      await tester.pump();

      expect(find.text('Please enter your mobile number'), findsOneWidget);
    });

    testWidgets('shows error for invalid phone number length', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      await tester.enterText(find.byType(TextFormField), '77123');
      await tester.tap(find.text('SEND CODE'));
      await tester.pump();

      expect(find.text('Please enter 9 digits'), findsOneWidget);
    });

    testWidgets('shows error for phone not starting with 7', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      await tester.enterText(find.byType(TextFormField), '123456789');
      await tester.tap(find.text('SEND CODE'));
      await tester.pump();

      expect(
        find.text('Please enter valid Sri Lankan mobile number'),
        findsOneWidget,
      );
    });

    testWidgets('sends OTP when valid phone entered', (tester) async {
      when(mockRepository.verifyPhone(
        phoneNumber: anyNamed('phoneNumber'),
        onCodeSent: anyNamed('onCodeSent'),
        onVerificationCompleted: anyNamed('onVerificationCompleted'),
        onVerificationFailed: anyNamed('onVerificationFailed'),
      )).thenAnswer((invocation) async {
        final onCodeSent = invocation.namedArguments[#onCodeSent] as Function(String);
        onCodeSent('verification_123');
        return const Right(null);
      });

      await tester.pumpWidget(createTestableWidget());

      await tester.enterText(find.byType(TextFormField), '771234567');
      await tester.tap(find.text('SEND CODE'));
      await tester.pump();

      // Verify loading state shows
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows OTP input after code sent', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Emit OTP sent state
      authBloc.emit(AuthOtpSent(phoneNumber: '+94771234567'));
      await tester.pump();

      expect(find.text('Enter OTP'), findsOneWidget);
      expect(find.text('VERIFY'), findsOneWidget);
      expect(find.text('Resend Code'), findsOneWidget);
      expect(find.text('6-digit Code'), findsOneWidget);
    });

    testWidgets('shows error for invalid OTP length', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      // First emit OTP sent state
      authBloc.emit(AuthOtpSent(phoneNumber: '+94771234567'));
      await tester.pump();

      // Enter short OTP
      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('VERIFY'));
      await tester.pump();

      expect(find.text('Please enter 6-digit OTP'), findsOneWidget);
    });

    testWidgets('shows loading indicator during authentication', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Emit loading state
      authBloc.emit(AuthLoading());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows snackbar on error', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      authBloc.emit(AuthError(message: 'Invalid verification code'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid verification code'), findsOneWidget);
    });

    testWidgets('has prefix text for phone number', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      final decoration = textField.decoration as InputDecoration;
      expect(decoration.prefixText, '+94 ');
    });

    testWidgets('disables input during loading', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      // Emit loading state
      authBloc.emit(AuthLoading());
      await tester.pump();

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, false);
    });

    testWidgets('limits phone input to 9 digits', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      final formatters = textField.inputFormatters;
      
      expect(formatters, isNotNull);
      expect(formatters!.length, 2);
      expect(
        formatters.any((f) => f is LengthLimitingTextInputFormatter),
        true,
      );
    });

    testWidgets('only accepts digits for phone', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      final formatters = textField.inputFormatters;
      
      expect(formatters, isNotNull);
      expect(
        formatters!.any((f) => f is FilteringTextInputFormatter),
        true,
      );
    });
  });
}
