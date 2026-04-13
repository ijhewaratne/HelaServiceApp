import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/features/customer/domain/repositories/customer_repository.dart';
import 'package:home_service_app/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:home_service_app/features/customer/presentation/pages/customer_home_page.dart';
import 'package:mockito/annotations.dart';

import 'customer_home_page_test.mocks.dart';

@GenerateMocks([CustomerRepository])
void main() {
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
  });

  Widget createWidget() {
    return MaterialApp(
      home: BlocProvider(
        create: (_) => CustomerBloc(customerRepository: mockRepository),
        child: const CustomerHomePage(),
      ),
    );
  }

  group('CustomerHomePage', () {
    testWidgets('renders correctly with app bar title', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('HelaService'), findsOneWidget);
    });

    testWidgets('shows service categories', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Services'), findsOneWidget);
    });

    testWidgets('has bottom navigation bar', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('navigates to bookings tab', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Tap on bookings tab
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
    });
  });
}
