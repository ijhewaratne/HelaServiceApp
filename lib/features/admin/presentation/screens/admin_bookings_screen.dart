import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../../../../shared/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/branded_widgets.dart';
import '../../../../injection_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      context.read<AdminBloc>().add(const FetchDashboardData());
    });
  }

  Future<void> _showWorkerPicker(
    BuildContext context,
    String bookingId,
    String serviceType,
  ) async {
    final snap = await sl<FirebaseFirestore>()
        .collection('workers')
        .where('isOnline', isEqualTo: true)
        .where('verificationStatus', isEqualTo: 'approved')
        .limit(20)
        .get();

    if (!mounted) return;

    final workers = snap.docs.map((d) {
      final data = d.data();
      return _WorkerOption(
        uid: d.id,
        name: data['fullName'] as String? ?? 'Worker',
        phone: data['mobileNumber'] as String? ?? '',
        tier: data['verificationTier'] as String? ?? 'green',
      );
    }).toList();

    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No online verified workers available.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<_WorkerOption>(
      context: context,
      builder: (ctx) => _WorkerPickerSheet(workers: workers),
    );

    if (selected != null && mounted) {
      context.read<AdminBloc>().add(
        ManuallyAssignWorker(bookingId, selected.uid),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminBloc>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Dispatch Board')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.activeBookings.isEmpty
          ? Center(
              child: Text(
                'No active bookings',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
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
                              Text(
                                booking.serviceType.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: booking.status == 'draft'
                                      ? Colors.red.shade100
                                      : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  booking.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: booking.status == 'draft'
                                        ? Colors.red.shade900
                                        : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${booking.bookingDate} at ${booking.startTime} (${booking.durationHours}h)',
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  booking.addressText,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 30),
                          if (booking.workerId == null)
                            OutlinedButton.icon(
                              onPressed: () => _showWorkerPicker(
                                context,
                                booking.bookingId,
                                booking.serviceType,
                              ),
                              icon: const Icon(Icons.assignment_ind),
                              label: const Text('Assign Worker'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          else
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Worker Assigned: ${booking.workerId}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 100 * index))
                    .slideY(begin: 0.1);
              },
            ),
    );
  }
}

class _WorkerOption {
  final String uid;
  final String name;
  final String phone;
  final String tier;
  const _WorkerOption({
    required this.uid,
    required this.name,
    required this.phone,
    required this.tier,
  });
}

class _WorkerPickerSheet extends StatelessWidget {
  final List<_WorkerOption> workers;
  const _WorkerPickerSheet({required this.workers});

  Color _tierColor(String t) {
    switch (t) {
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'partner':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'Select Worker',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${workers.length} online',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: workers.length,
              itemBuilder: (ctx, i) {
                final w = workers[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _tierColor(w.tier).withValues(alpha: 0.12),
                    child: Text(
                      w.name.isNotEmpty ? w.name[0].toUpperCase() : 'W',
                      style: TextStyle(
                        color: _tierColor(w.tier),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(w.name),
                  subtitle: Text(w.phone),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _tierColor(w.tier).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      w.tier.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _tierColor(w.tier),
                      ),
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, w),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
