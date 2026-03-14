import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'injection_container.dart' as di;

// Provider-based ViewModels (existing layer)
import 'features/auth/data/auth_repository.dart';
import 'features/worker/data/worker_repository.dart';
import 'features/customer/data/booking_repository.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/worker/presentation/viewmodels/worker_viewmodel.dart';
import 'features/customer/presentation/viewmodels/customer_home_viewmodel.dart';
import 'features/customer/presentation/viewmodels/booking_viewmodel.dart';
import 'features/admin/presentation/viewmodels/admin_dashboard_viewmodel.dart';

// BLoC layer (new onboarding flow)
import 'features/worker/presentation/bloc/worker_onboarding_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase — wrapped in try/catch so mock mode still works
  // before `flutterfire configure` is run.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Ignore: firebase_options.dart not yet generated — mock repositories active
    debugPrint('Firebase not configured yet — running in mock mode. Run: flutterfire configure');
  }

  // Initialize get_it dependency injection
  await di.init();

  runApp(
    MultiProvider(
      providers: [
        // --- Existing Provider-based ViewModels ---
        ChangeNotifierProvider(create: (_) => AuthViewModel(AuthRepository())),
        ChangeNotifierProvider(create: (_) => WorkerViewModel(WorkerRepository())),
        ChangeNotifierProvider(create: (_) => CustomerViewModel(BookingRepository())),
        ChangeNotifierProvider(create: (_) => BookingViewModel(BookingRepository())),
        ChangeNotifierProvider(create: (_) => AdminViewModel(AdminRepository())),

        // --- BLoC: Worker Onboarding Flow ---
        BlocProvider<WorkerOnboardingBloc>(
          create: (_) => di.sl<WorkerOnboardingBloc>(),
        ),
      ],
      child: const HomeServiceApp(),
    ),
  );
}

