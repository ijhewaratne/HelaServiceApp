import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';
import '../../../booking/domain/entities/booking.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Worker Dashboard — Today's jobs, Earnings, Calendar tabs + SOS
// ──────────────────────────────────────────────────────────────────────────────

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _isOnline = false;
  String? _workerId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _workerId = FirebaseAuth.instance.currentUser?.uid;
    _loadOnlineStatus();
  }

  Future<void> _loadOnlineStatus() async {
    if (_workerId == null) return;
    final snap = await sl<FirebaseFirestore>().collection('workers').doc(_workerId).get();
    if (snap.exists && mounted) {
      setState(() => _isOnline = snap.data()?['isOnline'] as bool? ?? false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _toggleOnline(bool val) {
    setState(() => _isOnline = val);
    if (_workerId == null) return;
    sl<FirebaseFirestore>().collection('workers').doc(_workerId).update({
      'isOnline': val,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void _showSOS() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
            'This will alert the HelaService safety team immediately. '
            'Only use if you are in genuine danger.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(context);
              if (_workerId != null) {
                await sl<FirebaseFirestore>().collection('safety_alerts').add({
                  'workerId': _workerId,
                  'customerId': '',
                  'bookingId': '',
                  'type': 'sosPanic',
                  'severity': 'critical',
                  'message': 'Worker triggered the SOS button from the dashboard.',
                  'status': 'open',
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('SOS alert sent. Help is on the way.'),
                    backgroundColor: AppTheme.errorColor));
              }
            },
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, scrolled) => [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            forceElevated: scrolled,
            flexibleSpace: FlexibleSpaceBar(
              background: _Header(
                  isOnline: _isOnline, onToggle: _toggleOnline),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.star_outline, color: Colors.white),
                tooltip: 'My Reviews',
                onPressed: () => context.push('/worker/reviews'),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) async {
                  switch (v) {
                    case 'profile':
                      context.push('/worker/profile/edit');
                      break;
                    case 'payouts':
                      context.push('/worker/payouts');
                      break;
                    case 'bank':
                      context.push('/worker/bank-account');
                      break;
                    case 'support':
                      context.push('/support');
                      break;
                    case 'sessions':
                      context.push('/account/sessions');
                      break;
                    case 'logout':
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) context.go('/auth');
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'profile', child: Text('Edit Profile')),
                  PopupMenuItem(value: 'payouts', child: Text('Payout History')),
                  PopupMenuItem(value: 'bank', child: Text('Bank Account')),
                  PopupMenuItem(value: 'support', child: Text('Support')),
                  PopupMenuItem(
                      value: 'sessions', child: Text('Active Sessions')),
                  PopupMenuItem(value: 'logout', child: Text('Sign Out')),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: "Today's Jobs"),
                Tab(text: 'Earnings'),
                Tab(text: 'Calendar'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _TodaysJobsTab(workerId: _workerId),
            _EarningsTab(workerId: _workerId),
            _CalendarTab(workerId: _workerId),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSOS,
        backgroundColor: AppTheme.errorColor,
        icon: const Icon(Icons.sos),
        label: const Text('SOS'),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isOnline;
  final void Function(bool) onToggle;
  const _Header({required this.isOnline, required this.onToggle});

  static String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Good ${_greet()},',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Text('Worker Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ])),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                  color: isOnline ? Colors.greenAccent : Colors.white60,
                  fontSize: 11, fontWeight: FontWeight.w600)),
          Switch(
            value: isOnline, onChanged: onToggle,
            activeThumbColor: Colors.greenAccent,
          ),
        ]),
      ]),
    );
  }
}

// ── Tab 1: Today's Jobs ───────────────────────────────────────────────────────

class _TodaysJobsTab extends StatelessWidget {
  final String? workerId;
  const _TodaysJobsTab({required this.workerId});

