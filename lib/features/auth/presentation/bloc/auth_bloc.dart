import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// BLoC for managing authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  String? _verificationId;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<PhoneNumberSubmitted>(_onPhoneNumberSubmitted);
    on<OtpSubmitted>(_onOtpSubmitted);
    on<LoggedOut>(_onLoggedOut);
    on<_AuthStateChanged>(_onAuthStateChanged);

    // Listen to auth state changes
    _authRepository.authStateChanges.listen((user) {
      add(_AuthStateChanged(user: user));
    });
  }
  
  Future<void> _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.user != null) {
      if (event.user!.isOnboarded) {
        emit(AuthAuthenticated(user: event.user!));
      } else {
        emit(AuthNeedsOnboarding(user: event.user!));
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    
    final user = _authRepository.currentUser;
    if (user != null) {
      if (user.isOnboarded) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthNeedsOnboarding(user: user));
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onPhoneNumberSubmitted(
    PhoneNumberSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _authRepository.verifyPhone(
      phoneNumber: event.phoneNumber,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        emit(AuthOtpSent(phoneNumber: event.phoneNumber));
      },
      onVerificationCompleted: (credential) async {
        // Auto-verification - sign in immediately
        final result = await _authRepository.verifyOTP(
          verificationId: _verificationId ?? '',
          smsCode: credential.smsCode ?? '',
        );
        
        result.fold(
          (failure) => emit(AuthError(message: failure.message)),
          (user) {
            if (user.isOnboarded) {
              emit(AuthAuthenticated(user: user));
            } else {
              emit(AuthNeedsOnboarding(user: user));
            }
          },
        );
      },
      onVerificationFailed: (error) {
        emit(AuthError(message: error));
      },
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) {}, // Success - wait for codeSent callback
    );
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    if (_verificationId == null) {
      emit(AuthError(message: 'Verification ID not found'));
      return;
    }
    
    final result = await _authRepository.verifyOTP(
      verificationId: _verificationId!,
      smsCode: event.otpCode,
    );
    
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        if (user.isOnboarded) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthNeedsOnboarding(user: user));
        }
      },
    );
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _authRepository.signOut();
    emit(AuthUnauthenticated());
  }
}

// ==================== EVENTS ====================

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// App started - check auth status
class AppStarted extends AuthEvent {}

/// Phone number submitted for OTP
class PhoneNumberSubmitted extends AuthEvent {
  final String phoneNumber;

  PhoneNumberSubmitted({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// OTP submitted for verification
class OtpSubmitted extends AuthEvent {
  final String otpCode;

  OtpSubmitted({required this.otpCode});

  @override
  List<Object?> get props => [otpCode];
}

/// User logged out
class LoggedOut extends AuthEvent {}

/// Internal event for auth state changes
class _AuthStateChanged extends AuthEvent {
  final UserEntity? user;

  _AuthStateChanged({this.user});
  
  @override
  List<Object?> get props => [user];
}

// ==================== STATES ====================

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Initial auth state
class AuthInitial extends AuthState {}

/// Loading state
class AuthLoading extends AuthState {}

/// User is authenticated with complete profile
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User needs to complete onboarding
class AuthNeedsOnboarding extends AuthState {
  final UserEntity user;

  AuthNeedsOnboarding({required this.user});

  @override
  List<Object?> get props => [user];
}

/// OTP has been sent
class AuthOtpSent extends AuthState {
  final String phoneNumber;

  AuthOtpSent({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {}

/// Error state
class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
