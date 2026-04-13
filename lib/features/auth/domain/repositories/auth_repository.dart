import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Abstract repository for authentication operations
/// 
/// Phase 2: Architecture Refactoring - Updated to use consolidated User entity
abstract class AuthRepository {
  /// Stream of auth state changes
  Stream<User?> get authStateChanges;

  /// Verify phone number and send OTP
  Future<Either<Failure, void>> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String error) onVerificationFailed,
  });

  /// Verify OTP and sign in
  Future<Either<Failure, User>> verifyOTP({
    required String verificationId,
    required String smsCode,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Get current authenticated user
  User? get currentUser;

  /// Update user type after role selection
  Future<Either<Failure, User>> updateUserType(String userId, UserType userType);

  /// Mark user as onboarded
  Future<Either<Failure, User>> markUserOnboarded(String userId);
}
