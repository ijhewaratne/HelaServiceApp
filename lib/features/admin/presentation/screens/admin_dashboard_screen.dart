import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Admin Operations Dashboard — live metrics, verification queue, safety alerts,
// worker performance.
// ──────────────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, scrolled) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            forceElevated: scrolled,
            flexibleSpace: const FlexibleSpaceBar(background: _AdminHeader()),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => context.go('/auth'),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Verification'),
                Tab(text: 'Safety Alerts'),
                Tab(text: 'Performance'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: const [
            _OverviewTab(),
            _VerificationTab(),
            _SafetyAlertsTab(),
            _PerformanceTab(),
          ],
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A3D3D), AppTheme.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 8),
      child: const Row(children: [
        Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
        SizedBox(width: 12),
        Column(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HelaService',
              style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2)),
          Text('Operations Command Center',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

// ── Tab 1: Overview ───────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Live metrics', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _LiveCard(
            label: 'Active Bookings',
            stream: sl<FirebaseFirestore>().collection('bookings')
                .where('status', whereIn: ['confirmed','workerAssigned','workerEnRoute','workerArrived','inProgress'])
                .snapshots().map((s) => s.size.toString()),
            icon: Icons.calendar_today, color: AppTheme.primaryColor,
          )),
          const SizedBox(width: 12),
          Expanded(child: _LiveCard(
            label: 'Pending Verification',
            stream: sl<FirebaseFirestore>().collection('workers')
                .where('verificationStatus', isEqualTo: 'pending_review')
                .snapshots().map((s) => s.size.toString()),
            icon: Icons.pending_actions, color: AppTheme.warningColor,
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _LiveCard(
            label: 'Unresolved Safety Alerts',
            stream: sl<FirebaseFirestore>().collection('safety_alerts')
                .where('status', whereIn: ['open', 'acknowledged', 'escalated'])
                .snapshots().map((s) => s.size.toString()),
            icon: Icons.warning_amber, color: AppTheme.errorColor,
          )),
          const SizedBox(width: 12),
          Expanded(child: _LiveCard(
            label: 'Workers Online',
            stream: sl<FirebaseFirestore>().collection('workers')
                .where('isOnline', isEqualTo: true)
                .snapshots().map((s) => s.size.toString()),
            icon: Icons.people_outline, color: AppTheme.successColor,
          )),
        ]),
        const SizedBox(height: 24),
        Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _ActionTile(icon: Icons.book_online_outlined,
            label: 'Booking Management', subtitle: 'View and reassign active bookings',
            onTap: () => context.push('/admin/bookings')),
        _ActionTile(icon: Icons.workspace_premium_outlined,
            label: 'Worker Approvals', subtitle: 'Green and Blue tier verification queue',
            onTap: () => context.push('/admin/workers')),
        _ActionTile(icon: Icons.bar_chart_outlined,
            label: 'Revenue Reports', subtitle: 'Daily and weekly revenue drill-down',
            onTap: () => context.push('/admin/revenue')),
        _ActionTile(icon: Icons.support_agent_outlined,
            label: 'Support Tickets', subtitle: 'Customer feedback and complaints',
            onTap: () => context.push('/admin/support')),
        _ActionTile(icon: Icons.emergency_outlined,
            label: 'Emergency Dispatch', subtitle: 'Manual worker assignment',
            onTap: () => context.push('/admin/dispatch')),
        _ActionTile(icon: Icons.people_outlined,
            label: 'Customer Management', subtitle: 'View and suspend customer accounts',
            onTap: () => context.push('/admin/customers')),
        _ActionTile(icon: Icons.rate_review_outlined,
            label: 'Review Moderation', subtitle: 'Approve, hide, or flag reviews',
            onTap: () => context.push('/admin/reviews')),
        _ActionTile(icon: Icons.report_problem_outlined,
            label: 'Disputes', subtitle: 'Manage open and under-review disputes',
            onTap: () => context.push('/admin/disputes')),
        _ActionTile(icon: Icons.category_outlined,
            label: 'Service Categories', subtitle: 'Manage service catalog and pricing',
            onTap: () => context.push('/admin/categories')),
        _ActionTile(icon: Icons.history_outlined,
            label: 'Audit Log', subtitle: 'View admin action history',
            onTap: () => context.push('/admin/audit-log')),
        _ActionTile(icon: Icons.manage_accounts_outlined,
            label: 'User Management', subtitle: 'View and manage admin accounts',
            onTap: () => context.push('/admin/users')),
      ]),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final String label;
  final Stream<String> stream;
  final IconData icon;
  final Color color;
  const _LiveCard({required this.label, required this.stream,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (ctx, snap) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(snap.data ?? '…',
              style: Theme.of(ctx).textTheme.displaySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: color)),
        ]),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label,
    required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}

// ── Tab 2: Verification Queue ─────────────────────────────────────────────────

class _VerificationTab extends StatelessWidget {
  const _VerificationTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: sl<FirebaseFirestore>().collection('workers')
          .where('verificationStatus', whereIn: ['pending_review', 'documents_submitted'])
          .orderBy('createdAt')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_outline, size: 64, color: AppTheme.successColor),
            const SizedBox(height: 16),
            Text('No pending verifications', style: Theme.of(ctx).textTheme.titleMedium),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _VerifCard(workerId: docs[i].id, data: data);
          },
        );
      },
    );
  }
}

class _VerifCard extends StatelessWidget {
  final String workerId;
  final Map<String, dynamic> data;
  const _VerifCard({required this.workerId, required this.data});

