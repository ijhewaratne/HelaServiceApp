import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking_schedule.dart';
import '../repositories/scheduling_repository.dart';

class FindAvailableWorkers
    implements UseCase<List<String>, FindAvailableWorkersParams> {
  final SchedulingRepository repository;
  FindAvailableWorkers(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(
          FindAvailableWorkersParams params) =>
      repository.findAvailableWorkers(
        schedule: params.schedule,
        serviceType: params.serviceType,
        nearLat: params.nearLat,
        nearLng: params.nearLng,
        radiusKm: params.radiusKm,
      );
}

class FindAvailableWorkersParams extends Equatable {
  final BookingSchedule schedule;
  final String serviceType;
  final double? nearLat;
  final double? nearLng;
  final double radiusKm;

  const FindAvailableWorkersParams({
    required this.schedule,
    required this.serviceType,
    this.nearLat,
    this.nearLng,
    this.radiusKm = 15.0,
  });

  @override
  List<Object?> get props => [schedule, serviceType, nearLat, nearLng, radiusKm];
}
