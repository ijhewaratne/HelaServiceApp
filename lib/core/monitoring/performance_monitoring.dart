import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance monitoring service for tracking app performance
class PerformanceMonitoring {
  static final PerformanceMonitoring _instance = PerformanceMonitoring._internal();
  factory PerformanceMonitoring() => _instance;
  PerformanceMonitoring._internal();

  final Map<String, DateTime> _timers = {};

  /// Start timing an operation
  void startTimer(String operationName) {
    _timers[operationName] = DateTime.now();
  }

  /// End timing and log duration
  int? endTimer(String operationName, {bool logToConsole = true}) {
    final startTime = _timers.remove(operationName);
    if (startTime == null) return null;

    final duration = DateTime.now().difference(startTime);
    final milliseconds = duration.inMilliseconds;

    if (logToConsole) {
      developer.log(
        '$operationName took ${milliseconds}ms',
        name: 'Performance',
        time: DateTime.now(),
      );
    }

    return milliseconds;
  }

  /// Measure async operation
  Future<T> measure<T>(
    String operationName,
    Future<T> Function() operation, {
    void Function(int duration)? onComplete,
  }) async {
    startTimer(operationName);
    try {
      return await operation();
    } finally {
      final duration = endTimer(operationName, logToConsole: false);
      if (duration != null) {
        developer.log(
          '$operationName completed in $duration ms',
          name: 'Performance',
        );
        onComplete?.call(duration);
      }
    }
  }

  /// Log memory usage
  void logMemoryUsage(String context) {
    // Note: Actual memory usage requires platform-specific implementation
    developer.log(
      'Memory check at: $context',
      name: 'Performance',
    );
  }

  /// Track frame build time
  void trackFrame(String frameName, VoidCallback build) {
    final stopwatch = Stopwatch()..start();
    build();
    stopwatch.stop();

    final microseconds = stopwatch.elapsedMicroseconds;
    if (microseconds > 16666) {
      // 16.66ms = 60fps
      developer.log(
        'SLOW FRAME: $frameName took ${microseconds}μs',
        name: 'Performance',
        level: 900,
      );
    }
  }
}
