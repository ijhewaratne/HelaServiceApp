import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Stream of auth state changes
  Stream<UserEntity?> get authStateChanges;

  /// Verify phone number and send OTP
  Future<Either<Failure, void>> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String error) onVerificationFailed,
  });

  /// Verify OTP and sign in
  Future<Either<Failure, UserEntity>> verifyOTP({
    required String verificationId,
    required String smsCode,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Get current authenticated user
  UserEntity? get currentUser;
}
