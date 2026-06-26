import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../features/booking/domain/entities/review.dart';

class AdminReviewModerationScreen extends StatelessWidget {
  const AdminReviewModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Moderation'),
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'All Reviews'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReviewList(statusFilter: 'pending'),
            _ReviewList(statusFilter: null),
          ],
        ),
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  final String? statusFilter;
  const _ReviewList({this.statusFilter});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('reviews')
        .orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('moderationStatus', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(50).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  statusFilter == 'pending'
                      ? 'No pending reviews'
                      : 'No reviews found',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        final reviews = snap.data!.docs
            .map((d) => Review.fromFirestore(d))
            .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _ReviewModerationCard(review: reviews[i]),
        );
      },
    );
  }
}

class _ReviewModerationCard extends StatefulWidget {
  final Review review;
  const _ReviewModerationCard({required this.review});

  @override
  State<_ReviewModerationCard> createState() =>
      _ReviewModerationCardState();
}

class _ReviewModerationCardState extends State<_ReviewModerationCard> {
  bool _busy = false;

  Future<void> _updateStatus(String newStatus, {String? note}) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    setState(() => _busy = true);
    try {
      final fs = FirebaseFirestore.instance;
      final updates = <String, dynamic>{
        'moderationStatus': newStatus,
        'moderatedAt': FieldValue.serverTimestamp(),
      };
      if (note != null) updates['adminNote'] = note;

      // Batch: review update + audit log are atomic
      final batch = fs.batch();
      batch.update(fs.collection('reviews').doc(widget.review.id), updates);
      batch.set(fs.collection('audit_logs').doc(), {
        'adminUserId': adminId,
        'actionType': '${newStatus}_review',
        'entityType': 'reviews',
        'entityId': widget.review.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      // Recalculate rating any time the approved-review set changes
      final prevStatus = widget.review.moderationStatus;
      final affectsRating = newStatus == 'approved' ||
          prevStatus == ReviewModerationStatus.approved;
      if (affectsRating) {
        await _updateProviderRating(widget.review.providerId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _updateProviderRating(String providerId) async {
    final snap = await FirebaseFirestore.instance
        .collection('reviews')
        .where('providerId', isEqualTo: providerId)
        .where('moderationStatus', isEqualTo: 'approved')
        .get();
    final ratings = snap.docs
        .map((d) =>
            (d.data() as Map<String, dynamic>)['rating'] as int? ?? 0)
        .where((r) => r > 0)
        .toList();
    final avg = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;
    await FirebaseFirestore.instance
        .collection('workers')
        .doc(providerId)
        .update({'rating': avg, 'reviewCount': ratings.length});
  }

  Future<void> _hideWithNote() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hide Review'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              hintText: 'Admin note (optional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hide',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateStatus('hidden',
          note: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
    }
  }

  Color _statusColor(ReviewModerationStatus s) {
    switch (s) {
      case ReviewModerationStatus.approved: return Colors.green;
      case ReviewModerationStatus.hidden:   return Colors.red;
      case ReviewModerationStatus.flagged:  return Colors.orange;
      case ReviewModerationStatus.pending:  return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(5, (i) => Icon(Icons.star,
                    size: 16,
                    color: i < r.rating
                        ? Colors.amber
                        : Colors.grey[300])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(r.moderationStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    r.moderationStatus.name,
                    style: TextStyle(
                        color: _statusColor(r.moderationStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            if (r.reviewText != null && r.reviewText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.reviewText!,
                  style: TextStyle(color: Colors.grey[700])),
            ],
            const SizedBox(height: 6),
            Text('Provider: ${r.providerId.substring(0, 8)}...',
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              )
            else if (r.moderationStatus == ReviewModerationStatus.pending ||
                r.moderationStatus == ReviewModerationStatus.flagged) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _ActionBtn(
                    label: 'Approve',
                    color: Colors.green,
                    icon: Icons.check,
                    onTap: () => _updateStatus('approved'),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    label: 'Hide',
                    color: Colors.red,
                    icon: Icons.visibility_off,
                    onTap: _hideWithNote,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    label: 'Flag',
                    color: Colors.orange,
                    icon: Icons.flag,
                    onTap: () => _updateStatus('flagged'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.color,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
