import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../domain/entities/promo_code_entity.dart';
import '../../domain/repositories/promo_repository.dart';

class PromoRepositoryImpl implements PromoRepository {
  final FirebaseFirestore _firestore;

  PromoRepositoryImpl(this._firestore);

  @override
  Future<Either<Failure, PromoCodeEntity>> getPromoCode(String code) async =>
      const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, ValidationResult>> validatePromoCode({
    required String code,
    required double orderAmount,
    required ServiceType serviceType,
    required String zoneId,
    required String userId,
  }) async => const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, double>> applyPromoCode({
    required String code,
    required String userId,
    required String bookingId,
    required double orderAmount,
  }) async => const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, List<PromoCodeEntity>>> getActivePromoCodes({
    String? userId,
    ServiceType? serviceType,
    String? zoneId,
  }) async => const Right([]);

  @override
  Future<Either<Failure, bool>> hasUserUsedPromoCode({
    required String userId,
    required String promoCode,
  }) async => const Right(false);

  @override
  Future<Either<Failure, List<PromoCodeUsage>>> getUserPromoUsage({
    required String userId,
    int limit = 50,
  }) async => const Right([]);

  @override
  Future<Either<Failure, PromoCodeEntity>> createPromoCode(
    PromoCodeEntity promoCode,
  ) async => const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, PromoCodeEntity>> updatePromoCode(
    PromoCodeEntity promoCode,
  ) async => const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, void>> deactivatePromoCode(String code) async =>
      const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, PromoCodeStatistics>> getPromoCodeStatistics(
    String code,
  ) async => const Left(GenericFailure('Not implemented'));

  @override
  Future<Either<Failure, List<PromoCodeEntity>>> getTrendingPromoCodes({
    int limit = 10,
  }) async => const Right([]);
}
