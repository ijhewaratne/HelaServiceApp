import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'injection_container.dart' as di;
import 'core/services/location_service.dart';
import 'features/worker/presentation/bloc/worker_onboarding_bloc.dart';
import 'features/worker/presentation/pages/nic_input_page.dart';
import 'features/worker/presentation/pages/service_selection_page.dart';
import 'features/worker/presentation/pages/document_upload_page.dart';
import 'features/worker/presentation/pages/verification_pending_page.dart';
import 'features/worker/presentation/pages/job_offer_page.dart';
import 'features/worker/presentation/pages/active_job_page.dart';
import 'features/worker/presentation/pages/online_toggle_page.dart';
import 'features/incident/presentation/pages/incident_report_page.dart';
import 'features/admin/presentation/pages/emergency_dashboard.dart';
import 'features/auth/presentation/pages/phone_auth_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to portrait for v1 (cleaner UI for workers)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // Add this file via FlutterFire CLI
  );
  
  // Initialize Dependency Injection
  await di.init();
  
  // Location service singleton
  final locationService = di.sl<LocationService>();
  
  runApp(MyApp(locationService: locationService));
}

class MyApp extends StatelessWidget {
  final LocationService locationService;

  const MyApp({Key? key, required this.locationService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<WorkerOnboardingBloc>()),
      ],
      child: MaterialApp.router(
        title: 'HelaService', // Your Sri Lankan brand
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routerConfig: _router,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.teal,
      scaffoldBackgroundColor: Colors.grey[50],
      useMaterial3: true,
      fontFamily: 'NotoSansSinhala', // Add this font for Sinhala support
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}