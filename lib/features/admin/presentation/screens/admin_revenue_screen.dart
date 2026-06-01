import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';

/// Admin revenue drill-down: daily/weekly totals, top services, payout summary.
class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final Future<_RevenueData> _future;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _future = _loadRevenue();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<_RevenueData> _loadRevenue() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    final db = sl<FirebaseFirestore>();

    // Completed bookings today
    final todaySnap = await db
        .collection('bookings')
        .where('status', isEqualTo: 'completed')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .get();

    // Completed bookings this week
    final weekSnap = await db
        .collection('bookings')
        .where('status', isEqualTo: 'completed')
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .get();

    double todayRevenue = 0;
    double weekRevenue = 0;
    final serviceBreakdown = <String, double>{};
    final dailyRevenue = <String, double>{};

    for (final doc in weekSnap.docs) {
      final d = doc.data();
      final price = (d['estimatedPrice'] as num?)?.toDouble() ?? 0;
      final service = d['serviceType'] as String? ?? 'other';
      final completedAt = (d['completedAt'] as Timestamp?)?.toDate();
      if (completedAt == null) continue;

      weekRevenue += price;
      serviceBreakdown[service] = (serviceBreakdown[service] ?? 0) + price;

      final dayKey =
          '${completedAt.month.toString().padLeft(2,'0')}/${completedAt.day.toString().padLeft(2,'0')}';
      dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + price;

      if (completedAt.isAfter(todayStart)) todayRevenue += price;
    }

    // Pending payouts
    final payoutsSnap = await db
        .collection('payouts')
        .where('status', isEqualTo: 'pending')
        .get();
    final pendingPayouts = payoutsSnap.docs.fold<double>(
        0, (s, d) => s + ((d.data()['amount'] as num?)?.toDouble() ?? 0));

    return _RevenueData(
      todayRevenue: todayRevenue,
      weekRevenue: weekRevenue,
      todayBookings: todaySnap.size,
      weekBookings: weekSnap.size,
      serviceBreakdown: serviceBreakdown,
      dailyRevenue: dailyRevenue,
      pendingPayouts: pendingPayouts,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Reports'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'By Service'),
          ],
        ),
      ),
      body: FutureBuilder<_RevenueData>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final data = snap.data!;
          return TabBarView(
            controller: _tabs,
            children: [
              _OverviewTab(data: data),
              _ServiceTab(data: data),
            ],
          );
        },
      ),
    );
  }
}

class _RevenueData {
  final double todayRevenue;
  final double weekRevenue;
  final int todayBookings;
  final int weekBookings;
  final Map<String, double> serviceBreakdown;
  final Map<String, double> dailyRevenue;
  final double pendingPayouts;

  const _RevenueData({
    required this.todayRevenue,
    required this.weekRevenue,
    required this.todayBookings,
    required this.weekBookings,
    required this.serviceBreakdown,
    required this.dailyRevenue,
    required this.pendingPayouts,
  });

  double get platformRevenue => weekRevenue * 0.20;
  double get workerEarnings => weekRevenue * 0.80;
}

class _OverviewTab extends StatelessWidget {
  final _RevenueData data;
  const _OverviewTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('This week', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MetricCard(
            label: 'Total Revenue',
            value: 'LKR ${_fmt(data.weekRevenue)}',
            icon: Icons.monetization_on_outlined,
            color: AppTheme.primaryColor,
          )),
          const SizedBox(width: 12),
          Expanded(child: _MetricCard(
            label: 'Bookings',
            value: '${data.weekBookings}',
            icon: Icons.receipt_long_outlined,
            color: AppTheme.successColor,
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MetricCard(
            label: 'Platform (20%)',
            value: 'LKR ${_fmt(data.platformRevenue)}',
            icon: Icons.account_balance_outlined,
            color: AppTheme.warningColor,
          )),
          const SizedBox(width: 12),
          Expanded(child: _MetricCard(
            label: 'Worker Pay (80%)',
            value: 'LKR ${_fmt(data.workerEarnings)}',
            icon: Icons.people_outlined,
            color: Colors.teal,
          )),
        ]),
        const SizedBox(height: 20),
        Text('Today', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _MetricCard(
            label: 'Revenue',
            value: 'LKR ${_fmt(data.todayRevenue)}',
            icon: Icons.today_outlined,
            color: AppTheme.primaryColor,
          )),
          const SizedBox(width: 12),
          Expanded(child: _MetricCard(
            label: 'Completed',
            value: '${data.todayBookings} bookings',
            icon: Icons.check_circle_outline,
            color: AppTheme.successColor,
          )),
        ]),
        const SizedBox(height: 20),
        Text('Payouts', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _MetricCard(
          label: 'Pending Payout to Workers',
          value: 'LKR ${_fmt(data.pendingPayouts)}',
          icon: Icons.payments_outlined,
          color: Colors.orange,
          wide: true,
        ),
        const SizedBox(height: 20),
        if (data.dailyRevenue.isNotEmpty) ...[
          Text('Daily breakdown (this week)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...data.dailyRevenue.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(width: 60,
                  child: Text(e.key, style: Theme.of(context).textTheme.bodySmall)),
              Expanded(child: LinearProgressIndicator(
                value: data.weekRevenue > 0 ? e.value / data.weekRevenue : 0,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
              )),
              const SizedBox(width: 10),
              Text('LKR ${_fmt(e.value)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600)),
            ]),
          )),
        ],
      ]),
    );
  }

  static String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);
}

class _ServiceTab extends StatelessWidget {
  final _RevenueData data;
  const _ServiceTab({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.serviceBreakdown.isEmpty) {
      return Center(
          child: Text('No completed bookings this week.',
              style: TextStyle(color: Colors.grey.shade600)));
    }
    final sorted = data.serviceBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = data.serviceBreakdown.values.fold(0.0, (s, v) => s + v);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (ctx, i) {
        final e = sorted[i];
        final pct = total > 0 ? (e.value / total * 100) : 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(ctx).colorScheme.outline),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_serviceName(e.key),
                  style: Theme.of(ctx).textTheme.titleSmall),
              Text('LKR ${(e.value / 1000).toStringAsFixed(1)}k',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                minHeight: 6,
              )),
              const SizedBox(width: 8),
              Text('${pct.toStringAsFixed(0)}%',
                  style: Theme.of(ctx).textTheme.bodySmall),
            ]),
          ]),
        );
      },
    );
  }

  static String _serviceName(String key) {
    switch (key) {
      case 'cleaning': return 'Home Cleaning';
      case 'babysitting': return 'Babysitting';
      case 'elderlyCare': return 'Elderly Care';
      case 'cooking': return 'Cooking Help';
      case 'laundry': return 'Laundry & Ironing';
      default: return key[0].toUpperCase() + key.substring(1);
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool wide;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color, fontWeight: FontWeight.bold)),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
      ]),
    );
  }
}
