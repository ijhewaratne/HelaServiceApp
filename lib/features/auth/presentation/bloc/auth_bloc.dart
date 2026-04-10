import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/monitoring/crash_reporting.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// BLoC for managing authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final AnalyticsService _analytics;
  final CrashReportingService _crashReporting;
  String? _verificationId;

  AuthBloc({
    required AuthRepository authRepository,
    AnalyticsService? analytics,
    CrashReportingService? crashReporting,
  })  : _authRepository = authRepository,
        _analytics = analytics ?? AnalyticsService(),
        _crashReporting = crashReporting ?? CrashReportingService(),
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
      // Set user properties for analytics
      await _analytics.setUserProperties(
        userId: event.user!.id,
        userType: event.user!.userType,
      );
      await _crashReporting.setUserIdentifier(event.user!.id);

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
      // Set user properties for analytics
      await _analytics.setUserProperties(
        userId: user.id,
        userType: user.userType,
      );
      await _crashReporting.setUserIdentifier(user.id);

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
          (failure) {
            _analytics.logError(
              error: 'Auto-verification failed: ${failure.message}',
              context: 'auth_bloc',
            );
            emit(AuthError(message: failure.message));
          },
          (user) async {
            // Log successful login
            await _analytics.logLogin(
              method: 'phone_auto_verification',
              userType: user.userType,
            );
            
            if (user.isOnboarded) {
              emit(AuthAuthenticated(user: user));
            } else {
              emit(AuthNeedsOnboarding(user: user));
            }
          },
        );
      },
      onVerificationFailed: (error) {
        _analytics.logError(
          error: 'Phone verification failed: $error',
          context: 'auth_bloc',
        );
        emit(AuthError(message: error));
      },
    );
    
    result.fold(
      (failure) {
        _analytics.logError(
          error: 'Phone submission failed: ${failure.message}',
          context: 'auth_bloc',
        );
        emit(AuthError(message: failure.message));
      },
      (_) {}, // Success - wait for codeSent callback
    );
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    if (_verificationId == null) {
      _analytics.logError(
        error: 'OTP submitted without verification ID',
        context: 'auth_bloc',
      );
      emit(AuthError(message: 'Verification ID not found'));
      return;
    }
    
    final result = await _authRepository.verifyOTP(
      verificationId: _verificationId!,
      smsCode: event.otpCode,
    );
    
    result.fold(
      (failure) {
        _analytics.logError(
          error: 'OTP verification failed: ${failure.message}',
          context: 'auth_bloc',
        );
        emit(AuthError(message: failure.message));
      },
      (user) async {
        // Determine if this is a new signup or existing login
        final isNewUser = user.createdAt.difference(DateTime.now()).inMinutes.abs() < 5;
        
        if (isNewUser) {
          await _analytics.logSignUp(
            method: 'phone_otp',
            userType: user.userType,
          );
        } else {
          await _analytics.logLogin(
            method: 'phone_otp',
            userType: user.userType,
          );
        }
        
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
    
    await _analytics.logLogout();
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
