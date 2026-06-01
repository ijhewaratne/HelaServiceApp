import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/customer/domain/entities/address.dart';
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
    const customerId = 'customer_123';
    final profile = {
      'id': customerId,
      'fullName': 'Test Customer',
      'phoneNumber': '+94771234567',
    };

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerProfileLoaded] when successful',
      build: () {
        when(mockRepository.getCustomerProfile(customerId))
            .thenAnswer((_) async => Right(profile));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadCustomerProfile(customerId: customerId)),
      expect: () => [
        CustomerLoading(),
        CustomerProfileLoaded(profile: profile),
      ],
    );

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerError] when repository fails',
      build: () {
        when(mockRepository.getCustomerProfile(customerId))
            .thenAnswer((_) async => Left(ServerFailure('Network error')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadCustomerProfile(customerId: customerId)),
      expect: () => [
        CustomerLoading(),
        CustomerError(message: 'Network error'),
      ],
    );
  });

  group('UpdateCustomerProfile', () {
    const customerId = 'customer_123';
    final updateData = {'fullName': 'Updated Name'};
    final updatedProfile = {'id': customerId, 'fullName': 'Updated Name'};

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerProfileUpdated] when successful',
      build: () {
        when(mockRepository.updateCustomerProfile(customerId, updateData))
            .thenAnswer((_) async => Right(updatedProfile));
        return bloc;
      },
      act: (bloc) => bloc.add(UpdateCustomerProfile(
        customerId: customerId,
        data: updateData,
      )),
      expect: () => [
        CustomerLoading(),
        CustomerProfileUpdated(profile: updatedProfile),
      ],
    );
  });

  group('LoadCustomerBookings', () {
    const customerId = 'customer_123';
    final bookings = [
      {'id': 'booking_1', 'status': 'completed'},
      {'id': 'booking_2', 'status': 'assigned'},
    ];

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerBookingsLoaded] when successful',
      build: () {
        when(mockRepository.getCustomerBookings(customerId))
            .thenAnswer((_) async => Right(bookings));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadCustomerBookings(customerId: customerId)),
      expect: () => [
        CustomerLoading(),
        CustomerBookingsLoaded(bookings: bookings),
      ],
    );

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, CustomerError] when repository fails',
      build: () {
        when(mockRepository.getCustomerBookings(customerId))
            .thenAnswer((_) async => Left(ServerFailure('Failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadCustomerBookings(customerId: customerId)),
      expect: () => [
        CustomerLoading(),
        CustomerError(message: 'Failed'),
      ],
    );
  });

  group('LoadSavedAddresses', () {
    const customerId = 'customer_123';
    final addresses = [
      Address(
        id: 'addr_1',
        customerId: customerId,
        label: 'Home',
        houseNumber: '12A',
        city: 'Colombo',
        district: 'Colombo',
        zoneId: 'colombo_03_04',
        latitude: 6.9271,
        longitude: 79.8612,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, SavedAddressesLoaded] when successful',
      build: () {
        when(mockRepository.getSavedAddresses(customerId))
            .thenAnswer((_) async => Right(addresses));
        return bloc;
      },
      act: (bloc) => bloc.add(LoadSavedAddresses(customerId: customerId)),
      expect: () => [
        CustomerLoading(),
        SavedAddressesLoaded(addresses: addresses),
      ],
    );
  });

  group('AddSavedAddress', () {
    const customerId = 'customer_123';
    final address = Address(
      id: '',
      customerId: customerId,
      label: 'Office',
      houseNumber: '456',
      city: 'Colombo',
      district: 'Colombo',
      zoneId: 'colombo_03_04',
      latitude: 6.9147,
      longitude: 79.9723,
      createdAt: DateTime(2026, 1, 1),
    );
    final savedAddress = address.copyWith(id: 'addr_new');

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, SavedAddressAdded] when successful',
      build: () {
        when(mockRepository.addSavedAddress(customerId, address))
            .thenAnswer((_) async => Right(savedAddress));
        return bloc;
      },
      act: (bloc) => bloc.add(AddSavedAddress(
        customerId: customerId,
        address: address,
      )),
      expect: () => [
        CustomerLoading(),
        SavedAddressAdded(address: savedAddress),
      ],
    );
  });

  group('DeleteSavedAddress', () {
    const customerId = 'customer_123';
    const addressId = 'addr_123';

    blocTest<CustomerBloc, CustomerState>(
      'emits [CustomerLoading, SavedAddressDeleted] when successful',
      build: () {
        when(mockRepository.deleteSavedAddress(customerId, addressId))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(DeleteSavedAddress(
        customerId: customerId,
        addressId: addressId,
      )),
      expect: () => [
        CustomerLoading(),
        SavedAddressDeleted(addressId: addressId),
      ],
    );
  });
}
