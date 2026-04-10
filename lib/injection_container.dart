import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';

import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/analytics_service.dart';

import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/worker/data/repositories/worker_repository_impl.dart';
import 'features/worker/domain/repositories/worker_repository.dart';
import 'features/worker/presentation/bloc/worker_bloc.dart';

import 'features/customer/data/repositories/customer_repository_impl.dart';
import 'features/customer/domain/repositories/customer_repository.dart';
import 'features/customer/presentation/bloc/customer_bloc.dart';

import 'features/booking/data/repositories/booking_repository_impl.dart';
import 'features/booking/domain/repositories/booking_repository.dart';
import 'features/booking/presentation/bloc/booking_bloc.dart';

import 'features/matching/domain/usecases/find_nearest_worker.dart';

import 'features/payment/data/repositories/payment_repository_impl.dart';
import 'features/payment/domain/repositories/payment_repository.dart';

import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  
  // Services
  sl.registerLazySingleton(() => LocationService(sl()));
  sl.registerLazySingleton(() => NotificationService(sl(), sl()));
  sl.registerLazySingleton(() => ConnectivityService(sl()));
  sl.registerLazySingleton(() => AnalyticsService());
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<WorkerRepository>(() => WorkerRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl(sl()));
  sl.registerLazySingleton<BookingRepository>(() => BookingRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl());
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  
  // Use Cases
  sl.registerLazySingleton(() => FindNearestWorker(sl()));
  
  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => WorkerBloc(workerRepository: sl(), locationService: sl()));
  sl.registerFactory(() => CustomerBloc(customerRepository: sl()));
  sl.registerFactory(() => BookingBloc(bookingRepository: sl(), findNearestWorker: sl()));
}

/// Initialize services that need async setup
Future<void> initServices() async {
  // Initialize notifications
  await sl<NotificationService>().initialize();
  
  // Initialize analytics
  await sl<AnalyticsService>().initialize();
}
