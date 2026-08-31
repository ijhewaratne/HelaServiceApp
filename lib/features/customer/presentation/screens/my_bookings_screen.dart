import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../booking/domain/entities/booking.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BookingList(
            customerId: uid,
            statuses: const [
              'pending',
              'confirmed',
              'workerAssigned',
              'workerEnRoute',
              'workerArrived',
              'inProgress',
              'disputed',
            ],
          ),
          _BookingList(customerId: uid, statuses: const ['completed']),
          _BookingList(customerId: uid, statuses: const ['cancelled']),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final String customerId;
  final List<String> statuses;

  const _BookingList({required this.customerId, required this.statuses});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: customerId)
          .where('status', whereIn: statuses)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No bookings here',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }
        final bookings = snap.data!.docs
            .map((d) => Booking.fromFirestore(d))
            .toList();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _BookingTile(booking: bookings[i]),
        );
      },
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  const _BookingTile({required this.booking});

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
        return 'Pending';
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
        return 'Disputed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.go('/customer/bookings/${booking.id}', extra: booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceType.name
                          .replaceAllMapped(
                            RegExp(r'([A-Z])'),
                            (m) => ' ${m[0]}',
                          )
                          .trim()
                          .replaceFirst(
                            booking.serviceType.name[0],
                            booking.serviceType.name[0].toUpperCase(),
                          ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(booking.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _statusColor(booking.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _statusLabel(booking.status),
                      style: TextStyle(
                        color: _statusColor(booking.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    booking.formattedScheduledTime,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.address.fullAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                  Text(
                    booking.formattedPrice,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
