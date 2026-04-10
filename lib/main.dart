import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'app.dart';
import 'core/services/notification_service.dart';
import 'core/monitoring/bloc_observer.dart';
import 'core/monitoring/crash_reporting.dart';

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
  
  // Set BLoC observer for analytics
  Bloc.observer = AnalyticsBlocObserver();
  
  runApp(const HelaServiceApp());
}
