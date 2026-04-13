import 'package:flutter/material.dart';
import '../../../../core/widgets/branded_widgets.dart';

class NicVerificationPage extends StatefulWidget {
  const NicVerificationPage({super.key});

  @override
  State<NicVerificationPage> createState() => _NicVerificationPageState();
}

class _NicVerificationPageState extends State<NicVerificationPage> {
  bool _isScanning = false;
  String? _scannedNic;

  Future<void> _simulateCameraScan() async {
    setState(() => _isScanning = true);
    
    // Abstracted: Camera Controller + Google ML Kit OCR invocation
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isScanning = false;
      _scannedNic = '951234567V'; // Simulated OCR Result
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Identity')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'National Identity Card',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'For your security and platform trust, please scan your NIC. This data is handled securely under PDPA guidelines.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // Scan Frame Simulation
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.shade200, width: 2, style: BorderStyle.solid),
                ),
                child: Center(
                  child: _isScanning 
                      ? const CircularProgressIndicator()
                      : _scannedNic != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                                const SizedBox(height: 16),
                                Text('Scanned: $_scannedNic', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.credit_card, size: 64, color: Colors.indigo.shade300),
                                const SizedBox(height: 16),
                                const Text('Position NIC within frame'),
                              ],
                            ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            if (_scannedNic == null)
              BrandedButton(
                label: 'Scan Document',
                onPressed: _isScanning ? () {} : _simulateCameraScan,
              )
            else
              BrandedButton(
                label: 'Continue',
                onPressed: () {
                  // Navigate to next step: Skill Selection
                  // context.go('/worker/onboarding/skills');
                },
              ),
          ],
        ),
      ),
    );
  }
}
