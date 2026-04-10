import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:home_service_app/features/worker/domain/repositories/worker_repository.dart';
import 'package:home_service_app/features/worker/domain/entities/worker.dart';
import 'package:home_service_app/core/errors/failures.dart';

@GenerateMocks([WorkerRepository])
import 'worker_repository_test.mocks.dart';

void main() {
  late MockWorkerRepository mockRepository;

  setUp(() {
    mockRepository = MockWorkerRepository();
  });

  group('WorkerRepository', () {
    const testWorkerId = 'worker_123';
    final testWorker = Worker(
      id: testWorkerId,
      nic: '853202937V',
      fullName: 'John Doe',
      mobileNumber: '+94771234567',
      address: '123 Main St, Colombo',
      emergencyContactName: 'Jane Doe',
      emergencyContactPhone: '+94771234568',
      services: [ServiceType.cleaning, ServiceType.cooking],
      status: WorkerStatus.approved,
      createdAt: DateTime.now(),
    );

    test('should create worker successfully', () async {
      // Arrange
      when(mockRepository.createWorker(any))
          .thenAnswer((_) async => Right(testWorker));

      // Act
      final result = await mockRepository.createWorker(testWorker);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (worker) {
          expect(worker.id, testWorkerId);
          expect(worker.nic, '853202937V');
          expect(worker.status, WorkerStatus.approved);
        },
      );
    });

    test('should get worker by ID', () async {
      // Arrange
      when(mockRepository.getWorker(testWorkerId))
          .thenAnswer((_) async => Right(testWorker));

      // Act
      final result = await mockRepository.getWorker(testWorkerId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (worker) {
          expect(worker.id, testWorkerId);
          expect(worker.fullName, 'John Doe');
        },
      );
    });

    test('should return NotFoundFailure for non-existent worker', () async {
      // Arrange
      when(mockRepository.getWorker('non_existent'))
          .thenAnswer((_) async => const Left(NotFoundFailure('Worker not found')));

      // Act
      final result = await mockRepository.getWorker('non_existent');

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('Should return failure'),
      );
    });

    test('should update online status', () async {
      // Arrange
      when(mockRepository.updateOnlineStatus(
        workerId: anyNamed('workerId'),
        isOnline: anyNamed('isOnline'),
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
      )).thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.updateOnlineStatus(
        workerId: testWorkerId,
        isOnline: true,
        lat: 6.9271,
        lng: 79.8612,
      );

      // Assert
      expect(result.isRight(), true);
    });

    test('should accept contract', () async {
      // Arrange
      when(mockRepository.acceptContract(any))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await mockRepository.acceptContract(testWorkerId);

      // Assert
      expect(result.isRight(), true);
    });

    test('should upload NIC document', () async {
      // Arrange
      const testUrl = 'https://storage.example.com/nic_front.jpg';
      when(mockRepository.uploadNICDocument(
        workerId: anyNamed('workerId'),
        file: anyNamed('file'),
        isFront: anyNamed('isFront'),
      )).thenAnswer((_) async => const Right(testUrl));

      // Act
      final result = await mockRepository.uploadNICDocument(
        workerId: testWorkerId,
        file: File('test.jpg'),
        isFront: true,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (url) => expect(url, testUrl),
      );
    });

    test('should upload profile photo', () async {
      // Arrange
      const testUrl = 'https://storage.example.com/profile.jpg';
      when(mockRepository.uploadProfilePhoto(
        workerId: anyNamed('workerId'),
        file: anyNamed('file'),
      )).thenAnswer((_) async => const Right(testUrl));

      // Act
      final result = await mockRepository.uploadProfilePhoto(
        workerId: testWorkerId,
        file: File('profile.jpg'),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (url) => expect(url, testUrl),
      );
    });
  });
}
