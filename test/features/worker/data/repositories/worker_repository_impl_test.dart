import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_app/core/errors/failures.dart';
import 'package:home_service_app/features/worker/data/repositories/worker_repository_impl.dart';
import 'package:home_service_app/features/worker/domain/entities/worker.dart';
import 'package:home_service_app/features/worker/domain/entities/worker_application.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../../test_helpers/firebase_mocks.dart';

void main() {
  late WorkerRepositoryImpl repository;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseStorage mockStorage;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    repository = WorkerRepositoryImpl(mockFirestore, mockStorage);
  });

  group('getWorker', () {
    const workerId = 'worker_123';

    test('should return Worker when document exists', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = createMockDocumentSnapshot(
        id: workerId,
        data: {
          'id': workerId,
          'nic': '123456789V',
          'fullName': 'Test Worker',
          'mobileNumber': '+94771234567',
          'address': 'Colombo',
          'emergencyContactName': 'Emergency',
          'emergencyContactPhone': '+94771234568',
          'services': ['cleaning', 'cooking'],
          'status': 'approved',
          'createdAt': Timestamp.now(),
          'rating': 4.5,
          'totalJobs': 10,
          'hasAcceptedContract': true,
        },
      );
      
      when(mockFirestore.collection('workers')).thenReturn(MockCollectionReference());
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);

      // Act
      final result = await repository.getWorker(workerId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return worker'),
        (worker) {
          expect(worker.id, equals(workerId));
          expect(worker.fullName, equals('Test Worker'));
          expect(worker.status, equals(WorkerStatus.approved));
        },
      );
    });

    test('should return NotFoundFailure when document does not exist', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = createMockDocumentSnapshot(
        id: workerId,
        data: null,
        exists: false,
      );
      
      when(mockFirestore.collection('workers')).thenReturn(MockCollectionReference());
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);

      // Act
      final result = await repository.getWorker(workerId);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('createWorker', () {
    final worker = Worker(
      id: 'worker_123',
      nic: '123456789V',
      fullName: 'Test Worker',
      mobileNumber: '+94771234567',
      address: 'Colombo',
      emergencyContactName: 'Emergency',
      emergencyContactPhone: '+94771234568',
      services: [ServiceType.cleaning],
      status: WorkerStatus.pending,
      createdAt: DateTime.now(),
      rating: 4.0,
      totalJobs: 0,
      hasAcceptedContract: false,
    );

    test('should create worker successfully', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('workers')).thenReturn(MockCollectionReference());
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.createWorker(worker);

      // Assert
      expect(result, equals(Right(worker)));
    });

    test('should return ServerFailure when creation fails', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('workers')).thenReturn(MockCollectionReference());
      when(mockDocRef.set(any)).thenThrow(Exception('Network error'));

      // Act
      final result = await repository.createWorker(worker);

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should return failure'),
      );
    });
  });

  group('checkNICExists', () {
    const nic = '123456789V';

    test('should return true when NIC exists', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([
        createMockQueryDocumentSnapshot(id: 'worker_1', data: {'nic': nic}),
      ]);
      
      when(mockFirestore.collection('workers')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.checkNICExists(nic);

      // Assert
      expect(result, equals(const Right(true)));
    });

    test('should return false when NIC does not exist', () async {
      // Arrange
      final mockQuerySnap = createMockQuerySnapshot([]);
      
      when(mockFirestore.collection('workers')).thenReturn(MockCollectionReference());

      // Act
      final result = await repository.checkNICExists(nic);

      // Assert
      expect(result, equals(const Right(false)));
    });
  });

  group('submitApplication', () {
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

    test('should submit application successfully', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('worker_applications')).thenReturn(MockCollectionReference());
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.submitApplication(application);

      // Assert
      expect(result.isRight(), isTrue);
    });
  });

  group('getApplicationStatus', () {
    const workerId = 'worker_123';

    test('should return application when found', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = createMockDocumentSnapshot(
        id: workerId,
        data: {
          'id': workerId,
          'nic': '123456789V',
          'fullName': 'Test Applicant',
          'mobileNumber': '+94771234567',
          'address': 'Colombo',
          'emergencyContactName': 'Emergency',
          'emergencyContactPhone': '+94771234568',
          'selectedServices': ['cleaning'],
          'status': 'underReview',
          'appliedAt': DateTime.now().toIso8601String(),
          'hasCompletedTraining': false,
        },
      );
      
      when(mockFirestore.collection('worker_applications')).thenReturn(MockCollectionReference());
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);

      // Act
      final result = await repository.getApplicationStatus(workerId);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should return application'),
        (app) {
          expect(app.id, equals(workerId));
          expect(app.status, equals(ApplicationStatus.underReview));
        },
      );
    });
  });

  group('completeTraining', () {
    const workerId = 'worker_123';

    test('should complete training successfully', () async {
      // Arrange
      final mockDocRef = MockDocumentReference();
      when(mockFirestore.collection('worker_applications')).thenReturn(MockCollectionReference());
      when(mockDocRef.update(any)).thenAnswer((_) async {});

      // Act
      final result = await repository.completeTraining(workerId);

      // Assert
      expect(result, equals(const Right(null)));
    });
  });

  group('updateOnlineStatus', () {
    const workerId = 'worker_123';

    test('should update online status with location', () async {
      // Arrange
      final mockWorkerDoc = MockDocumentReference();
      final mockLocationDoc = MockDocumentReference();
      
      when(mockFirestore.collection('workers')).thenReturn(MockCollectionReference());
      when(mockFirestore.collection('worker_locations')).thenReturn(MockCollectionReference());
      when(mockWorkerDoc.update(any)).thenAnswer((_) async {});
      when(mockLocationDoc.set(any, any)).thenAnswer((_) async {});

      // Act
      final result = await repository.updateOnlineStatus(
        workerId: workerId,
        isOnline: true,
        lat: 6.9271,
        lng: 79.8612,
      );

      // Assert
      expect(result, equals(const Right(null)));
    });

    test('should update offline status without location', () async {
      // Arrange
      final mockWorkerDoc = MockDocumentReference();
      final mockLocationDoc = MockDocumentReference();
      
      when(mockFirestore.collection('workers')).thenReturn(MockCollectionReference());
      when(mockFirestore.collection('worker_locations')).thenReturn(MockCollectionReference());
      when(mockWorkerDoc.update(any)).thenAnswer((_) async {});
      when(mockLocationDoc.set(any, any)).thenAnswer((_) async {});

      // Act
      final result = await repository.updateOnlineStatus(
        workerId: workerId,
        isOnline: false,
      );

      // Assert
      expect(result, equals(const Right(null)));
    });
  });
}
