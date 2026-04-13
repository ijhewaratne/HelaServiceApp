import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/services/analytics_service.dart';
import 'package:home_service_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:home_service_app/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:home_service_app/features/payment/presentation/pages/payment_page.dart';
import 'package:mockito/annotations.dart';

import 'payment_page_test.mocks.dart';

@GenerateMocks([PaymentRepository, AnalyticsService])
void main() {
  late MockPaymentRepository mockRepository;
  late MockAnalyticsService mockAnalytics;

  setUp(() {
    mockRepository = MockPaymentRepository();
    mockAnalytics = MockAnalyticsService();
  });

  Widget createWidget({double amount = 1500.0}) {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => PaymentBloc(
          paymentRepository: mockRepository,
          analytics: mockAnalytics,
        ),
        child: PaymentPage(
          bookingId: 'booking_123',
          amount: amount,
        ),
      ),
    );
  }

  group('PaymentPage', () {
    testWidgets('renders correctly with payment details', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('LKR 1,500.00'), findsOneWidget);
    });

    testWidgets('shows booking summary', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Booking Summary'), findsOneWidget);
    });

    testWidgets('shows payment methods', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select Payment Method'), findsOneWidget);
    });

    testWidgets('has pay now button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Pay Now'), findsOneWidget);
    });

    testWidgets('displays correct amount formatting', (tester) async {
      await tester.pumpWidget(createWidget(amount: 2500.50));
      await tester.pumpAndSettle();

      expect(find.text('LKR 2,500.50'), findsOneWidget);
    });

    testWidgets('shows back button in app bar', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('shows secure payment badge', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
  });
}
