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

/// Phase 6: DevOps & Monitoring - Production Environment Entry Point
/// 
/// This entry point is used for:
/// - Production deployments via GitHub Actions
/// - Play Store releases
/// - App Store releases
/// - Live user traffic

void main() async {
  // Run in zone for error handling
  runZonedGuarded<Future<void>>(() async {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Load production environment variables
    await dotenv.load(fileName: '.env.production');
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize Firebase with production options
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY_PRODUCTION'),
        appId: String.fromEnvironment('FIREBASE_APP_ID_PRODUCTION'),
        messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID_PRODUCTION'),
        projectId: String.fromEnvironment('FIREBASE_PROJECT_ID_PRODUCTION'),
        storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET_PRODUCTION'),
      ),
    );
    
    // Initialize Crashlytics for production
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Enable performance monitoring for production
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
    
    // Set Crashlytics user ID if available (after auth)
    // FirebaseCrashlytics.instance.setUserIdentifier(userId);
    
    // Initialize dependency injection
    await di.init();
    
    // Run the app
    runApp(const HelaServiceApp());
    
  }, (error, stack) {
    // Handle zone errors
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
