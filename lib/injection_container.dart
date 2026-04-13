import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/analytics_service.dart';
import 'core/monitoring/crash_reporting.dart';
import 'core/monitoring/performance_monitoring.dart';
import 'core/security/encryption_service.dart';
import 'core/localization/localization_service.dart';
import 'core/providers/theme_provider.dart';

import 'features/incident/services/emergency_service.dart';

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
import 'features/payment/presentation/bloc/payment_bloc.dart';

import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';

import 'features/wallet/data/repositories/wallet_repository_impl.dart';
import 'features/wallet/domain/repositories/wallet_repository.dart';

import 'features/promo/data/repositories/promo_repository_impl.dart';
import 'features/promo/domain/repositories/promo_repository.dart';

import 'features/referral/data/repositories/referral_repository_impl.dart';
import 'features/referral/domain/repositories/referral_repository.dart';

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
  sl.registerLazySingleton(() => CrashReportingService());
  sl.registerLazySingleton(() => PerformanceMonitoring());
  sl.registerLazySingleton(() => EmergencyService(firestore: sl()));
  
  // Localization Service
  sl.registerLazySingletonAsync<LocalizationService>(() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalizationService(prefs);
  });
  
  // Theme Provider
  sl.registerLazySingletonAsync<ThemeProvider>(() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeProvider(prefs);
  });
  
  // Security Services
  // EncryptionService is registered with a factory to allow key rotation
  sl.registerFactory<EncryptionService>(
    () => EncryptionService(
      // Get key from environment - ensure this is set!
      const String.fromEnvironment('ENCRYPTION_KEY', defaultValue: 'dev_key_not_for_production_use_only'),
    ),
  );
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<WorkerRepository>(() => WorkerRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepositoryImpl(sl()));
  sl.registerLazySingleton<BookingRepository>(() => BookingRepositoryImpl(sl(), sl()));
  sl.registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl(sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  
  // Phase 7: Business Features
  sl.registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(sl()));
  sl.registerLazySingleton<PromoRepository>(() => PromoRepositoryImpl(sl()));
  sl.registerLazySingleton<ReferralRepository>(() => ReferralRepositoryImpl(sl()));
  
  // Use Cases
  sl.registerLazySingleton(() => FindNearestWorker(sl()));
  
  // BLoCs - with analytics and monitoring
  sl.registerFactory(() => AuthBloc(
    authRepository: sl(),
    analytics: sl(),
    crashReporting: sl(),
  ));
  sl.registerFactory(() => WorkerBloc(
    workerRepository: sl(),
    locationService: sl(),
  ));
  sl.registerFactory(() => CustomerBloc(
    customerRepository: sl(),
  ));
  sl.registerFactory(() => BookingBloc(
    bookingRepository: sl(),
    findNearestWorker: sl(),
    analytics: sl(),
    performance: sl(),
  ));
  sl.registerFactory(() => PaymentBloc(
    paymentRepository: sl(),
    analytics: sl(),
  ));
}

/// Initialize services that need async setup
Future<void> initServices() async {
  // Initialize notifications
  await sl<NotificationService>().initialize();
  
  // Initialize analytics
  await sl<AnalyticsService>().initialize();
  
  // Initialize crash reporting
  await sl<CrashReportingService>().initialize();
}
