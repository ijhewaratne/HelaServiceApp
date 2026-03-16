import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'core/services/location_service.dart';
import 'features/worker/data/repositories/worker_repository_impl.dart';
import 'features/worker/domain/repositories/worker_repository.dart';
import 'features/worker/presentation/bloc/worker_onboarding_bloc.dart';
import 'features/incident/data/repositories/incident_repository_impl.dart';
import 'features/incident/domain/repositories/incident_repository.dart';
import 'features/incident/services/emergency_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Firebase
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  
  // Services
  sl.registerLazySingleton(() => LocationService(sl()));
  sl.registerLazySingleton(() => EmergencyService(sl(), sl()));
  
  // Repositories
  sl.registerLazySingleton<WorkerRepository>(
    () => WorkerRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<IncidentRepository>(
    () => IncidentRepositoryImpl(sl(), sl()),
  );
  
  // BLoCs
  sl.registerFactory(() => WorkerOnboardingBloc(repository: sl()));
  sl.registerFactory(() => AuthBloc(auth: sl()));
}