  Future<void> _approve(BuildContext ctx) async {
    await sl<FirebaseFirestore>().collection('workers').doc(workerId).update({
      'verificationStatus': 'approved',
      'isVerified': true,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Worker approved.'), backgroundColor: AppTheme.successColor));
    }
  }

  Future<void> _reject(BuildContext ctx) async {
    await sl<FirebaseFirestore>().collection('workers').doc(workerId).update({
      'verificationStatus': 'rejected', 'isVerified': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = data['fullName'] as String? ?? data['name'] as String? ?? 'Worker';
    final phone = data['phone'] as String? ?? '-';
    final status = (data['verificationStatus'] as String? ?? 'pending').replaceAll('_', ' ');
    final tier = data['verificationTier'] as String? ?? 'green';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'W',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: Theme.of(context).textTheme.titleSmall),
            Text(phone, style: Theme.of(context).textTheme.bodySmall),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.warningColor)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _Badge(label: 'NIC', done: data['nicVerified'] as bool? ?? false),
          const SizedBox(width: 6),
          _Badge(label: 'Phone', done: data['phoneVerified'] as bool? ?? false),
          const SizedBox(width: 6),
          _Badge(label: 'BG', done: data['backgroundCheckPassed'] as bool? ?? false),
          const Spacer(),
          Text('Tier: $tier', style: Theme.of(context).textTheme.bodySmall),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _reject(context),
            style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor)),
            child: const Text('Reject'),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: () => _approve(context),
            child: const Text('Approve'),
          )),
        ]),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool done;
  const _Badge({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final c = done ? AppTheme.successColor : AppTheme.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(done ? Icons.check : Icons.close, size: 10, color: c),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: c)),
      ]),
    );
  }
}

// ── Tab 3: Safety Alerts ──────────────────────────────────────────────────────

class _SafetyAlertsTab extends StatelessWidget {
  const _SafetyAlertsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: sl<FirebaseFirestore>().collection('safety_alerts')
          .where('status', whereIn: ['open', 'acknowledged', 'escalated'])
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.security, size: 64, color: AppTheme.successColor),
            const SizedBox(height: 16),
            Text('No unresolved safety alerts', style: Theme.of(ctx).textTheme.titleMedium),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _AlertCard(alertId: docs[i].id, data: data);
          },
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String alertId;
  final Map<String, dynamic> data;
  const _AlertCard({required this.alertId, required this.data});

  Future<void> _resolve() async {
    await sl<FirebaseFirestore>().collection('safety_alerts').doc(alertId).update({
      'status': 'resolved',
      'resolvedBy': FirebaseAuth.instance.currentUser?.uid,
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolutionNotes': 'Resolved by admin dashboard',
    });
  }

  String _typeLabel(String rawType) {
    switch (rawType) {
      case 'sosPanic':
      case 'sos':
        return 'SOS Emergency';
      case 'customerReport':
      case 'customer_emergency':
        return 'Customer Report';
      case 'missedCheckIn':
        return 'Missed Check-In';
      case 'missedCheckOut':
        return 'Missed Check-Out';
      case 'locationLost':
        return 'Location Lost';
      default:
        return rawType.isEmpty ? 'Unknown Alert' : rawType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? 'unknown';
    final status = data['status'] as String? ?? 'open';
    final severity = data['severity'] as String? ?? 'medium';
    final isSOS = type == 'sosPanic' || type == 'sos';
    final color = isSOS ? AppTheme.errorColor : AppTheme.warningColor;
    final desc = data['message'] as String? ?? data['description'] as String? ?? 'No description';
    final wid  = data['workerId'] as String? ?? '-';
    final cid  = data['customerId'] as String? ?? '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(isSOS ? Icons.sos : Icons.warning, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_typeLabel(type),
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            Text('Worker: $wid | Customer: $cid', style: Theme.of(context).textTheme.bodySmall),
          ])),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isSOS) Icon(Icons.priority_high, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                '${severity.toUpperCase()} · ${status.toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.phone, size: 14),
            label: const Text('Contact'),
            onPressed: () {},
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 14),
            label: const Text('Resolve'),
            onPressed: _resolve,
          )),
        ]),
      ]),
    );
  }
}

// ── Tab 4: Performance ────────────────────────────────────────────────────────

class _PerformanceTab extends StatelessWidget {
  const _PerformanceTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: sl<FirebaseFirestore>().collection('workers')
          .where('isVerified', isEqualTo: true)
          .orderBy('reliabilityScore', descending: true)
          .limit(30)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('No verified workers.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final name = data['fullName'] as String? ?? data['name'] as String? ?? 'Worker';
            final score = (data['reliabilityScore'] as num?)?.toDouble() ?? 0.0;
            final jobs = data['completedJobsCount'] as int? ?? 0;
            final tier = data['verificationTier'] as String? ?? 'green';
            final tc = _tierC(tier);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(ctx).colorScheme.outline),
              ),
              child: Row(children: [
                SizedBox(width: 28, child: Text('#${i + 1}',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: i < 3 ? AppTheme.warningColor : null))),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: Theme.of(ctx).textTheme.titleSmall),
                  Text('$jobs jobs', style: Theme.of(ctx).textTheme.bodySmall),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(tier.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: tc)),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(score.toStringAsFixed(2),
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  Text('score', style: Theme.of(ctx).textTheme.bodySmall),
                ]),
              ]),
            );
          },
        );
      },
    );
  }

  static Color _tierC(String t) {
    switch (t) {
      case 'blue':    return const Color(0xFF3B82F6);
      case 'gold':    return const Color(0xFFF59E0B);
      case 'partner': return const Color(0xFF8B5CF6);
      default:        return const Color(0xFF22C55E);
    }
  }
}
