import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/worker/domain/entities/worker_application.dart';
import 'package:home_service_app/features/worker/domain/repositories/worker_repository.dart';
import 'package:home_service_app/features/worker/presentation/bloc/worker_onboarding_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'worker_onboarding_bloc_test.mocks.dart';

@GenerateMocks([WorkerRepository])
void main() {
  late WorkerOnboardingBloc bloc;
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
    bloc = WorkerOnboardingBloc(repository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('SubmitPersonalInfo', () {
    const nic = '123456789V';
    const fullName = 'Test Applicant';
    const mobileNumber = '+94771234567';
    const address = 'Colombo';
    const emergencyContactName = 'Emergency Contact';
    const emergencyContactPhone = '+94771234568';

    final application = WorkerApplication(
      nic: nic,
      fullName: fullName,
      mobileNumber: mobileNumber,
      address: address,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      selectedServices: const [],
      appliedAt: DateTime.now(),
    );

    blocTest<WorkerOnboardingBloc, WorkerOnboardingState>(
      'emits [WorkerOnboardingLoading, PersonalInfoSubmitted] when successful',
      build: () {
        when(mockRepository.checkNICExists(nic))
            .thenAnswer((_) async => const Right(false));
        when(mockRepository.submitApplication(any))
            .thenAnswer((_) async => Right(application));
        return bloc;
      },
      act: (bloc) => bloc.add(SubmitPersonalInfo(
        nic: nic,
        fullName: fullName,
        mobileNumber: mobileNumber,
        address: address,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      )),
      expect: () => [
        WorkerOnboardingLoading(),
        isA<PersonalInfoSubmitted>(),
      ],
    );

    blocTest<WorkerOnboardingBloc, WorkerOnboardingState>(
      'emits [WorkerOnboardingLoading, WorkerOnboardingError] when NIC exists',
      build: () {
        when(mockRepository.checkNICExists(nic))
            .thenAnswer((_) async => const Right(true));
        return bloc;
      },
      act: (bloc) => bloc.add(SubmitPersonalInfo(
        nic: nic,
        fullName: fullName,
        mobileNumber: mobileNumber,
        address: address,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      )),
      expect: () => [
        WorkerOnboardingLoading(),
        WorkerOnboardingError('This NIC is already registered'),
      ],
    );
  });

  group('SelectServices', () {
    final initialApplication = WorkerApplication(
      id: 'app_123',
      nic: '123456789V',
      fullName: 'Test Applicant',
      mobileNumber: '+94771234567',
      address: 'Colombo',
      emergencyContactName: 'Emergency',
      emergencyContactPhone: '+94771234568',
      selectedServices: const [],
      status: ApplicationStatus.draft,
      appliedAt: DateTime.now(),
    );

    blocTest<WorkerOnboardingBloc, WorkerOnboardingState>(
      'emits ServicesSelected when services are selected',
      build: () => bloc,
      seed: () => PersonalInfoSubmitted(initialApplication),
      act: (bloc) => bloc.add(SelectServices(const [
        app.ServiceType.cleaning,
        app.ServiceType.cooking,
      ])),
      expect: () => [
        isA<ServicesSelected>(),
      ],
    );
  });

  group('CheckApplicationStatus', () {
    final application = WorkerApplication(
      id: 'app_123',
      nic: '123456789V',
      fullName: 'Test Applicant',
      mobileNumber: '+94771234567',
      address: 'Colombo',
      emergencyContactName: 'Emergency',
      emergencyContactPhone: '+94771234568',
      selectedServices: const [app.ServiceType.cleaning],
      status: ApplicationStatus.approved,
      appliedAt: DateTime.now(),
    );

    blocTest<WorkerOnboardingBloc, WorkerOnboardingState>(
      'emits ApplicationApproved when application is approved',
      build: () {
        when(mockRepository.getApplicationStatus('worker_123'))
            .thenAnswer((_) async => Right(application));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckApplicationStatus(workerId: 'worker_123')),
      expect: () => [
        WorkerOnboardingLoading(),
        isA<ApplicationApproved>(),
      ],
    );

    blocTest<WorkerOnboardingBloc, WorkerOnboardingState>(
      'emits TrainingRequired when training is required',
      build: () {
        final trainingApp = application.copyWith(
          status: ApplicationStatus.trainingRequired,
        );
        when(mockRepository.getApplicationStatus('worker_123'))
            .thenAnswer((_) async => Right(trainingApp));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckApplicationStatus(workerId: 'worker_123')),
      expect: () => [
        WorkerOnboardingLoading(),
        isA<TrainingRequired>(),
      ],
    );

    blocTest<WorkerOnboardingBloc, WorkerOnboardingState>(
      'emits ApplicationRejected when application is rejected',
      build: () {
        final rejectedApp = application.copyWith(
          status: ApplicationStatus.rejected,
          rejectionReason: 'Invalid documents',
        );
        when(mockRepository.getApplicationStatus('worker_123'))
            .thenAnswer((_) async => Right(rejectedApp));
        return bloc;
      },
      act: (bloc) => bloc.add(const CheckApplicationStatus(workerId: 'worker_123')),
      expect: () => [
        WorkerOnboardingLoading(),
        isA<ApplicationRejected>(),
      ],
    );
  });

  group('CompleteTraining', () {
    final application = WorkerApplication(
      id: 'app_123',
      nic: '123456789V',
      fullName: 'Test Applicant',
      mobileNumber: '+94771234567',
      address: 'Colombo',
      emergencyContactName: 'Emergency',
      emergencyContactPhone: '+94771234568',
      selectedServices: const [app.ServiceType.cleaning],
      status: ApplicationStatus.trainingRequired,
      appliedAt: DateTime.now(),
    );

    blocTest<WorkerOnboardingBloc, WorkerOnboardingState>(
      'emits ApplicationApproved when training is completed',
      build: () {
        when(mockRepository.completeTraining('app_123'))
            .thenAnswer((_) async => const Right(null));
        return bloc;
      },
      seed: () => TrainingRequired(application),
      act: (bloc) => bloc.add(CompleteTraining()),
      expect: () => [
        WorkerOnboardingLoading(),
        isA<ApplicationApproved>(),
      ],
    );
  });
}