  @override
  Widget build(BuildContext context) {
    if (workerId == null) return const Center(child: Text('Not signed in'));
    final today = DateTime.now();
    final startTs = Timestamp.fromDate(DateTime(today.year, today.month, today.day));
    final endTs   = Timestamp.fromDate(DateTime(today.year, today.month, today.day, 23, 59, 59));

    return StreamBuilder<QuerySnapshot>(
      stream: sl<FirebaseFirestore>()
          .collection('bookings')
          .where('workerId', isEqualTo: workerId)
          .where('scheduledDate', isGreaterThanOrEqualTo: startTs)
          .where('scheduledDate', isLessThanOrEqualTo: endTs)
          .orderBy('scheduledDate')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.event_available, size: 64,
                color: Theme.of(ctx).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No jobs today', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Go online to receive bookings.',
                style: Theme.of(ctx).textTheme.bodySmall),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final booking = Booking.fromJson(data, id: docs[i].id);
            return _JobCard(booking: booking);
          },
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  final Booking booking;
  const _JobCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sc = _statusColour(booking.status);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sc.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(_statusLabel(booking.status),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc)),
            const Spacer(),
            Text(booking.schedule?.displayLabel ?? booking.formattedScheduledTime,
                style: theme.textTheme.bodySmall),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.home_repair_service,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.serviceCatalogId ?? booking.serviceType.name,
                    style: theme.textTheme.titleSmall),
                Text(booking.address.fullAddress,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
              Text('LKR ${((booking.finalPrice ?? booking.estimatedPrice) * 0.8).toStringAsFixed(0)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.successColor, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            _ActionButton(booking: booking),
          ]),
        ),
      ]),
    );
  }

  static Color _statusColour(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:
      case BookingStatus.workerAssigned: return AppTheme.infoColor;
      case BookingStatus.workerEnRoute:  return AppTheme.warningColor;
      case BookingStatus.workerArrived:
      case BookingStatus.inProgress:     return AppTheme.successColor;
      default:                           return const Color(0xFF64748B);
    }
  }

  static String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:      return 'Confirmed';
      case BookingStatus.workerAssigned: return 'Assigned';
      case BookingStatus.workerEnRoute:  return 'En Route';
      case BookingStatus.workerArrived:  return 'Arrived';
      case BookingStatus.inProgress:     return 'In Progress';
      case BookingStatus.completed:      return 'Completed';
      default:                           return 'Pending';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final Booking booking;
  const _ActionButton({required this.booking});

  @override
  Widget build(BuildContext context) {
    switch (booking.status) {
      case BookingStatus.workerAssigned:
      case BookingStatus.confirmed:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.navigation, size: 16),
            label: const Text('Navigate to Customer'),
            onPressed: () => context.push('/worker/active-job/${booking.id}'),
          ),
        );
      case BookingStatus.workerArrived:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('Check In'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            onPressed: () => context.push('/worker/active-job/${booking.id}'),
          ),
        );
      case BookingStatus.inProgress:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('Complete Job'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            onPressed: () => context.push('/worker/active-job/${booking.id}'),
          ),
        );
      default:
        return const SizedBox();
    }
  }
}

// ── Tab 2: Earnings ───────────────────────────────────────────────────────────

class _EarningsTab extends StatelessWidget {
  final String? workerId;
  const _EarningsTab({required this.workerId});

  @override
  Widget build(BuildContext context) {
    if (workerId == null) return const Center(child: Text('Not signed in'));
    final weekAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7)));

    return FutureBuilder<QuerySnapshot>(
      future: sl<FirebaseFirestore>()
          .collection('bookings')
          .where('workerId', isEqualTo: workerId)
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThanOrEqualTo: weekAgo)
          .get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        double gross = 0;
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          gross += (data['finalPrice'] as num?)?.toDouble() ??
              (data['estimatedPrice'] as num?)?.toDouble() ?? 0;
        }
        final earnings = gross * 0.8;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _MetricCard(
                  label: 'This week', value: 'LKR ${earnings.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined, color: AppTheme.successColor)),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(
                  label: 'Jobs done', value: docs.length.toString(),
                  icon: Icons.check_circle_outline, color: AppTheme.infoColor)),
            ]),
            const SizedBox(height: 24),
            Text('Recent completed jobs', style: Theme.of(ctx).textTheme.titleSmall),
            const SizedBox(height: 10),
            if (docs.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No completed jobs this week.',
                    style: Theme.of(ctx).textTheme.bodySmall),
              ))
            else
              ...docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final booking = Booking.fromJson(data, id: d.id);
                final w = (booking.finalPrice ?? booking.estimatedPrice) * 0.8;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).cardTheme.color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(ctx).colorScheme.outline),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(booking.serviceCatalogId ?? booking.serviceType.name,
                          style: Theme.of(ctx).textTheme.titleSmall),
                      Text(booking.address.city, style: Theme.of(ctx).textTheme.bodySmall),
                    ])),
                    Text('+LKR ${w.toStringAsFixed(0)}',
                        style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                  ]),
                );
              }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: AppTheme.infoColor, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                    'Payouts every Monday at 09:00. Minimum payout: LKR 1,000.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppTheme.infoColor))),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.account_balance, size: 16),
                label: const Text('Setup Bank Account for Payouts'),
                onPressed: () => context.push('/worker/bank-account'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.workspace_premium, size: 16),
                label: const Text('Gold Tier Training'),
                onPressed: () => context.push('/worker/training'),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ]),
    );
  }
}

// ── Tab 3: Calendar ───────────────────────────────────────────────────────────

