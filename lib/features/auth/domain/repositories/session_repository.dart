import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_session.dart';

abstract class SessionRepository {
  /// Records (or refreshes lastActiveAt for) this device's session under
  /// [userId]. Call once per app start after successful sign-in.
  Future<Either<Failure, void>> recordCurrentSession(String userId);

  /// All sessions for [userId], most recently active first.
  Future<Either<Failure, List<UserSession>>> getSessions(String userId);

  /// Firebase Auth cannot revoke a single refresh token — only all of them
  /// for a user at once. This signs the user out of every device except the
  /// current one (which keeps its still-valid ID token until it naturally
  /// expires and tries to refresh).
  Future<Either<Failure, void>> signOutOtherDevices(String userId);
}
