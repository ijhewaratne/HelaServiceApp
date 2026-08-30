import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/session_repository.dart';

const _sessionIdPrefsKey = 'device_session_id';

class SessionRepositoryImpl implements SessionRepository {
  final FirebaseFirestore _firestore;

  SessionRepositoryImpl(this._firestore);

  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  /// A UUID persisted locally so this device/install reports the same
  /// session id across app restarts (until the app is uninstalled or local
  /// storage is cleared).
  Future<String> _getOrCreateSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_sessionIdPrefsKey);
    if (existing != null) return existing;

    final id = const Uuid().v4();
    await prefs.setString(_sessionIdPrefsKey, id);
    return id;
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  @override
  Future<Either<Failure, void>> recordCurrentSession(String userId) async {
    try {
      final sessionId = await _getOrCreateSessionId();
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId);

      final doc = await ref.get();
      await ref.set({
        'platform': _platform,
        if (!doc.exists) 'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'revokedAt': null,
      }, SetOptions(merge: true));
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<UserSession>>> getSessions(
    String userId,
  ) async {
    try {
      final currentSessionId = await _getOrCreateSessionId();
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .orderBy('lastActiveAt', descending: true)
          .get();

      final sessions = snap.docs.map((doc) {
        final data = doc.data();
        return UserSession(
          id: doc.id,
          platform: data['platform'] as String? ?? 'unknown',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastActiveAt:
              (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          revokedAt: (data['revokedAt'] as Timestamp?)?.toDate(),
          isCurrent: doc.id == currentSessionId,
        );
      }).toList();
      return Right(sessions);
    } on FirebaseException catch (e) {
      return Left(GenericFailure('Firebase error: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> signOutOtherDevices(String userId) async {
    try {
      final sessionId = await _getOrCreateSessionId();
      await _functions.httpsCallable('revokeOtherSessions').call({
        'keepSessionId': sessionId,
      });
      return const Right(null);
    } on FirebaseFunctionsException catch (e) {
      return Left(GenericFailure('Failed to sign out other devices: ${e.message}'));
    } catch (e) {
      return Left(GenericFailure('Unknown error: $e'));
    }
  }
}
