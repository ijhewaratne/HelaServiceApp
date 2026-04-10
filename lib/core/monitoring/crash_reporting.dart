import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive crash reporting service
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  bool _initialized = false;

  /// Initialize Crashlytics
  Future<void> initialize() async {
    if (_initialized) return;

    // Pass all uncaught errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    _initialized = true;
    debugPrint('✓ Crashlytics initialized');
  }

  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String userId) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Set custom keys for crash context
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    for (final entry in keys.entries) {
      final value = entry.value;
      if (value is String) {
        await FirebaseCrashlytics.instance.setCustomKey(entry.key, value);
      } else if (value is int) {
        await FirebaseCrashlytics.instance.setCustomKey(entry.key, value);
      } else if (value is double) {
        await FirebaseCrashlytics.instance.setCustomKey(entry.key, value);
      } else if (value is bool) {
        await FirebaseCrashlytics.instance.setCustomKey(entry.key, value);
      }
    }
  }

  /// Log non-fatal error
  Future<void> logError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Log custom message
  Future<void> log(String message) async {
    await FirebaseCrashlytics.instance.log(message);
  }
}

/// Mixin for automatic error tracking in BLoCs
mixin ErrorTrackingMixin {
  Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      await CrashReportingService().logError(
        e,
        stackTrace,
        reason: 'Operation failed: $operationName',
      );
      rethrow;
    }
  }
}
