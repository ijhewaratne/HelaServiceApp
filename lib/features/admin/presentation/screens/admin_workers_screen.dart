import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import '../../../../shared/dialogs/confirm_dialog.dart';
import '../../../../core/widgets/branded_widgets.dart';
import '../../data/admin_repository.dart';

class AdminWorkersScreen extends StatefulWidget {
  const AdminWorkersScreen({super.key});

  @override
  State<AdminWorkersScreen> createState() => _AdminWorkersScreenState();
}

class _AdminWorkersScreenState extends State<AdminWorkersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().fetchDashboardData();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Approvals'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'New Applicants'),
            Tab(text: 'Blue Tier Reviews'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _NewApplicantsTab(),
          _BlueTierTab(),
        ],
      ),
    );
  }
}

// ── Tab 1: new green-tier applicants ─────────────────────────────────────────

class _NewApplicantsTab extends StatelessWidget {
  const _NewApplicantsTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    if (vm.isLoading) return const Center(child: CircularProgressIndicator());
    if (vm.pendingWorkers.isEmpty) {
      return Center(
          child: Text('No pending workers',
              style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vm.pendingWorkers.length,
      itemBuilder: (context, index) {
        final worker = vm.pendingWorkers[index];
        return GlassCard(
          child: Row(children: [
            CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Icon(Icons.person, color: Colors.orange.shade800),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(worker.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                    'ID: ${worker.uid.substring(0, 8)}… | ${worker.verificationStatus.toUpperCase()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ),
            ElevatedButton(
              onPressed: () async {
                final confirm = await showConfirmDialog(context,
                    title: 'Approve Worker',
                    message: 'Approve ${worker.name}?');
                if (confirm && context.mounted) {
                  await context.read<AdminViewModel>().approveWorker(worker.uid);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Approve', style: TextStyle(fontSize: 13)),
            ),
          ]),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
      },
    );
  }
}

// ── Tab 2: blue-tier reference-call reviews ──────────────────────────────────

class _BlueTierTab extends StatelessWidget {
  const _BlueTierTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    if (vm.isLoading) return const Center(child: CircularProgressIndicator());
    if (vm.blueTierPending.isEmpty) {
      return Center(
          child: Text('No pending blue-tier reviews',
              style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vm.blueTierPending.length,
      itemBuilder: (context, i) =>
          _BlueTierCard(verification: vm.blueTierPending[i])
              .animate()
              .fadeIn(delay: Duration(milliseconds: 80 * i))
              .slideX(begin: 0.1),
    );
  }
}

class _BlueTierCard extends StatelessWidget {
  final BlueTierVerification verification;
  const _BlueTierCard({required this.verification});

  bool get _allRefsCalled => verification.references.every(
      (r) => r.verificationStatus != 'pending');

  @override
  Widget build(BuildContext context) {
    final v = verification;
    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.12),
            child: const Icon(Icons.workspace_premium,
                color: Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.workerName ?? 'Worker ${v.workerId.substring(0, 8)}…',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text('Submitted ${_daysAgo(v.submittedAt)} · Blue Tier Request',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
          ),
          if (v.policeClearanceFrontUrl != null)
            Tooltip(
              message: 'Police clearance uploaded',
              child: Icon(Icons.verified_user_outlined,
                  color: Colors.green.shade600, size: 20),
            ),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Text('References',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...v.references.asMap().entries.map((e) =>
            _ReferenceRow(
                verification: v, reference: e.value, index: e.key)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(context, v),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: _allRefsCalled
                  ? () => _approveWithConfirm(context, v)
                  : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6)),
              child: const Text('Approve Blue Tier'),
            ),
          ),
        ]),
        if (!_allRefsCalled)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Log all reference calls before approving.',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                textAlign: TextAlign.center),
          ),
      ]),
    );
  }

  Future<void> _approveWithConfirm(
      BuildContext context, BlueTierVerification v) async {
    final ok = await showConfirmDialog(context,
        title: 'Approve Blue Tier',
        message:
            'Grant Blue Tier status to ${v.workerName ?? v.workerId}? This cannot be reversed without admin CLI.');
    if (ok && context.mounted) {
      await context.read<AdminViewModel>().approveBlueTierUpgrade(v.workerId);
    }
  }

  Future<void> _showRejectDialog(
      BuildContext context, BlueTierVerification v) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Blue Tier Application'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
              labelText: 'Rejection reason', hintText: 'e.g. Reference refused'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Reject',
                  style: TextStyle(color: Colors.red.shade700))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context
          .read<AdminViewModel>()
          .rejectBlueTierUpgrade(v.workerId, reasonCtrl.text.trim());
    }
  }

  static String _daysAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return '1 day ago';
    return '$diff days ago';
  }
}

class _ReferenceRow extends StatelessWidget {
  final BlueTierVerification verification;
  final ReferenceContact reference;
  final int index;

  const _ReferenceRow({
    required this.verification,
    required this.reference,
    required this.index,
  });

  Color get _statusColor {
    switch (reference.verificationStatus) {
      case 'called_confirmed':
        return Colors.green;
      case 'called_refused':
        return Colors.red;
      case 'no_answer':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (reference.verificationStatus) {
      case 'called_confirmed':
        return 'Confirmed';
      case 'called_refused':
        return 'Refused';
      case 'no_answer':
        return 'No answer';
      default:
        return 'Pending call';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ref ${index + 1}: ${reference.name}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${reference.phone} · ${reference.relation}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (reference.callNotes != null && reference.callNotes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Notes: ${reference.callNotes}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic)),
              ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_statusLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _statusColor)),
          ),
          const SizedBox(height: 4),
          TextButton(
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(60, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () => _showLogCallDialog(context),
            child: const Text('Log call', style: TextStyle(fontSize: 12)),
          ),
        ]),
      ]),
    );
  }

  void _showLogCallDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _LogCallDialog(
        reference: reference,
        onSubmit: (outcome, notes) async {
          await context.read<AdminViewModel>().logReferenceCallOutcome(
            workerId: verification.workerId,
            referenceIndex: index,
            outcome: outcome,
            notes: notes,
          );
        },
      ),
    );
  }
}

// ── Log call outcome dialog ───────────────────────────────────────────────────

class _LogCallDialog extends StatefulWidget {
  final ReferenceContact reference;
  final Future<void> Function(String outcome, String notes) onSubmit;

  const _LogCallDialog({required this.reference, required this.onSubmit});

  @override
  State<_LogCallDialog> createState() => _LogCallDialogState();
}

class _LogCallDialogState extends State<_LogCallDialog> {
  String _outcome = 'called_confirmed';
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  static const _outcomes = [
    ('called_confirmed', 'Confirmed — spoke with reference, positive feedback'),
    ('called_refused', 'Refused — reference gave negative feedback'),
    ('no_answer', 'No answer — could not reach reference'),
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log call: ${widget.reference.name}'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${widget.reference.phone} · ${widget.reference.relation}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ..._outcomes.map((o) {
            final (value, label) = o;
            return RadioListTile<String>(
              title: Text(label, style: const TextStyle(fontSize: 13)),
              value: value,
              groupValue: _outcome,
              onChanged: (v) => setState(() => _outcome = v!),
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
                labelText: 'Call notes (optional)',
                hintText: 'What did they say?'),
            maxLines: 3,
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  try {
                    await widget.onSubmit(_outcome, _notesCtrl.text.trim());
                    if (context.mounted) Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
