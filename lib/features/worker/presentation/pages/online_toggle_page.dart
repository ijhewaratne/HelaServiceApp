import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/location_service.dart';
import '../../../../injection_container.dart';

/// Page for workers to toggle online/offline status
class OnlineTogglePage extends StatefulWidget {
  const OnlineTogglePage({super.key});

  @override
  State<OnlineTogglePage> createState() => _OnlineTogglePageState();
}

class _OnlineTogglePageState extends State<OnlineTogglePage> {
  bool _isOnline = false;
  bool _isLoading = false;
  final LocationService _locationService = sl<LocationService>();

  Future<void> _toggleOnlineStatus() async {
    setState(() => _isLoading = true);

    try {
      if (!_isOnline) {
        // Going online - start location tracking
        await _locationService.startTracking('current_worker_id');
        setState(() => _isOnline = true);
      } else {
        // Going offline - stop location tracking
        await _locationService.stopTracking();
        setState(() => _isOnline = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Online'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOnline ? Colors.green.shade100 : Colors.grey.shade200,
                  border: Border.all(
                    color: _isOnline ? Colors.green : Colors.grey,
                    width: 4,
                  ),
                ),
                child: Icon(
                  _isOnline ? Icons.check_circle : Icons.offline_bolt,
                  size: 100,
                  color: _isOnline ? Colors.green : Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _isOnline ? 'You are Online' : 'You are Offline',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _isOnline
                    ? 'You will receive job offers in your area'
                    : 'Go online to start receiving job offers',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleOnlineStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isOnline ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
