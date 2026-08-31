import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';
import '../../domain/entities/booking.dart';
import '../../../worker/domain/entities/worker.dart';

/// Shown after a booking is confirmed. Polls the booking document and
/// displays worker details once dispatch assigns someone.
class BookingConfirmationPage extends StatelessWidget {
  final Booking booking;
  const BookingConfirmationPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: sl<FirebaseFirestore>()
            .collection('bookings')
            .doc(booking.id)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _SearchingView();
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const _SearchingView();
          }

          final data = snap.data!.data()!;
          final status = data['status'] as String? ?? 'pending';
          final workerId = data['workerId'] as String?;

          if (workerId != null &&
              (status == 'workerAssigned' ||
                  status == 'workerEnRoute' ||
                  status == 'inProgress')) {
            return _WorkerAssignedView(
              booking: booking,
              workerId: workerId,
              status: status,
            );
          }

          if (status == 'no_workers_available') {
            return _NoWorkerView(booking: booking);
          }

          return _SearchingView(bookingId: booking.id);
        },
      ),
    );
  }
}

// ── Searching state ────────────────────────────────────────────────────────────

class _SearchingView extends StatelessWidget {
  final String? bookingId;
  const _SearchingView({this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Finding your worker…',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re matching you with the nearest available worker. This usually takes under 30 seconds.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (bookingId != null) ...[
            const SizedBox(height: 16),
            Text(
              'Booking ID: ${bookingId!.substring(0, 8)}…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => context.go('/customer/home'),
            child: const Text('Track from Home'),
          ),
        ],
      ),
    );
  }
}

// ── Worker assigned ───────────────────────────────────────────────────────────

class _WorkerAssignedView extends StatelessWidget {
  final Booking booking;
  final String workerId;
  final String status;
  const _WorkerAssignedView({
    required this.booking,
    required this.workerId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: sl<FirebaseFirestore>().collection('workers').doc(workerId).get(),
      builder: (ctx, snap) {
        final workerData = snap.data?.data();
        final workerName = workerData?['fullName'] as String? ?? 'Your Worker';
        final workerPhone = workerData?['mobileNumber'] as String? ?? '';
        final rating = (workerData?['rating'] as num?)?.toDouble() ?? 4.0;
        final totalJobs = workerData?['totalJobs'] as int? ?? 0;
        final tier = workerData?['verificationTier'] as String? ?? 'green';
        final photoUrl = workerData?['profilePhotoUrl'] as String?;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                'Worker Found!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Worker card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      child: photoUrl == null
                          ? Text(
                              workerName.isNotEmpty
                                  ? workerName[0].toUpperCase()
                                  : 'W',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          workerName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        _TierBadge(tier: tier),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.work_outline,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$totalJobs jobs',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _StatusRow(status: status),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Booking summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      Icons.home_repair_service,
                      'Service',
                      booking.serviceType.name,
                    ),
                    _SummaryRow(
                      Icons.calendar_today,
                      'Date',
                      _fmtDate(booking.scheduledDate),
                    ),
                    _SummaryRow(
                      Icons.access_time,
                      'Time',
                      booking.scheduledTime ?? '–',
                    ),
                    _SummaryRow(
                      Icons.attach_money,
                      'Estimated',
                      'LKR ${booking.estimatedPrice.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Track Live'),
                      onPressed: () =>
                          context.push('/customer/track/${booking.id}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('Chat'),
                      onPressed: () => context.push('/chat/${booking.id}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/customer/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  Color get _color {
    switch (tier) {
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
    if (tier == 'green') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tier.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _color,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  const _StatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      'workerAssigned' => (
        Icons.directions_run,
        'Worker on the way',
        Colors.orange,
      ),
      'workerEnRoute' => (
        Icons.directions_run,
        'En route to you',
        Colors.orange,
      ),
      'workerArrived' => (
        Icons.location_on,
        'Worker has arrived',
        AppTheme.primaryColor,
      ),
      'inProgress' => (
        Icons.play_circle_outline,
        'Service in progress',
        AppTheme.successColor,
      ),
      _ => (Icons.hourglass_empty, 'Preparing…', Colors.grey),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _SummaryRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── No worker available ───────────────────────────────────────────────────────

class _NoWorkerView extends StatelessWidget {
  final Booking booking;
  const _NoWorkerView({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off_outlined, size: 72, color: Colors.orange),
          const SizedBox(height: 20),
          Text(
            'No Workers Available',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'No available workers were found for your zone right now. We\'ll retry automatically, or you can reschedule.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => context.go('/customer/home'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}
