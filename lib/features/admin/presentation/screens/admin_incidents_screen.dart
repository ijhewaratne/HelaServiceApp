import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import '../../../../shared/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/branded_widgets.dart';

class AdminIncidentsScreen extends StatefulWidget {
  const AdminIncidentsScreen({super.key});

  @override
  State<AdminIncidentsScreen> createState() => _AdminIncidentsScreenState();
}

class _AdminIncidentsScreenState extends State<AdminIncidentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Support & Incidents')),
      body: vm.isLoading
        ? const Center(child: CircularProgressIndicator())
        : vm.openIncidents.isEmpty
          ? Center(child: Text('No active incidents', style: TextStyle(color: Colors.grey.shade600)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.openIncidents.length,
              itemBuilder: (context, index) {
                final incident = vm.openIncidents[index];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                            child: const Text('URGENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                          ),
                          Text(incident.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.report_problem, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(incident.description, style: const TextStyle(fontWeight: FontWeight.w600))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Booking ID: ${incident.bookingId}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Text('Reported By: ${incident.reportedBy}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const Divider(height: 30),
                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showConfirmDialog(context, 'Mark this incident as resolved?');
                          if (confirm && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident Resolved')));
                            // In a real app we'd call a ViewModel method here
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Colors.grey.shade300),
                          elevation: 0,
                        ),
                        child: const Text('Mark Resolved'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1);
              },
            ),
    );
  }
}
