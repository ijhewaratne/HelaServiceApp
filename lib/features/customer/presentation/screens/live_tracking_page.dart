import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/audit_logger.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  // In a real scenario, these would populate from Firebase / Geolocator streams.
  final double _mockDistance = 2.4; 
  final int _mockEta = 12;

  Future<void> _reportEmergency() async {
    // 1. Log incident immutably to AuditLogger for legal protection
    final logger = AuditLogger();
    await logger.logEvent(
      workerId: 'mock_worker_id',
      bookingId: 'mock_booking_id',
      type: AuditEventType.incidentReported,
      payload: {'reportedBy': 'customer', 'severity': 'high'},
    );

    // 2. Launch WhatsApp to Operator Hot-line (Stub)
    final Uri whatsappUri = Uri.parse('whatsapp://send?phone=+94770000000&text=EMERGENCY%20REPORT%20-%20Booking%20ID%20123');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp. Call 119 immediately.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Worker Arriving'),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: Colors.indigo), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // Simulated Map Background Container
          Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: Colors.black26),
                  SizedBox(height: 8),
                  Text('Google Map Embed Instance', style: TextStyle(color: Colors.black45)),
                ],
              ),
            ),
          ),
          
          // Bottom Status Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5)
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Arriving in $_mockEta mins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Distance: $_mockDistance km', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('En Route', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                      )
                    ],
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  // Worker Profile Plate
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.indigo.shade100,
                        child: const Icon(Icons.person, color: Colors.indigo),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saman Perera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('4.9 (120 jobs)', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          )
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.message, color: Colors.indigo),
                      )
                    ],
                  ),

                  const SizedBox(height: 16),
                  
                  // Incident Reporting Stub
                  OutlinedButton.icon(
                    onPressed: _reportEmergency,
                    icon: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    label: const Text('Report Emergency / Incident', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Privacy Note: Live tracking automatically disables once the job status changes to "Checked In" per PDPA guidelines.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
