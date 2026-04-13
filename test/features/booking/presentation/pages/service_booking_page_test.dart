import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/booking/domain/repositories/booking_repository.dart';
import 'package:home_service_app/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:home_service_app/features/booking/presentation/pages/service_booking_page.dart';
import 'package:home_service_app/features/matching/domain/usecases/find_nearest_worker.dart';
import 'package:mockito/annotations.dart';

import 'service_booking_page_test.mocks.dart';

@GenerateMocks([BookingRepository, FindNearestWorker])
void main() {
  late MockBookingRepository mockRepository;
  late MockFindNearestWorker mockFindNearestWorker;

  setUp(() {
    mockRepository = MockBookingRepository();
    mockFindNearestWorker = MockFindNearestWorker();
  });

  Widget createWidget() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => BookingBloc(
          bookingRepository: mockRepository,
          findNearestWorker: mockFindNearestWorker,
        ),
        child: const ServiceBookingPage(),
      ),
    );
  }

  group('ServiceBookingPage', () {
    testWidgets('renders correctly with service selection', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Book a Service'), findsOneWidget);
    });

    testWidgets('shows service type selector', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField), findsOneWidget);
    });

    testWidgets('shows date and time pickers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('shows address input field', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows price estimate section', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Estimated Price'), findsOneWidget);
    });

    testWidgets('has confirm booking button', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Confirm Booking'), findsOneWidget);
    });
  });
}
