import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Mixin for optimizing BLoC state updates
/// 
/// Usage:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState> with BlocPerformanceMixin<MyState> {
///   MyBloc() : super(MyState()) {
///     on<MyEvent>(_onEvent, transformer: throttleEvent(throttleDuration));
///   }
/// }
/// ```
mixin BlocPerformanceMixin<S> on BlocBase<S> {
  /// Emits state only if it's different from current state
  /// Use this instead of emit() when state equality matters
  void emitIfChanged(S newState) {
    if (newState != state) {
      // ignore: invalid_use_of_visible_for_testing_member
      emit(newState);
    }
  }
}

/// Build optimization predicates for BlocBuilder
/// 
/// These predicates help prevent unnecessary widget rebuilds
/// by comparing only the relevant state properties
class BuildOptimization {
  BuildOptimization._();

  /// Builds only when loading state changes
  static bool whenLoadingChanged<S extends LoadingState>(
    S previous,
    S current,
  ) {
    return previous.isLoading != current.isLoading;
  }

  /// Builds only when error state changes
  static bool whenErrorChanged<S extends ErrorState>(
    S previous,
    S current,
  ) {
    return previous.hasError != current.hasError ||
        previous.errorMessage != current.errorMessage;
  }

  /// Builds only when data changes (not loading/error)
  static bool whenDataChanged<S extends DataState<T>, T>(
    S previous,
    S current,
  ) {
    return previous.data != current.data;
  }

  /// Builds only when specific property changes
  /// 
  /// Example:
  /// ```dart
  /// BlocBuilder<MyBloc, MyState>(
  ///   buildWhen: (prev, curr) => 
  ///     BuildOptimization.whenPropertyChanged(prev, curr, (s) => s.count),
  ///   builder: (context, state) => Text('${state.count}'),
  /// )
  /// ```
  static bool whenPropertyChanged<T, V>(
    T previous,
    T current,
    V Function(T) selector,
  ) {
    return selector(previous) != selector(current);
  }

  /// Builds when any of the specified properties change
  static bool whenAnyPropertyChanged<T>(
    T previous,
    T current,
    List<Object? Function(T)> selectors,
  ) {
    for (final selector in selectors) {
      if (selector(previous) != selector(current)) {
        return true;
      }
    }
    return false;
  }
}

/// Interface for states with loading information
abstract class LoadingState {
  bool get isLoading;
}

/// Interface for states with error information
abstract class ErrorState {
  bool get hasError;
  String? get errorMessage;
}

/// Interface for states with data
abstract class DataState<T> {
  T get data;
}

/// Optimized base state class with equality support
/// 
/// Extend this class for better performance in BLoCs
abstract class OptimizedState {
  const OptimizedState();

  /// List of properties to use for equality comparison
  List<Object?> get props;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OptimizedState) return false;
    if (runtimeType != other.runtimeType) return false;
    return _listEquals(props, other.props);
  }

  @override
  int get hashCode => Object.hashAll(props);
}

/// Utility function for list equality
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Event transformer utilities for performance
class EventTransformers {
  EventTransformers._();

  /// Throttles events to prevent rapid-fire updates
  /// 
  /// Usage:
  /// ```dart
  /// on<MyEvent>(
  ///   _handleEvent,
  ///   transformer: EventTransformers.throttle(const Duration(milliseconds: 100)),
  /// )
  /// ```
  static EventTransformer<E> throttle<E>(Duration duration) {
    return (events, mapper) {
      return events
          .throttleTime(duration)
          .asyncExpand(mapper);
    };
  }

  /// Debounces events to wait for pause in input
  /// 
  /// Usage for search inputs:
  /// ```dart
  /// on<SearchQueryChanged>(
  ///   _handleSearch,
  ///   transformer: EventTransformers.debounce(const Duration(milliseconds: 300)),
  /// )
  /// ```
  static EventTransformer<E> debounce<E>(Duration duration) {
    return (events, mapper) {
      return events
          .debounceTime(duration)
          .asyncExpand(mapper);
    };
  }
}

/// Extension on Stream for throttle/debounce operators
extension StreamPerformanceExtension<T> on Stream<T> {
  /// Throttles the stream (emits first, then ignores for duration)
  Stream<T> throttleTime(Duration duration) {
    Timer? throttleTimer;
    return transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          if (throttleTimer?.isActive != true) {
            sink.add(data);
            throttleTimer = Timer(duration, () {});
          }
        },
      ),
    );
  }

  /// Debounces the stream (waits for pause, then emits last)
  Stream<T> debounceTime(Duration duration) {
    Timer? debounceTimer;
    return transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          debounceTimer?.cancel();
          debounceTimer = Timer(duration, () => sink.add(data));
        },
        handleDone: (sink) {
          debounceTimer?.cancel();
          sink.close();
        },
      ),
    );
  }
}

/// Performance-optimized BLoC observer
/// 
/// Use this to track BLoC performance in development
class PerformanceBlocObserver extends BlocObserver {
  final bool trackEventProcessingTime;
  final bool logStateChanges;

  PerformanceBlocObserver({
    this.trackEventProcessingTime = true,
    this.logStateChanges = false,
  });

  final Map<String, DateTime> _eventStartTimes = {};

  @override
  void onEvent(BlocBase<dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (trackEventProcessingTime) {
      _eventStartTimes[bloc.runtimeType.toString()] = DateTime.now();
    }
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);

    final key = bloc.runtimeType.toString();
    if (trackEventProcessingTime && _eventStartTimes.containsKey(key)) {
      final startTime = _eventStartTimes[key];
      if (startTime != null) {
        final duration = DateTime.now().difference(startTime);
        _eventStartTimes.remove(key);

        // Log slow transitions (> 100ms)
        if (duration.inMilliseconds > 100) {
          // ignore: avoid_print
          print('⚠️ SLOW BLoC: ${bloc.runtimeType} took ${duration.inMilliseconds}ms');
        }
      }
    }

    if (logStateChanges) {
      // ignore: avoid_print
      print('📊 ${bloc.runtimeType}: ${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType}');
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    // ignore: avoid_print
    print('❌ BLoC Error in ${bloc.runtimeType}: $error');
    super.onError(bloc, error, stackTrace);
  }
}
