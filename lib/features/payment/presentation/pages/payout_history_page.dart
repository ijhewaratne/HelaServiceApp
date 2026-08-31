import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Payout History — worker-facing list of weekly payouts (10.9)
// ──────────────────────────────────────────────────────────────────────────────

class PayoutHistoryPage extends StatelessWidget {
  const PayoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payout History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: sl<FirebaseFirestore>()
            .collection('payouts')
            .where('workerId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payouts yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payouts are processed every Monday.\nMinimum payout: LKR 1,000.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Lifetime total
          double totalEarned = 0;
          for (final doc in docs) {
            final d = doc.data() as Map<String, dynamic>;
            totalEarned += (d['workerAmount'] as num?)?.toDouble() ?? 0;
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SummaryBanner(totalEarned: totalEarned),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _PayoutCard(data: data);
                  }, childCount: docs.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final double totalEarned;
  const _SummaryBanner({required this.totalEarned});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Lifetime Earnings',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'LKR ${totalEarned.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your 80% share of completed bookings',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PayoutCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final amount = (data['workerAmount'] as num?)?.toDouble() ?? 0;
    final gross = (data['grossAmount'] as num?)?.toDouble() ?? 0;
    final fee = (data['platformFee'] as num?)?.toDouble() ?? 0;
    final jobCount = (data['bookingIds'] as List?)?.length ?? 0;
    final createdTs = data['createdAt'] as Timestamp?;
    final dateStr = createdTs != null ? _formatDate(createdTs.toDate()) : '—';

    final statusColor = _statusColor(status);
    final isBelowThreshold = status == 'below_threshold';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '$jobCount job${jobCount != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isBelowThreshold
                        ? 'Carried over'
                        : 'LKR ${amount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isBelowThreshold
                          ? Theme.of(context).colorScheme.outline
                          : AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isBelowThreshold) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gross', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  'LKR ${gross.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Platform fee (20%)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '– LKR ${fee.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.errorColor),
                ),
              ],
            ),
          ],
          if (isBelowThreshold)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Below LKR 1,000 threshold — will be added to next payout.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'below_threshold':
        return const Color(0xFF94A3B8);
      case 'failed':
        return AppTheme.errorColor;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'completed':
        return 'Paid';
      case 'pending':
        return 'Processing';
      case 'below_threshold':
        return 'Below min';
      case 'failed':
        return 'Failed';
      default:
        return s;
    }
  }

  static String _formatDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}