class _CalendarTab extends StatefulWidget {
  final String? workerId;
  const _CalendarTab({required this.workerId});

  @override
  State<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<_CalendarTab> {
  static const _days = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
  static const _labels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  final Map<String, List<_Slot>> _schedule = {};
  final Set<DateTime> _exceptions = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final d in _days) {
      _schedule[d] = [];
    }
    _load();
  }

  Future<void> _load() async {
    final wid = widget.workerId;
    if (wid == null) return;
    final doc = await sl<FirebaseFirestore>()
        .collection('workers').doc(wid).collection('calendar').doc('availability').get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    final recurring = data['recurring'] as Map<String, dynamic>? ?? {};
    setState(() {
      for (final d in _days) {
        if (recurring.containsKey(d)) {
          final slots = (recurring[d]['slots'] as List?)
              ?.map((s) => _Slot(
                  start: (s as Map)['start'] as String? ?? '08:00',
                  end: s['end'] as String? ?? '17:00'))
              .toList() ?? [];
          _schedule[d] = slots;
        }
      }
      final exc = data['exceptions'] as Map<String, dynamic>? ?? {};
      for (final k in exc.keys) {
        final p = k.split('-');
        if (p.length == 3) {
          _exceptions.add(DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2])));
        }
      }
    });
  }

  Future<void> _save() async {
    final wid = widget.workerId;
    if (wid == null) return;
    setState(() => _saving = true);
    final recurring = <String, dynamic>{};
    for (final d in _days) {
      final slots = _schedule[d] ?? [];
      if (slots.isNotEmpty) {
        recurring[d] = {
          'day': d,
          'slots': slots.map((s) => {'start': s.start, 'end': s.end}).toList(),
        };
      }
    }
    String dateKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final exceptions = {for (final d in _exceptions) dateKey(d): 'unavailable'};
    await sl<FirebaseFirestore>()
        .collection('workers').doc(wid).collection('calendar').doc('availability')
        .set({'workerId': wid, 'recurring': recurring, 'exceptions': exceptions,
              'updatedAt': FieldValue.serverTimestamp()});
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Calendar saved.'), backgroundColor: AppTheme.successColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Weekly availability', style: Theme.of(context).textTheme.titleMedium),
          _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save'),
                ),
        ]),
        const SizedBox(height: 12),
        ...List.generate(_days.length, (i) {
          final d = _days[i];
          final slots = _schedule[d] ?? [];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(children: [
              Row(children: [
                SizedBox(width: 36,
                    child: Text(_labels[i], style: Theme.of(context).textTheme.titleSmall)),
                if (slots.isEmpty)
                  Text('Off', style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline)),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _schedule[d]!.add(_Slot(start: '08:00', end: '17:00'))),
                  child: const Icon(Icons.add_circle_outline,
                      size: 20, color: AppTheme.primaryColor),
                ),
              ]),
              ...List.generate(slots.length, (si) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  const SizedBox(width: 44),
                  _TimeChip(
                    value: slots[si].start,
                    onChanged: (t) => setState(() => _schedule[d]![si].start = t),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
                  _TimeChip(
                    value: slots[si].end,
                    onChanged: (t) => setState(() => _schedule[d]![si].end = t),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => setState(() => _schedule[d]!.removeAt(si)),
                    child: const Icon(Icons.remove_circle_outline,
                        size: 18, color: AppTheme.errorColor),
                  ),
                ]),
              )),
            ]),
          );
        }),
        const SizedBox(height: 20),
        Text('Days off', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Tap a date to block it. Tap again to unblock.',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        CalendarDatePicker(
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          onDateChanged: (d) => setState(() {
            final exists = _exceptions.any(
                (e) => e.year == d.year && e.month == d.month && e.day == d.day);
            if (exists) {
              _exceptions.removeWhere(
                  (e) => e.year == d.year && e.month == d.month && e.day == d.day);
            } else {
              _exceptions.add(d);
            }
          }),
        ),
        if (_exceptions.isNotEmpty)
          Wrap(
            spacing: 8, runSpacing: 4,
            children: (_exceptions.toList()..sort())
                .map((d) => Chip(
                      label: Text('${d.day}/${d.month}',
                          style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _exceptions.removeWhere(
                          (e) => e.year == d.year && e.month == d.month && e.day == d.day)),
                      backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                      side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                    ))
                .toList(),
          ),
        const SizedBox(height: 80),
      ]),
    );
  }
}

class _Slot {
  String start, end;
  _Slot({required this.start, required this.end});
}

class _TimeChip extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _TimeChip({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final p = value.split(':');
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
        );
        if (picked != null) {
          onChanged('${picked.hour.toString().padLeft(2, '0')}:'
              '${picked.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Text(value, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
      ),
    );
  }
}
