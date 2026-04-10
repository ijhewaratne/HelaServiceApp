import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/analytics_service.dart';
import '../services/location_service.dart';
import '../services/connectivity_service.dart';
import 'performance_monitoring.dart';

/// Debug monitoring dashboard for development builds
/// Shows real-time app metrics and allows testing analytics
class DebugDashboard extends StatefulWidget {
  const DebugDashboard({super.key});

  @override
  State<DebugDashboard> createState() => _DebugDashboardState();
}

class _DebugDashboardState extends State<DebugDashboard> {
  final _analytics = AnalyticsService();
  final _performance = PerformanceMonitoring();
  bool _isLocationTracking = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkServices();
  }

  Future<void> _checkServices() async {
    final connectivity = ConnectivityService(FirebaseFirestore.instance);
    final isOnline = await connectivity.checkConnectivity();
    setState(() {
      _isOnline = isOnline;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🔧 Debug Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isOnline ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Analytics Section
              _buildSection(
                title: '📊 Analytics',
                children: [
                  _buildButton(
                    'Test Booking Event',
                    () => _analytics.logBookingCreated(
                      bookingId: 'test_123',
                      serviceType: 'cleaning',
                      estimatedPrice: 1500,
                      zone: 'colombo',
                    ),
                  ),
                  _buildButton(
                    'Test Payment Event',
                    () => _analytics.logPaymentSuccess(
                      paymentId: 'pay_123',
                      bookingId: 'test_123',
                      amount: 1500,
                      method: 'card',
                    ),
                  ),
                  _buildButton(
                    'Test Error Event',
                    () => _analytics.logError(
                      error: 'Test error from debug dashboard',
                      context: 'debug_dashboard',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Performance Section
              _buildSection(
                title: '⚡ Performance',
                children: [
                  _buildButton(
                    'Measure Operation',
                    () async {
                      final duration = await _performance.measure(
                        'test_operation',
                        () async {
                          await Future.delayed(const Duration(milliseconds: 500));
                          return 'done';
                        },
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Operation took ${duration}ms')),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Services Section
              _buildSection(
                title: '🔌 Services',
                children: [
                  _buildToggle(
                    'Location Tracking',
                    _isLocationTracking,
                    (value) {
                      setState(() => _isLocationTracking = value);
                      if (value) {
                        LocationService(FirebaseFirestore.instance).startTracking('debug_worker');
                      }
                    },
                  ),
                  _buildButton(
                    'Check Memory',
                    () {
                      PerformanceMonitoring().logMemoryUsage('debug_dashboard');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Memory usage logged')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildToggle(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.blue[700],
        ),
      ],
    );
  }
}

/// Debug dashboard overlay widget
class DebugDashboardOverlay extends StatelessWidget {
  final Widget child;

  const DebugDashboardOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;

    return Stack(
      children: [
        child,
        const Positioned.fill(
          child: DebugDashboard(),
        ),
      ],
    );
  }
}
