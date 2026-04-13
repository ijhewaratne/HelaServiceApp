import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/monitoring/bloc_observer.dart';
import 'core/monitoring/crash_reporting.dart';
import 'core/bloc/performance_mixin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Portrait only for v1
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Crashlytics
  await CrashReportingService().initialize();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Dependency Injection
  await di.init();
  
  // Initialize services
  await di.initServices();
  
  // Initialize Firebase App Check for API security
  await _initializeAppCheck();
  
  // Set BLoC observer for analytics (use PerformanceBlocObserver in debug)
  Bloc.observer = kDebugMode 
      ? PerformanceBlocObserver(trackEventProcessingTime: true)
      : AnalyticsBlocObserver();
  
  runApp(const HelaServiceApp());
}

/// Initialize Firebase App Check to protect backend resources
/// 
/// Sprint 5: Security Hardening
/// - Uses Play Integrity for Android (production)
/// - Uses Debug provider for Android (development)
/// - Uses App Attest for iOS (production)
/// - Uses Debug provider for iOS (development)
Future<void> _initializeAppCheck() async {
  try {
    final appCheck = FirebaseAppCheck.instance;
    
    if (kDebugMode) {
      // Debug provider for development
      await appCheck.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      debugPrint('🔒 Firebase App Check initialized (DEBUG mode)');
    } else {
      // Production providers
      await appCheck.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.appAttest,
      );
      debugPrint('🔒 Firebase App Check initialized (PRODUCTION mode)');
    }
    
    // Set token refresh interval (optional, default is reasonable)
    // Token is automatically refreshed every 1 hour
  } catch (e) {
    // Log but don't crash - App Check is defense in depth
    debugPrint('⚠️ Firebase App Check initialization failed: $e');
    // In production, you might want to report this to Crashlytics
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'App Check initialization failed',
      );
    }
  }
}
