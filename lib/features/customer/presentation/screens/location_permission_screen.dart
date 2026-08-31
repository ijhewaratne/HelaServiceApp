import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  Future<void> _requestPermission(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!context.mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      context.go('/customer/home');
    } else {
      context.go('/customer/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on,
                size: 100,
                color: Color(0xFF1B5E20),
              ),
              const SizedBox(height: 32),
              Text(
                'Allow Location Access',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Sevana uses your location to show nearby verified service providers and estimate availability in your area.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _requestPermission(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Allow Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/customer/home'),
                child: const Text(
                  'Enter Address Manually',
                  style: TextStyle(color: Color(0xFF1B5E20)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
