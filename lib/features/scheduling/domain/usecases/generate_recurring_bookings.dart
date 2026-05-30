import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/booking_schedule.dart';
import '../repositories/scheduling_repository.dart';

class GenerateRecurringBookings
    implements UseCase<List<String>, GenerateRecurringBookingsParams> {
  final SchedulingRepository repository;
  GenerateRecurringBookings(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(
          GenerateRecurringBookingsParams params) =>
      repository.generateRecurringBookings(
        parentBookingId: params.parentBookingId,
        schedule: params.schedule,
        bookingTemplate: params.bookingTemplate,
      );
}

class GenerateRecurringBookingsParams extends Equatable {
  final String parentBookingId;
  final BookingSchedule schedule;
  final Map<String, dynamic> bookingTemplate;

  const GenerateRecurringBookingsParams({
    required this.parentBookingId,
    required this.schedule,
    required this.bookingTemplate,
  });

  @override
  List<Object?> get props => [parentBookingId, schedule];
}
