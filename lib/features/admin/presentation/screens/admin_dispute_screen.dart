import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../features/safety/domain/entities/dispute.dart';

class AdminDisputeScreen extends StatefulWidget {
  const AdminDisputeScreen({super.key});

  @override
  State<AdminDisputeScreen> createState() => _AdminDisputeScreenState();
}

class _AdminDisputeScreenState extends State<AdminDisputeScreen> {
  DisputeStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispute Management'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<DisputeStatus?>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (v) => setState(() => _filterStatus = v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: null, child: Text('All Disputes')),
              ...DisputeStatus.values.map((s) => PopupMenuItem(
                    value: s,
                    child: Text(s.name),
                  )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_filterStatus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              color: const Color(0xFFE8F5E9),
              child: Row(
                children: [
                  Text('Filter: ${_filterStatus!.name}',
                      style: const TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _filterStatus = null),
                    child: const Icon(Icons.close,
                        size: 16, color: Color(0xFF1B5E20)),
                  ),
                ],
              ),
            ),
          Expanded(child: _DisputeList(statusFilter: _filterStatus)),
        ],
      ),
    );
  }
}

class _DisputeList extends StatelessWidget {
  final DisputeStatus? statusFilter;
  const _DisputeList({this.statusFilter});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('disputes')
        .orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter!.name);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(50).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('No disputes found'));
        }

        final disputes = snap.data!.docs
            .map((d) => Dispute.fromFirestore(d))
            .toList();

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: disputes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) =>
              _DisputeCard(dispute: disputes[i]),
        );
      },
    );
  }
}

class _DisputeCard extends StatefulWidget {
  final Dispute dispute;
  const _DisputeCard({required this.dispute});

  @override
  State<_DisputeCard> createState() => _DisputeCardState();
}

class _DisputeCardState extends State<_DisputeCard> {
  bool _expanded = false;
  bool _busy = false;

  Color _statusColor(DisputeStatus s) {
    switch (s) {
      case DisputeStatus.open:        return Colors.orange;
      case DisputeStatus.underReview: return Colors.blue;
      case DisputeStatus.resolved:    return Colors.green;
      case DisputeStatus.closed:      return Colors.grey;
    }
  }

  Future<void> _updateStatus(DisputeStatus newStatus) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark as ${newStatus.name}'),
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(
              hintText: 'Admin note (optional)'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20)),
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    setState(() => _busy = true);
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'resolvedByAdminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (noteCtrl.text.trim().isNotEmpty) {
        updates['adminNote'] = noteCtrl.text.trim();
      }
      if (newStatus == DisputeStatus.resolved ||
          newStatus == DisputeStatus.closed) {
        updates['resolvedAt'] = FieldValue.serverTimestamp();
      }
      await FirebaseFirestore.instance
          .collection('disputes')
          .doc(widget.dispute.id)
          .update(updates);

      await FirebaseFirestore.instance.collection('audit_logs').add({
        'adminUserId': adminId,
        'actionType': 'update_dispute_status',
        'entityType': 'disputes',
        'entityId': widget.dispute.id,
        'newValue': newStatus.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dispute;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusColor(d.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.issueType.name
                              .replaceAllMapped(RegExp(r'([A-Z])'),
                                  (m) => ' ${m[0]}')
                              .trim(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Booking: ${d.requestId.substring(0, 8)}... · ${d.status.name}',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(_expanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.description,
                      style: TextStyle(
                          color: Colors.grey[700], height: 1.4)),
                  if (d.adminNote != null) ...[
                    const SizedBox(height: 8),
                    Text('Admin note: ${d.adminNote}',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                            fontSize: 13)),
                  ],
                  const SizedBox(height: 12),
                  if (_busy)
                    const LinearProgressIndicator()
                  else if (d.status == DisputeStatus.open ||
                      d.status == DisputeStatus.underReview)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (d.status == DisputeStatus.open)
                          _StatusBtn(
                              'Under Review',
                              Colors.blue,
                              () => _updateStatus(
                                  DisputeStatus.underReview)),
                        _StatusBtn(
                            'Resolved',
                            Colors.green,
                            () =>
                                _updateStatus(DisputeStatus.resolved)),
                        _StatusBtn(
                            'Close',
                            Colors.grey,
                            () =>
                                _updateStatus(DisputeStatus.closed)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatusBtn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
