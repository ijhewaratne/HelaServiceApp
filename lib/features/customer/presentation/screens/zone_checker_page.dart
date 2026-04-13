import 'package:flutter/material.dart';
import '../../../../core/widgets/branded_widgets.dart';

class ZoneCheckerPage extends StatefulWidget {
  const ZoneCheckerPage({super.key});

  @override
  State<ZoneCheckerPage> createState() => _ZoneCheckerPageState();
}

class _ZoneCheckerPageState extends State<ZoneCheckerPage> {
  final TextEditingController _addressController = TextEditingController();
  bool _isChecking = false;
  bool? _isAvailable;

  void _checkAvailability() async {
    if (_addressController.text.trim().isEmpty) return;

    setState(() {
      _isChecking = true;
      _isAvailable = null;
    });

    // Simulated Google Places API & Geocoding delay mapping to ColomboZones
    await Future.delayed(const Duration(seconds: 2));

    final address = _addressController.text.toLowerCase();
    
    // Simple mock logic relying on Sri Lanka Zone rules defined earlier
    bool available = address.contains('colombo') || 
                     address.contains('kollupitiya') || 
                     address.contains('bambalapitiya') ||
                     address.contains('kotte');

    setState(() {
      _isChecking = false;
      _isAvailable = available;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Availability')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Where do you need service?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'We are currently operating in select Colombo zones. Enter your address or city to see if we cover your area.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'e.g., Colombo 03, Kotte',
                prefixIcon: const Icon(Icons.location_on, color: Colors.indigo),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              onSubmitted: (_) => _checkAvailability(),
            ),
            const SizedBox(height: 24),

            if (_isChecking)
              const Center(child: CircularProgressIndicator())
            else if (_isAvailable != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isAvailable! ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isAvailable! ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAvailable! ? Icons.check_circle : Icons.cancel,
                      color: _isAvailable! ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _isAvailable! 
                            ? 'Great news! We have workers available in your area.'
                            : 'Sorry, we are not currently launching services in that zone. We hope to expand soon.',
                        style: TextStyle(
                          color: _isAvailable! ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),
            BrandedButton(
              label: _isAvailable == true ? 'Continue to Booking' : 'Check Area',
              onPressed: _isAvailable == true 
                  ? () {
                      // Navigate to Service Selection page
                      // context.go('/customer/book/services');
                    }
                  : _checkAvailability,
              backgroundColor: _isAvailable == false ? Colors.grey : Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }
}
