import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository using Firebase
/// 
/// Phase 2: Architecture Refactoring - Updated to use consolidated User entity
class AuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl(this._auth, this._firestore);

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges().asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;
    
    // Fetch additional data from Firestore
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    
    return _mapToUser(firebaseUser, doc);
  });

  @override
  Future<Either<Failure, void>> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(firebase.PhoneAuthCredential credential) onVerificationCompleted,
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
  Future<Either<Failure, User>> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        return Left(AuthFailure('User is null after verification'));
      }
      
      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (!userDoc.exists) {
        // New user - create profile
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'phoneNumber': firebaseUser.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'userType': UserType.unknown.name,
          'isOnboarded': false,
          'isEmailVerified': false,
          'isPhoneVerified': true,
          'status': UserStatus.pendingVerification.name,
        });
      }
      
      return Right(_mapToUser(firebaseUser, userDoc));
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  User? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return User.fromFirebaseUser(firebaseUser);
  }

  @override
  Future<Either<Failure, User>> updateUserType(String userId, UserType userType) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'userType': userType.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return Left(AuthFailure('No authenticated user'));
      }
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return Right(_mapToUser(firebaseUser, userDoc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> markUserOnboarded(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnboarded': true,
        'status': UserStatus.active.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        return Left(AuthFailure('No authenticated user'));
      }
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return Right(_mapToUser(firebaseUser, userDoc));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Helper method to map Firebase user + Firestore data to User entity
  User _mapToUser(firebase.User firebaseUser, DocumentSnapshot firestoreDoc) {
    final data = firestoreDoc.data() as Map<String, dynamic>?;
    
    return User.fromFirebaseUser(
      firebaseUser,
      userType: data != null ? _parseUserType(data['userType']) : null,
    ).copyWith(
      isOnboarded: data?['isOnboarded'] ?? false,
      isEmailVerified: data?['isEmailVerified'] ?? false,
      isPhoneVerified: data?['isPhoneVerified'] ?? true,
      status: data != null ? _parseUserStatus(data['status']) : UserStatus.pendingVerification,
      displayName: data?['displayName'],
      email: data?['email'],
      photoUrl: data?['photoUrl'],
      metadata: data,
    );
  }

  UserType _parseUserType(String? type) {
    switch (type) {
      case 'customer':
        return UserType.customer;
      case 'worker':
        return UserType.worker;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.unknown;
    }
  }

  UserStatus _parseUserStatus(String? status) {
    switch (status) {
      case 'active':
        return UserStatus.active;
      case 'inactive':
        return UserStatus.inactive;
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.pendingVerification;
    }
  }
}
