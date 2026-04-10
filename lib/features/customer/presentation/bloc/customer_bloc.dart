import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/repositories/customer_repository.dart';

/// BLoC for managing customer-related state
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository _customerRepository;

  CustomerBloc({required CustomerRepository customerRepository})
      : _customerRepository = customerRepository,
        super(CustomerInitial()) {
    on<LoadCustomerProfile>(_onLoadCustomerProfile);
    on<CreateCustomerProfile>(_onCreateCustomerProfile);
    on<UpdateCustomerProfile>(_onUpdateCustomerProfile);
    on<DeleteCustomerProfile>(_onDeleteCustomerProfile);
    on<LoadCustomerBookings>(_onLoadCustomerBookings);
    on<LoadSavedAddresses>(_onLoadSavedAddresses);
    on<AddSavedAddress>(_onAddSavedAddress);
    on<UpdateSavedAddress>(_onUpdateSavedAddress);
    on<DeleteSavedAddress>(_onDeleteSavedAddress);
  }

  Future<void> _onLoadCustomerProfile(
    LoadCustomerProfile event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await _customerRepository.getCustomerProfile(event.customerId);
    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (profile) => emit(CustomerProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onCreateCustomerProfile(
    CreateCustomerProfile event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await _customerRepository.createCustomerProfile(
      event.customerId,
      event.data,
    );
    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (profile) => emit(CustomerProfileCreated(profile: profile)),
    );
  }

  Future<void> _onUpdateCustomerProfile(
    UpdateCustomerProfile event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await _customerRepository.updateCustomerProfile(
      event.customerId,
      event.data,
    );
    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (profile) => emit(CustomerProfileUpdated(profile: profile)),
    );
  }

  Future<void> _onDeleteCustomerProfile(
    DeleteCustomerProfile event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await _customerRepository.deleteCustomerProfile(event.customerId);
    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (_) => emit(CustomerProfileDeleted()),
    );
  }

  Future<void> _onLoadCustomerBookings(
    LoadCustomerBookings event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await _customerRepository.getCustomerBookings(event.customerId);
    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (bookings) => emit(CustomerBookingsLoaded(bookings: bookings)),
    );
  }

  Future<void> _onLoadSavedAddresses(
    LoadSavedAddresses event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await _customerRepository.getSavedAddresses(event.customerId);
    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (addresses) => emit(SavedAddressesLoaded(addresses: addresses)),
    );
  }

  Future<void> _onAddSavedAddress(
    AddSavedAddress event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await _customerRepository.addSavedAddress(
      event.customerId,
      event.address,
    );
    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (address) => emit(SavedAddressAdded(address: address)),
    );
  }

  Future<void> _onUpdateSavedAddress(
    UpdateSavedAddress event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await _customerRepository.updateSavedAddress(
      event.customerId,
      event.addressId,
      event.address,
    );
    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (address) => emit(SavedAddressUpdated(address: address)),
    );
  }

  Future<void> _onDeleteSavedAddress(
    DeleteSavedAddress event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await _customerRepository.deleteSavedAddress(
      event.customerId,
      event.addressId,
    );
    result.fold(
      (failure) => emit(CustomerError(message: failure.message)),
      (_) => emit(SavedAddressDeleted(addressId: event.addressId)),
    );
  }
}

// ==================== EVENTS ====================

abstract class CustomerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load customer profile
class LoadCustomerProfile extends CustomerEvent {
  final String customerId;

  LoadCustomerProfile({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

/// Create customer profile
class CreateCustomerProfile extends CustomerEvent {
  final String customerId;
  final Map<String, dynamic> data;

  CreateCustomerProfile({required this.customerId, required this.data});

  @override
  List<Object?> get props => [customerId, data];
}

/// Update customer profile
class UpdateCustomerProfile extends CustomerEvent {
  final String customerId;
  final Map<String, dynamic> data;

  UpdateCustomerProfile({required this.customerId, required this.data});

  @override
  List<Object?> get props => [customerId, data];
}

/// Delete customer profile
class DeleteCustomerProfile extends CustomerEvent {
  final String customerId;

  DeleteCustomerProfile({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

/// Load customer bookings
class LoadCustomerBookings extends CustomerEvent {
  final String customerId;

  LoadCustomerBookings({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

/// Load saved addresses
class LoadSavedAddresses extends CustomerEvent {
  final String customerId;

  LoadSavedAddresses({required this.customerId});

  @override
  List<Object?> get props => [customerId];
}

/// Add saved address
class AddSavedAddress extends CustomerEvent {
  final String customerId;
  final Map<String, dynamic> address;

  AddSavedAddress({required this.customerId, required this.address});

  @override
  List<Object?> get props => [customerId, address];
}

/// Update saved address
class UpdateSavedAddress extends CustomerEvent {
  final String customerId;
  final String addressId;
  final Map<String, dynamic> address;

  UpdateSavedAddress({
    required this.customerId,
    required this.addressId,
    required this.address,
  });

  @override
  List<Object?> get props => [customerId, addressId, address];
}

/// Delete saved address
class DeleteSavedAddress extends CustomerEvent {
  final String customerId;
  final String addressId;

  DeleteSavedAddress({required this.customerId, required this.addressId});

  @override
  List<Object?> get props => [customerId, addressId];
}

// ==================== STATES ====================

abstract class CustomerState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial state
class CustomerInitial extends CustomerState {}

/// Loading state
class CustomerLoading extends CustomerState {}

/// Customer profile loaded
class CustomerProfileLoaded extends CustomerState {
  final Map<String, dynamic> profile;

  CustomerProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

/// Customer profile created
class CustomerProfileCreated extends CustomerState {
  final Map<String, dynamic> profile;

  CustomerProfileCreated({required this.profile});

  @override
  List<Object?> get props => [profile];
}

/// Customer profile updated
class CustomerProfileUpdated extends CustomerState {
  final Map<String, dynamic> profile;

  CustomerProfileUpdated({required this.profile});

  @override
  List<Object?> get props => [profile];
}

/// Customer profile deleted
class CustomerProfileDeleted extends CustomerState {}

/// Customer bookings loaded
class CustomerBookingsLoaded extends CustomerState {
  final List<Map<String, dynamic>> bookings;

  CustomerBookingsLoaded({required this.bookings});

  @override
  List<Object?> get props => [bookings];
}

/// Saved addresses loaded
class SavedAddressesLoaded extends CustomerState {
  final List<Map<String, dynamic>> addresses;

  SavedAddressesLoaded({required this.addresses});

  @override
  List<Object?> get props => [addresses];
}

/// Saved address added
class SavedAddressAdded extends CustomerState {
  final Map<String, dynamic> address;

  SavedAddressAdded({required this.address});

  @override
  List<Object?> get props => [address];
}

/// Saved address updated
class SavedAddressUpdated extends CustomerState {
  final Map<String, dynamic> address;

  SavedAddressUpdated({required this.address});

  @override
  List<Object?> get props => [address];
}

/// Saved address deleted
class SavedAddressDeleted extends CustomerState {
  final String addressId;

  SavedAddressDeleted({required this.addressId});

  @override
  List<Object?> get props => [addressId];
}

/// Error state
class CustomerError extends CustomerState {
  final String message;

  CustomerError({required this.message});

  @override
  List<Object?> get props => [message];
}
