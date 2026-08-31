import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Abstract repository for authentication operations
///
/// Phase 2: Architecture Refactoring - Updated to use consolidated User entity
abstract class AuthRepository {
  /// Stream of auth state changes (emits custom User entity)
  Stream<User?> get authStateChanges;

  /// Verify phone number and send OTP
  Future<Either<Failure, void>> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(firebase.PhoneAuthCredential credential)
    onVerificationCompleted,
    required Function(String error) onVerificationFailed,
  });

  /// Verify OTP and sign in. If the account has a second factor enrolled,
  /// this returns Left(MfaRequiredFailure) instead of failing outright —
  /// call [completeMfaChallenge] next with the authenticator code.
  Future<Either<Failure, User>> verifyOTP({
    required String verificationId,
    required String smsCode,
  });

  /// Completes a sign-in that verifyOTP paused for a second factor.
  /// Only valid immediately after a Left(MfaRequiredFailure) from verifyOTP.
  Future<Either<Failure, User>> completeMfaChallenge({
    required String totpCode,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Get raw Firebase user (for auth checks only)
  firebase.User? get currentFirebaseUser;

  /// Get current user as app entity (requires Firestore lookup)
  Future<User?> getCurrentUser();

  /// Update user type after role selection
  Future<Either<Failure, User>> updateUserType(
    String userId,
    UserType userType,
  );

  /// Mark user as onboarded
  Future<Either<Failure, User>> markUserOnboarded(String userId);
}
