import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/config/theme.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/pending_approval.dart';
import '../../domain/repositories/approval_repository.dart';

/// Two-person approval queue for high-risk admin changes (category
/// deactivation, permission grants). Proposals are created elsewhere in the
/// admin app; this screen is where a *different* admin decides them.
class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  late Future<List<PendingApproval>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PendingApproval>> _load() async {
    final result = await sl<ApprovalRepository>().getPending();
    return result.fold((_) => [], (list) => list);
  }

  void _refresh() => setState(() => _future = _load());

  String _describe(PendingApproval approval) {
    switch (approval.type) {
      case ApprovalType.categoryDeactivation:
        final name = approval.payload['categoryName'] as String? ?? 'a category';
        return 'Deactivate "$name"';
      case ApprovalType.permissionGrant:
        final name = approval.payload['adminName'] as String? ?? 'an admin';
        final scopes = (approval.payload['scopes'] as List?)?.join(', ') ?? '';
        return 'Grant $name: $scopes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<PendingApproval>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final approvals = snap.data ?? [];
          if (approvals.isEmpty) {
            return Center(
              child: Text('No pending approvals',
                  style: TextStyle(color: Colors.grey.shade600)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: approvals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final approval = approvals[i];
              final isOwnProposal = approval.proposedBy == currentUid;
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_describe(approval),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        'Proposed by ${approval.proposedBy.substring(0, approval.proposedBy.length.clamp(0, 8))}… '
                        'on ${approval.proposedAt.toLocal()}'.split('.').first,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      if (isOwnProposal)
                        Text(
                          'Waiting for a different admin to decide — you cannot approve your own proposal.',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.orange.shade800),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _decide(approval, false),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red.shade700),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _decide(approval, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successColor),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _decide(PendingApproval approval, bool approve) async {
    final decidedBy = FirebaseAuth.instance.currentUser?.uid ?? '';
    final result = await sl<ApprovalRepository>().decide(
      approvalId: approval.id,
      approve: approve,
      decidedBy: decidedBy,
    );
    if (!mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${failure.message}'))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve ? 'Approved' : 'Rejected'))),
    );
    _refresh();
  }
}
