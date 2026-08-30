import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/consent_record.dart';

abstract class ConsentRepository {
  /// Record that [userId] accepted [version] of [documentType] just now.
  Future<Either<Failure, void>> recordAcceptance({
    required String userId,
    required ConsentDocumentType documentType,
    required String version,
  });

  /// True if [userId] has an acceptance record for [documentType] at exactly
  /// [currentVersion] — a prior acceptance of an older version doesn't count.
  Future<Either<Failure, bool>> hasAcceptedCurrentVersion({
    required String userId,
    required ConsentDocumentType documentType,
    required String currentVersion,
  });

  /// Full acceptance history for a user, newest first.
  Future<Either<Failure, List<ConsentRecord>>> getAcceptances(String userId);
}
