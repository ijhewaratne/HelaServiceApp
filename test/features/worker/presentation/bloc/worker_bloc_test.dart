import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/core/services/location_service.dart';
import 'package:home_service_app/features/worker/domain/entities/worker.dart';
import 'package:home_service_app/features/worker/domain/entities/worker_application.dart';
import 'package:home_service_app/features/worker/domain/repositories/worker_repository.dart';
import 'package:home_service_app/features/worker/presentation/bloc/worker_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'worker_bloc_test.mocks.dart';

@GenerateMocks([WorkerRepository, LocationService])
void main() {
  late WorkerBloc bloc;
  late MockWorkerRepository mockRepository;
  late MockLocationService mockLocationService;

  setUp(() {
    mockRepository = MockWorkerRepository();
    mockLocationService = MockLocationService();
    bloc = WorkerBloc(
      workerRepository: mockRepository,
      locationService: mockLocationService,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('LoadWorker', () {
    final worker = Worker(
      id: 'worker_123',
      nic: '123456789V',
      fullName: 'Test Worker',
      mobileNumber: '+94771234567',
      address: 'Colombo',
      emergencyContactName: 'Emergency',
      emergencyContactPhone: '+94771234568',
      services: [ServiceType.cleaning],
      status: WorkerStatus.approved,
      createdAt: DateTime.now(),
      rating: 4.5,
      totalJobs: 10,
      hasAcceptedContract: true,
    );

    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerLoaded] when successful',
      build: () {
        when(mockRepository.getWorker('worker_123'))
            .thenAnswer((_) async => Right(worker));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadWorker(workerId: 'worker_123')),
      expect: () => [
        WorkerLoading(),
        WorkerLoaded(worker: worker),
      ],
    );

    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerError] when repository fails',
      build: () {
        when(mockRepository.getWorker('worker_123'))
            .thenAnswer((_) async => Left(ServerFailure('Network error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadWorker(workerId: 'worker_123')),
      expect: () => [
        WorkerLoading(),
        WorkerError(message: 'Network error'),
      ],
    );
  });

  group('UpdateOnlineStatus', () {
    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerOnlineStatusUpdated] and starts tracking when going online',
      build: () {
        when(mockRepository.updateOnlineStatus(
          workerId: anyNamed('workerId'),
          isOnline: anyNamed('isOnline'),
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
        )).thenAnswer((_) async => const Right(null));
        when(mockLocationService.startTracking(any))
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateOnlineStatus(
        workerId: 'worker_123',
        isOnline: true,
        lat: 6.9271,
        lng: 79.8612,
      )),
      expect: () => [
        WorkerLoading(),
        const WorkerOnlineStatusUpdated(isOnline: true),
      ],
    );

    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerOnlineStatusUpdated] and stops tracking when going offline',
      build: () {
        when(mockRepository.updateOnlineStatus(
          workerId: anyNamed('workerId'),
          isOnline: anyNamed('isOnline'),
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
        )).thenAnswer((_) async => const Right(null));
        when(mockLocationService.stopTracking())
            .thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateOnlineStatus(
        workerId: 'worker_123',
        isOnline: false,
      )),
      expect: () => [
        WorkerLoading(),
        const WorkerOnlineStatusUpdated(isOnline: false),
      ],
    );

    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerError] when update fails',
      build: () {
        when(mockRepository.updateOnlineStatus(
          workerId: anyNamed('workerId'),
          isOnline: anyNamed('isOnline'),
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
        )).thenAnswer((_) async => Left(ServerFailure('Update failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateOnlineStatus(
        workerId: 'worker_123',
        isOnline: true,
        lat: 6.9271,
        lng: 79.8612,
      )),
      expect: () => [
        WorkerLoading(),
        WorkerError(message: 'Update failed'),
      ],
    );
  });

  group('CheckNICExists', () {
    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerNICCheckResult] when NIC exists',
      build: () {
        when(mockRepository.checkNICExists('123456789V'))
            .thenAnswer((_) async => const Right(true));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckNICExists(nic: '123456789V')),
      expect: () => [
        WorkerLoading(),
        const WorkerNICCheckResult(exists: true),
      ],
    );

    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerNICCheckResult] when NIC does not exist',
      build: () {
        when(mockRepository.checkNICExists('987654321V'))
            .thenAnswer((_) async => const Right(false));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckNICExists(nic: '987654321V')),
      expect: () => [
        WorkerLoading(),
        const WorkerNICCheckResult(exists: false),
      ],
    );
  });

  group('SubmitApplication', () {
    final application = WorkerApplication(
      id: 'app_123',
      nic: '123456789V',
      fullName: 'Test Applicant',
      mobileNumber: '+94771234567',
      address: 'Colombo',
      emergencyContactName: 'Emergency',
      emergencyContactPhone: '+94771234568',
      selectedServices: [app.ServiceType.cleaning],
      status: ApplicationStatus.pendingDocs,
      appliedAt: DateTime.now(),
    );

    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerApplicationSubmitted] when successful',
      build: () {
        when(mockRepository.submitApplication(application))
            .thenAnswer((_) async => Right(application));
        return bloc;
      },
      act: (bloc) => bloc.add(SubmitApplication(application: application)),
      expect: () => [
        WorkerLoading(),
        WorkerApplicationSubmitted(application: application),
      ],
    );
  });

  group('CompleteTraining', () {
    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerTrainingCompleted] when successful',
      build: () {
        when(mockRepository.completeTraining('worker_123'))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const CompleteTraining(workerId: 'worker_123')),
      expect: () => [
        WorkerLoading(),
        WorkerTrainingCompleted(),
      ],
    );
  });

  group('AcceptContract', () {
    blocTest<WorkerBloc, WorkerState>(
      'emits [WorkerLoading, WorkerContractAccepted] when successful',
      build: () {
        when(mockRepository.acceptContract('worker_123'))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const AcceptContract(workerId: 'worker_123')),
      expect: () => [
        WorkerLoading(),
        WorkerContractAccepted(),
      ],
    );
  });
}
