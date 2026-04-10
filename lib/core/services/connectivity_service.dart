import 'dart:async';

/// Service for monitoring network connectivity
class ConnectivityService {
  final dynamic _connectivity;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isConnected = true;
  StreamSubscription? _subscription;

  ConnectivityService(dynamic connectivity) : _connectivity = connectivity;

  /// Stream of connectivity status
  Stream<bool> get connectivityStream => _controller.stream;

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity status if connectivity object is available
      if (_connectivity != null) {
        // Handle connectivity package API
        final results = await (_connectivity.checkConnectivity() as Future<dynamic>);
        _updateConnectionStatus(results);

        // Listen for connectivity changes
        _listenToConnectivityChanges();
      } else {
        // Assume connected if no connectivity object provided
        _controller.add(true);
      }
    } catch (e) {
      // On error, assume connected
      _controller.add(true);
    }
  }

  /// Listen to connectivity changes
  void _listenToConnectivityChanges() {
    try {
      final stream = _connectivity.onConnectivityChanged;
      if (stream is Stream) {
        _subscription = stream.listen(
          (results) => _updateConnectionStatus(results),
          onError: (_) {
            // On error, maintain current state
          },
        );
      }
    } catch (e) {
      // If listening fails, continue without updates
    }
  }

  /// Update connection status based on connectivity results
  void _updateConnectionStatus(dynamic results) {
    final wasConnected = _isConnected;
    
    // Handle different result types
    if (results is List) {
      // connectivity_plus 5.x+ returns List<ConnectivityResult>
      _isConnected = results.any((result) => 
        result.toString().contains('wifi') || 
        result.toString().contains('mobile') ||
        result.toString().contains('ethernet')
      );
    } else if (results.toString().contains('none') || 
               results.toString().contains('None')) {
      _isConnected = false;
    } else {
      _isConnected = true;
    }

    if (wasConnected != _isConnected || !_controller.hasListener) {
      _controller.add(_isConnected);
    }
  }

  /// Check connectivity once
  Future<bool> checkConnectivity() async {
    try {
      if (_connectivity != null) {
        final results = await (_connectivity.checkConnectivity() as Future<dynamic>);
        _updateConnectionStatus(results);
      }
      return _isConnected;
    } catch (e) {
      return true; // Assume connected on error
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
