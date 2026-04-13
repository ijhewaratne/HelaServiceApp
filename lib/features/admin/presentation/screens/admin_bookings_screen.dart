import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import '../../../../shared/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/branded_widgets.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
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
      appBar: AppBar(title: const Text('Dispatch Board')),
      body: vm.isLoading
        ? const Center(child: CircularProgressIndicator())
        : vm.activeBookings.isEmpty
          ? Center(child: Text('No active bookings', style: TextStyle(color: Colors.grey.shade600)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.activeBookings.length,
              itemBuilder: (context, index) {
                final booking = vm.activeBookings[index];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(booking.serviceType.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: booking.status == 'draft' ? Colors.red.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                            child: Text(booking.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: booking.status == 'draft' ? Colors.red.shade900 : Colors.blue.shade900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Text('${booking.bookingDate} at ${booking.startTime} (${booking.durationHours}h)'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Expanded(child: Text(booking.addressText, style: const TextStyle(color: Colors.grey))),
                        ],
                      ),
                      const Divider(height: 30),
                      if (booking.workerId == null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showConfirmDialog(context, 'Assign mock worker to this job?');
                            if (confirm && context.mounted) {
                              await context.read<AdminViewModel>().manuallyAssignWorker(booking.bookingId, 'mock_worker_890');
                            }
                          },
                          icon: const Icon(Icons.assignment_ind),
                          label: const Text('Assign Worker Now'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          ),
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text('Worker Assigned: ${booking.workerId}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1);
              },
            ),
    );
  }
}
