import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'injection_container.dart' as di;

/// Phase 6: DevOps & Monitoring - Staging Environment Entry Point
/// 
/// This entry point is used for:
/// - Staging deployments via GitHub Actions
/// - QA testing
/// - Internal testing
/// - Pre-production validation

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialization();
  
  // Load staging environment variables
  await dotenv.load(fileName: '.env.staging');
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase with staging options
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY_STAGING'),
      appId: String.fromEnvironment('FIREBASE_APP_ID_STAGING'),
      messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_STAGING'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID_STAGING'),
      storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET_STAGING'),
    ),
  );
  
  // Initialize Crashlytics for staging
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  // Enable performance monitoring for staging
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
  
  // Initialize dependency injection
  await di.init();
  
  // Run the app with staging configuration
  runApp(const HelaServiceAppStaging());
}

/// Staging-specific app configuration
class HelaServiceAppStaging extends StatelessWidget {
  const HelaServiceAppStaging({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelaService Staging',
      debugShowCheckedModeBanner: false,
      // Show staging banner
      builder: (context, child) {
        return Banner(
          message: 'STAGING',
          location: BannerLocation.topEnd,
          color: Colors.orange,
          child: child!,
        );
      },
      home: const _StagingInitializer(),
    );
  }
}

/// Initialize the main app after showing staging info
class _StagingInitializer extends StatefulWidget {
  const _StagingInitializer();

  @override
  State<_StagingInitializer> createState() => _StagingInitializerState();
}

class _StagingInitializerState extends State<_StagingInitializer> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Add a small delay to show staging banner
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      // Navigate to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HelaServiceApp(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading Staging Environment...'),
          ],
        ),
      ),
    );
  }
}
