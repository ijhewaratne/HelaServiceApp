import 'package:flutter/material.dart';
import '../../../../core/widgets/branded_widgets.dart';

class ContractAcceptancePage extends StatefulWidget {
  const ContractAcceptancePage({super.key});

  @override
  State<ContractAcceptancePage> createState() => _ContractAcceptancePageState();
}

class _ContractAcceptancePageState extends State<ContractAcceptancePage> {
  bool _hasReadTerms = false;

  void _acceptContract() async {
    if (!_hasReadTerms) return;

    // Simulate PDF Generation, Digital Signature Hash, and Audit Logging
    // final auditLogger = AuditLogger();
    // await auditLogger.logEvent(
    //   workerId: FirebaseAuth.instance.currentUser!.uid,
    //   bookingId: 'ONBOARDING',
    //   type: AuditEventType.contractAccepted,
    //   payload: {'timestamp': DateTime.now().toIso8601String(), 'ipAddress': '192.168.1.1'},
    // );
    
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // context.go('/worker/dashboard/live');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contract Acceptance'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.gavel, size: 60, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'Independent Contractor Agreement',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    '''This Independent Contractor Agreement ("Agreement") is entered into by and between the Platform and the Service Provider ("Contractor").\n\n1. Relationship of Parties: The Contractor is an independent contractor and is not an employee, agent, or partner of the Platform. The Contractor explicitly waives any claims to EPF, ETF, or Gratuity funds under the Department of Labour regulations.\n\n2. Service Standards: The Contractor agrees to maintain the highest level of professionalism and quality in accordance with Sri Lankan cultural norms.\n\n3. Data Protection: The Contractor agrees to abide by the provisions of the Personal Data Protection Act (PDPA) regarding customer information.\n\n[Full 14-page legal text omitted for MVP...]''',
                    style: TextStyle(height: 1.5, color: Colors.black87),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _hasReadTerms,
                  activeColor: Colors.indigo,
                  onChanged: (value) {
                    setState(() => _hasReadTerms = value ?? false);
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _hasReadTerms = !_hasReadTerms),
                    child: const Text(
                      'I have read and legally agree to the terms of the Independent Contractor Agreement. My device signature will be recorded.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            BrandedButton(
              label: 'Sign & Accept Contract',
              backgroundColor: _hasReadTerms ? Colors.indigo : Colors.grey,
              onPressed: _hasReadTerms ? _acceptContract : () {},
            ),
          ],
        ),
      ),
    );
  }
}
