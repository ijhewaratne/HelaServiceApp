import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';
import '../../../booking/domain/entities/booking.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Customer Home Screen — wallet balance (10.2), emergency button (9.5),
// active bookings stream, quick-book card
// ──────────────────────────────────────────────────────────────────────────────

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  // ── SOS / Emergency ───────────────────────────────────────────────────────

  void _showEmergency() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EmergencySheet(uid: _uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _HomeHeader(
                uid: _uid,
                onEmergency: _showEmergency,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.book_online_outlined,
                    color: Colors.white),
                onPressed: () => context.push('/customer/bookings'),
                tooltip: 'My Bookings',
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined,
                    color: Colors.white),
                onPressed: () => context.push('/customer/profile'),
                tooltip: 'Profile',
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Book a service card ───────────────────────────────────
                _BookServiceCard(),
                const SizedBox(height: 20),

                // ── Active bookings ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Bookings',
                        style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () => context.push('/customer/bookings'),
                      child: const Text('See all',
                          style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ActiveBookingsList(uid: _uid),
              ]),
            ),
          ),
        ],
      ),
      // Always-visible emergency FAB
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showEmergency,
        backgroundColor: AppTheme.errorColor,
        tooltip: 'Emergency',
        child: const Icon(Icons.emergency, size: 20),
      ),
    );
  }
}

// ── Header with wallet balance ────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String? uid;
  final VoidCallback onEmergency;

  const _HomeHeader({required this.uid, required this.onEmergency});

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(_greeting(),
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Text('Need a hand today?',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          // Wallet balance row
          if (uid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: sl<FirebaseFirestore>()
                  .collection('wallets')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final balance =
                    (data?['balance'] as num?)?.toDouble() ?? 0.0;
                final held =
                    (data?['heldBalance'] as num?)?.toDouble() ?? 0.0;
                final available = balance - held;
                return GestureDetector(
                  onTap: () => context.push('/wallet/topup'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LKR ${available.toStringAsFixed(0)} available',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            if (held > 0)
                              Text(
                                'LKR ${held.toStringAsFixed(0)} held in escrow',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 10),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.add_circle_outline,
                            color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Book Service card ─────────────────────────────────────────────────────────

class _BookServiceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.home_repair_service,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book a Service',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('Cleaning, babysitting, elderly care & more',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/customer/book'),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10)),
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }
}

// ── Active bookings list ──────────────────────────────────────────────────────

class _ActiveBookingsList extends StatelessWidget {
  final String? uid;
  const _ActiveBookingsList({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Center(child: Text('Sign in to see bookings'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: sl<FirebaseFirestore>()
          .collection('bookings')
          .where('customerId', isEqualTo: uid)
          .where('status', whereIn: [
            'pending',
            'confirmed',
            'workerAssigned',
            'workerEnRoute',
            'workerArrived',
            'inProgress',
          ])
          .orderBy('scheduledDate', descending: false)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.event_busy,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('No active bookings',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text('Book a service to get started.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final booking = Booking.fromJson(data, id: doc.id);
            return _BookingCard(booking: booking);
          }).toList(),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_repair_service,
                color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceCatalogId ?? booking.serviceType.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  booking.formattedScheduledTime,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel(booking.status),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () =>
                    context.push('/customer/track/${booking.id}'),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('Track', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:
      case BookingStatus.workerAssigned:
        return AppTheme.infoColor;
      case BookingStatus.workerEnRoute:
        return AppTheme.warningColor;
      case BookingStatus.workerArrived:
      case BookingStatus.inProgress:
        return AppTheme.successColor;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:      return 'Confirmed';
      case BookingStatus.workerAssigned: return 'Assigned';
      case BookingStatus.workerEnRoute:  return 'En Route';
      case BookingStatus.workerArrived:  return 'Arrived';
      case BookingStatus.inProgress:     return 'In Progress';
      default:                           return 'Pending';
    }
  }
}

// ── Emergency Bottom Sheet (9.5) ─────────────────────────────────────────────

class _EmergencySheet extends StatelessWidget {
  final String? uid;
  const _EmergencySheet({required this.uid});

  static const _supportNumber = '+94765000000'; // HelaService hotline
  static const _policeNumber  = '119';
  static const _ambulanceNumber = '1990';

  Future<void> _call(BuildContext context, String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot call $number')));
      }
    }
  }

  Future<void> _reportToHelaService(BuildContext context) async {
    if (uid == null) return;
    await sl<FirebaseFirestore>().collection('safety_alerts').add({
      'customerId': uid,
      'workerId': '',
      'bookingId': '',
      'type': 'customerReport',
      'severity': 'critical',
      'message': 'Customer triggered the emergency support button.',
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert sent to HelaService support team.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emergency,
                      color: AppTheme.errorColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Emergency',
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Only use for genuine emergencies. Help is available 24/7.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),

            // HelaService report
            _EmergencyAction(
              icon: Icons.support_agent,
              title: 'Alert HelaService Support',
              subtitle: 'Notifies our safety team immediately',
              color: AppTheme.errorColor,
              onTap: () => _reportToHelaService(context),
            ),
            const SizedBox(height: 10),

            // Direct calls
            _EmergencyAction(
              icon: Icons.phone,
              title: 'Call HelaService Hotline',
              subtitle: _supportNumber,
              color: AppTheme.warningColor,
              onTap: () => _call(context, _supportNumber),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _EmergencyAction(
                    icon: Icons.local_police,
                    title: 'Police',
                    subtitle: _policeNumber,
                    color: AppTheme.infoColor,
                    onTap: () => _call(context, _policeNumber),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _EmergencyAction(
                    icon: Icons.local_hospital,
                    title: 'Ambulance',
                    subtitle: _ambulanceNumber,
                    color: AppTheme.successColor,
                    onTap: () => _call(context, _ambulanceNumber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          )),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
