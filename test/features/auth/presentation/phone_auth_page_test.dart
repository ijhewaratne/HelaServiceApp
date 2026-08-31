import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:home_service_app/features/auth/presentation/pages/phone_auth_page.dart';
import 'package:home_service_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_service_app/features/auth/domain/repositories/auth_repository.dart';

import 'phone_auth_page_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockRepository = MockAuthRepository();
    when(
      mockRepository.authStateChanges,
    ).thenAnswer((_) => const Stream.empty());
    // Use default AnalyticsService — all methods are no-ops when Firebase
    // is not initialized, so no stubs needed.
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

    testWidgets('shows OTP input after code sent', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      authBloc.emit(AuthOtpSent(phoneNumber: '+94771234567'));
      await tester.pump();

      expect(find.text('Enter OTP'), findsOneWidget);
      expect(find.text('VERIFY'), findsOneWidget);
      expect(find.text('Resend Code'), findsOneWidget);
    });

    testWidgets('shows error for invalid OTP length', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      authBloc.emit(AuthOtpSent(phoneNumber: '+94771234567'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('VERIFY'));
      await tester.pump();

      expect(find.text('Please enter 6-digit OTP'), findsOneWidget);
    });

    testWidgets('shows loading indicator during authentication', (
      tester,
    ) async {
      await tester.pumpWidget(createTestableWidget());

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
      expect(find.text('+94 '), findsOneWidget);
    });

    testWidgets('disables input during loading', (tester) async {
      await tester.pumpWidget(createTestableWidget());

      authBloc.emit(AuthLoading());
      await tester.pump();

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.enabled, false);
    });

    testWidgets('phone input field is present', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('phone input field shows correct hint', (tester) async {
      await tester.pumpWidget(createTestableWidget());
      expect(
        find.text('Enter 9-digit number without leading 0'),
        findsOneWidget,
      );
    });
  });
}
