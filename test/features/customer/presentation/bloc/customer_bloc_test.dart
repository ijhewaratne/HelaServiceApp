import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/customer/domain/repositories/customer_repository.dart';
import 'package:home_service_app/features/customer/presentation/bloc/customer_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'customer_bloc_test.mocks.dart';

@GenerateMocks([CustomerRepository])
void main() {
  late CustomerBloc bloc;
  late MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = MockCustomerRepository();
    bloc = CustomerBloc(customerRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('LoadCustomerProfile', () {
    final profile = {
      'id': 'customer_123',
      'fullName': 'Test Customer',
      'phoneNumber': '+94771234567',
      'address': 'Colombo',
      'savedLocations': [
        {
          'name': 'Home',
          'address': '123 Main St',
          'latitude': 6.9271,
          'longitude': 79.8612,
        },
      ],
    };

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerProfileLoaded] when successful',
      build: () {
        when(mockRepository.getProfile('customer_123'))
            .thenAnswer((_) async => Right(profile));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadCustomerProfile(customerId: 'customer_123')),
      expect: () => [
        CustomerLoading(),
        CustomerProfileLoaded(profile: profile),
      ],
    );

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerError] when repository fails',
      build: () {
        when(mockRepository.getProfile('customer_123'))
            .thenAnswer((_) async => Left(ServerFailure('Network error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadCustomerProfile(customerId: 'customer_123')),
      expect: () => [
        CustomerLoading(),
        const CustomerError(message: 'Network error'),
      ],
    );
  });

  group('UpdateCustomerProfile', () {
    final updateData = {
      'fullName': 'Updated Name',
      'address': 'New Address',
    };

    final updatedProfile = {
      'id': 'customer_123',
      'fullName': 'Updated Name',
      'phoneNumber': '+94771234567',
      'address': 'New Address',
    };

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerProfileLoaded] when successful',
      build: () {
        when(mockRepository.updateProfile('customer_123', updateData))
            .thenAnswer((_) async => Right(updatedProfile));
        return bloc;
      },
      act: (bloc) => bloc.add(UpdateCustomerProfile(
        customerId: 'customer_123',
        data: updateData,
      )),
      expect: () => [
        CustomerLoading(),
        CustomerProfileLoaded(profile: updatedProfile),
      ],
    );
  });

  group('LoadBookingHistory', () {
    final bookings = [
      {
        'id': 'booking_1',
        'serviceType': 'cleaning',
        'status': 'completed',
        'price': 1500.0,
        'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'booking_2',
        'serviceType': 'cooking',
        'status': 'assigned',
        'price': 2000.0,
        'date': DateTime.now().toIso8601String(),
      },
    ];

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerBookingsLoaded] when successful',
      build: () {
        when(mockRepository.getBookingHistory('customer_123'))
            .thenAnswer((_) async => Right(bookings));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadBookingHistory(customerId: 'customer_123')),
      expect: () => [
        CustomerLoading(),
        CustomerBookingsLoaded(bookings: bookings),
      ],
    );
  });

  group('SaveLocation', () {
    final location = {
      'name': 'Office',
      'address': '456 Work St',
      'latitude': 6.9147,
      'longitude': 79.9723,
    };

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, LocationSaved] when successful',
      build: () {
        when(mockRepository.saveLocation('customer_123', location))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(SaveLocation(
        customerId: 'customer_123',
        location: location,
      )),
      expect: () => [
        CustomerLoading(),
        LocationSaved(),
      ],
    );
  });

  group('DeleteLocation', () {
    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, LocationDeleted] when successful',
      build: () {
        when(mockRepository.deleteLocation('customer_123', 'location_123'))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const DeleteLocation(
        customerId: 'customer_123',
        locationId: 'location_123',
      )),
      expect: () => [
        CustomerLoading(),
        LocationDeleted(),
      ],
    );
  });
}
