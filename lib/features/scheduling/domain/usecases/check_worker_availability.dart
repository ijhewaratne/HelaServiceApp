import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking_schedule.dart';
import '../repositories/scheduling_repository.dart';

class CheckWorkerAvailability
    implements UseCase<bool, CheckWorkerAvailabilityParams> {
  final SchedulingRepository repository;
  CheckWorkerAvailability(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckWorkerAvailabilityParams params) =>
      repository.checkAvailability(
        workerId: params.workerId,
        schedule: params.schedule,
      );
}

class CheckWorkerAvailabilityParams extends Equatable {
  final String workerId;
  final BookingSchedule schedule;

  const CheckWorkerAvailabilityParams({
    required this.workerId,
    required this.schedule,
  });

  @override
  List<Object?> get props => [workerId, schedule];
}
