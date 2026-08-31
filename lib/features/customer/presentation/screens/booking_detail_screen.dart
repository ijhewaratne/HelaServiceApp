import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../../booking/domain/entities/booking.dart';

class BookingDetailScreen extends StatelessWidget {
  final String bookingId;
  final Booking? initialBooking;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  @override
  Widget build(BuildContext context) {
    if (initialBooking != null) {
      return _BookingDetailBody(booking: initialBooking!);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Booking not found'));
          }
          return _BookingDetailBody(booking: Booking.fromFirestore(snap.data!));
        },
      ),
    );
  }
}

class _BookingDetailBody extends StatelessWidget {
  final Booking booking;
  const _BookingDetailBody({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusCard(booking: booking),
            const SizedBox(height: 20),
            _DetailsCard(booking: booking),
            const SizedBox(height: 20),
            _StatusTimeline(booking: booking),
            const SizedBox(height: 24),
            _ActionButtons(booking: booking),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Booking booking;
  const _StatusCard({required this.booking});

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.disputed:
        return Colors.orange;
      case BookingStatus.inProgress:
      case BookingStatus.workerArrived:
        return Colors.blue;
      default:
        return const Color(0xFF1B5E20);
    }
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.draft:
        return 'Draft';
      case BookingStatus.pending:
        return 'Pending Confirmation';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.workerAssigned:
        return 'Provider Assigned';
      case BookingStatus.workerEnRoute:
        return 'Provider En Route';
      case BookingStatus.workerArrived:
        return 'Provider Arrived';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.disputed:
        return 'Under Review';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(_statusIcon(booking.status), color: color, size: 40),
          const SizedBox(height: 8),
          Text(
            _statusLabel(booking.status),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Booking #${booking.id.substring(0, 8).toUpperCase()}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(BookingStatus s) {
    switch (s) {
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.disputed:
        return Icons.report_problem;
      case BookingStatus.inProgress:
        return Icons.play_circle;
      case BookingStatus.workerEnRoute:
        return Icons.directions_car;
      case BookingStatus.workerArrived:
        return Icons.home;
      default:
        return Icons.schedule;
    }
  }
}

class _DetailsCard extends StatelessWidget {
  final Booking booking;
  const _DetailsCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final serviceLabel = booking.serviceType.name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
        .trim();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _DetailRow(
              Icons.home_repair_service,
              'Service',
              serviceLabel[0].toUpperCase() + serviceLabel.substring(1),
            ),
            _DetailRow(
              Icons.calendar_today,
              'Scheduled',
              booking.formattedScheduledTime,
            ),
            _DetailRow(
              Icons.location_on,
              'Location',
              booking.address.fullAddress,
            ),
            _DetailRow(
              Icons.payments,
              'Estimated Price',
              booking.formattedPrice,
            ),
            if (booking.finalPrice != null)
              _DetailRow(
                Icons.receipt,
                'Final Price',
                'LKR ${booking.finalPrice!.toStringAsFixed(2)}',
              ),
            if (booking.notes != null && booking.notes!.isNotEmpty)
              _DetailRow(Icons.notes, 'Notes', booking.notes!),
            if (booking.cancellationReason != null)
              _DetailRow(
                Icons.info_outline,
                'Cancellation Reason',
                booking.cancellationReason!,
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final Booking booking;
  const _StatusTimeline({required this.booking});

  @override
  Widget build(BuildContext context) {
    final events = <_TimelineEvent>[];

    events.add(
      _TimelineEvent(
        label: 'Booking Created',
        time: booking.createdAt,
        done: true,
      ),
    );
    if (booking.status.index >= BookingStatus.confirmed.index &&
        booking.status != BookingStatus.cancelled) {
      events.add(
        _TimelineEvent(label: 'Booking Confirmed', time: null, done: true),
      );
    }
    if (booking.checkIn != null) {
      events.add(
        _TimelineEvent(
          label: 'Provider Checked In',
          time: booking.checkIn!.timestamp,
          done: true,
        ),
      );
    }
    if (booking.checkOut != null) {
      events.add(
        _TimelineEvent(
          label: 'Service Completed',
          time: booking.checkOut!.timestamp,
          done: true,
        ),
      );
    } else if (booking.completedAt != null) {
      events.add(
        _TimelineEvent(
          label: 'Service Completed',
          time: booking.completedAt,
          done: true,
        ),
      );
    }
    if (booking.cancelledAt != null) {
      events.add(
        _TimelineEvent(
          label: 'Booking Cancelled',
          time: booking.cancelledAt,
          done: true,
          isError: true,
        ),
      );
    }

    if (events.length <= 1) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...events.asMap().entries.map(
              (e) => _TimelineTile(
                event: e.value,
                isLast: e.key == events.length - 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEvent {
  final String label;
  final DateTime? time;
  final bool done;
  final bool isError;
  _TimelineEvent({
    required this.label,
    required this.time,
    required this.done,
    this.isError = false,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;
  const _TimelineTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = event.isError ? Colors.red : const Color(0xFF1B5E20);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: event.done ? color : Colors.grey[300],
              child: Icon(
                event.done ? Icons.check : Icons.circle,
                size: 12,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: color.withOpacity(0.3)),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (event.time != null)
                Text(
                  '${event.time!.day}/${event.time!.month}/${event.time!.year} ${event.time!.hour.toString().padLeft(2, '0')}:${event.time!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatefulWidget {
  final Booking booking;
  const _ActionButtons({required this.booking});

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _loading = false;

  Future<void> _cancelBooking(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
            'cancellationReason': 'Cancelled by customer',
          });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
        context.go('/customer/bookings');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        if (b.status == BookingStatus.completed) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/customer/review/${b.id}', extra: b),
              icon: const Icon(Icons.star),
              label: const Text('Leave a Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (b.canCancel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelBooking(context),
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text(
                'Cancel Booking',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (b.isActive && !b.canCancel && b.status != BookingStatus.disputed)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go(
                '/incident/report',
                extra: {
                  'reporterId': b.customerId,
                  'reporterType': 'customer',
                  'jobId': b.id,
                },
              ),
              icon: const Icon(Icons.report_problem, color: Colors.orange),
              label: const Text(
                'Raise a Dispute',
                style: TextStyle(color: Colors.orange),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
