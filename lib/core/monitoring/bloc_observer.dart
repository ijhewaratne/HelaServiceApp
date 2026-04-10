import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/analytics_service.dart';
import 'crash_reporting.dart';

/// BLoC observer for tracking state changes and errors
class AnalyticsBlocObserver extends BlocObserver {
  final AnalyticsService _analytics;
  final CrashReportingService _crashReporting;

  AnalyticsBlocObserver({
    AnalyticsService? analytics,
    CrashReportingService? crashReporting,
  })  : _analytics = analytics ?? AnalyticsService(),
        _crashReporting = crashReporting ?? CrashReportingService();

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      debugPrint('📦 ${bloc.runtimeType} created');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      debugPrint('🔄 ${bloc.runtimeType}: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}');
    }

    // Track state changes that might indicate errors
    final nextState = change.nextState;
    if (nextState.toString().contains('Failure') ||
        nextState.toString().contains('Error')) {
      _analytics.logError(
        error: 'BLoC state error in ${bloc.runtimeType}',
        context: nextState.toString(),
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    
    // Log to Crashlytics
    _crashReporting.logError(
      error,
      stackTrace,
      reason: 'BLoC error in ${bloc.runtimeType}',
    );

    // Log to Analytics
    _analytics.logError(
      error: error.toString(),
      context: bloc.runtimeType.toString(),
      stackTrace: stackTrace.toString(),
    );

    if (kDebugMode) {
      debugPrint('❌ ${bloc.runtimeType} error: $error');
    }
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (kDebugMode) {
      debugPrint('🗑️ ${bloc.runtimeType} closed');
    }
  }
}
