import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl(this._auth, this._firestore);

  @override
  Stream<UserEntity?> get authStateChanges => _auth.authStateChanges().asyncMap((user) async {
    if (user == null) return null;
    
    // Fetch additional data from Firestore
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserEntity.fromJson({
        'id': user.uid,
        'phoneNumber': user.phoneNumber ?? '',
        ...doc.data()!,
      });
    }
    
    return UserEntity(
      id: user.uid,
      phoneNumber: user.phoneNumber ?? '',
    );
  });

  @override
  Future<Either<Failure, void>> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(String error) onVerificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: (e) => onVerificationFailed(e.message ?? 'Verification failed'),
        codeSent: (verificationId, _) => onCodeSent(verificationId),
        codeAutoRetrievalTimeout: (_) {},
        timeout: const Duration(seconds: 60),
      );
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user == null) {
        return Left(AuthFailure('User is null after verification'));
      }
      
      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        // New user - create profile
        await _firestore.collection('users').doc(user.uid).set({
          'phoneNumber': user.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'userType': 'unknown', // Will be set during onboarding
          'isOnboarded': false,
        });
      }
      
      return Right(UserEntity(
        id: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        isOnboarded: userDoc.data()?['isOnboarded'] ?? false,
        userType: userDoc.data()?['userType'] ?? 'unknown',
      ));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  UserEntity? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return UserEntity(
      id: user.uid,
      phoneNumber: user.phoneNumber ?? '',
    );
  }
}
