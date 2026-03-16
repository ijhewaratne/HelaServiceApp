import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;

  AuthBloc({required FirebaseAuth auth}) : _auth = auth, super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedOut>(_onLoggedOut);
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        add(AppStarted());
      }
    });
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final user = _auth.currentUser;
    if (user != null) {
      emit(Authenticated(userId: user.uid));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    await _auth.signOut();
    emit(Unauthenticated());
  }
}

// Events
abstract class AuthEvent {}

class AppStarted extends AuthEvent {}
class LoggedOut extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final String userId;
  Authenticated({required this.userId});
  
  @override
  List<Object?> get props => [userId];
}
class Unauthenticated extends AuthState {}