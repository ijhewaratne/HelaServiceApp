import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'features/worker/data/repositories/worker_repository_impl.dart';
import 'features/worker/domain/repositories/worker_repository.dart';
import 'features/worker/presentation/bloc/worker_onboarding_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Firebase
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  
  // Repositories
  sl.registerLazySingleton<WorkerRepository>(
    () => WorkerRepositoryImpl(sl(), sl()),
  );
  
  // BLoCs
  sl.registerFactory(() => WorkerOnboardingBloc(repository: sl()));
}