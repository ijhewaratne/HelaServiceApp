import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../../../safety/domain/entities/safety_alert.dart';
import '../../../safety/presentation/bloc/safety_bloc.dart';

/// Admin dashboard for live safety alerts with escalation actions.
class EmergencyDashboard extends StatelessWidget {
  const EmergencyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SafetyBloc>()..add(WatchOpenAlerts()),
      child: const _EmergencyDashboardBody(),
    );
  }
}

class _EmergencyDashboardBody extends StatelessWidget {
  const _EmergencyDashboardBody();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Dashboard'),
          centerTitle: true,
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  context.read<SafetyBloc>().add(WatchOpenAlerts()),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Open'),
              Tab(text: 'Escalated'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        body: BlocConsumer<SafetyBloc, SafetyState>(
          listener: (ctx, state) {
            if (state is SafetyError) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text(state.message),
                    backgroundColor: Colors.red),
              );
            }
          },
          builder: (ctx, state) {
            if (state is SafetyLoading || state is SafetyInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            final alerts = state is OpenAlertsLoaded ? state.alerts : <SafetyAlert>[];

            final open = alerts.where((a) => a.status == AlertStatus.open || a.status == AlertStatus.acknowledged).toList();
            final escalated = alerts.where((a) => a.status == AlertStatus.escalated).toList();
            final resolved = alerts.where((a) => a.status == AlertStatus.resolved).toList();

            return TabBarView(
              children: [
                _AlertList(alerts: open, showEscalateAction: true),
                _AlertList(alerts: escalated, showLogContactAction: true),
                _AlertList(alerts: resolved),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlertList extends StatelessWidget {
  final List<SafetyAlert> alerts;
  final bool showEscalateAction;
  final bool showLogContactAction;

  const _AlertList({
    required this.alerts,
    this.showEscalateAction = false,
    this.showLogContactAction = false,
  });

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Center(
          child: Text('No alerts',
              style: TextStyle(color: Colors.grey.shade600)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: alerts.length,
      itemBuilder: (ctx, i) => _AlertCard(
        alert: alerts[i],
        showEscalateAction: showEscalateAction,
        showLogContactAction: showLogContactAction,
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SafetyAlert alert;
  final bool showEscalateAction;
  final bool showLogContactAction;

  const _AlertCard({
    required this.alert,
    required this.showEscalateAction,
    required this.showLogContactAction,
  });

  Color get _severityColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return Colors.red;
      case AlertSeverity.high:
        return Colors.orange;
      case AlertSeverity.medium:
        return Colors.amber;
      case AlertSeverity.low:
        return Colors.blue;
    }
  }

  String get _typeLabel {
    switch (alert.type) {
      case AlertType.sosPanic:
        return 'SOS Panic';
      case AlertType.missedCheckIn:
        return 'Missed Check-In';
      case AlertType.missedCheckOut:
        return 'Missed Check-Out';
      case AlertType.customerReport:
        return 'Customer Report';
      case AlertType.locationLost:
        return 'Location Lost';
    }
  }

  String _elapsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _severityColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _severityColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                alert.severity.name.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(_typeLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            Text(_elapsed(alert.createdAt),
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600)),
          ]),
          const SizedBox(height: 8),
          Text(alert.message,
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            'Booking: ${alert.bookingId.isEmpty ? '-' : alert.bookingId.substring(0, alert.bookingId.length.clamp(0, 12))}… '
            '| Worker: ${alert.workerId.isEmpty ? '-' : alert.workerId.substring(0, alert.workerId.length.clamp(0, 8))}…',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          if (showEscalateAction || showLogContactAction) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(children: [
              if (showEscalateAction) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Acknowledge'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6)),
                    onPressed: () => context
                        .read<SafetyBloc>()
                        .add(AcknowledgeAlert(alert.id)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.escalator_warning, size: 16),
                    label: const Text('Escalate'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6)),
                    onPressed: () => context
                        .read<SafetyBloc>()
                        .add(EscalateAlert(alert.id)),
                  ),
                ),
              ],
              if (showLogContactAction) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Log contact'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6)),
                    onPressed: () =>
                        _showLogContactDialog(context, alert),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.task_alt, size: 16),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6)),
                    onPressed: () =>
                        _showResolveDialog(context, alert),
                  ),
                ),
              ],
            ]),
          ],
        ]),
      ),
    );
  }

  void _showLogContactDialog(BuildContext context, SafetyAlert alert) {
    final notesCtrl = TextEditingController();
    String contactType = 'phone';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Log Manual Contact'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Record a contact attempt for this escalation.'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: contactType,
              decoration: const InputDecoration(labelText: 'Contact type'),
              items: const [
                DropdownMenuItem(value: 'phone', child: Text('Phone call')),
                DropdownMenuItem(value: 'sms', child: Text('SMS sent')),
                DropdownMenuItem(value: 'police', child: Text('Police notified')),
              ],
              onChanged: (v) => setS(() => contactType = v ?? 'phone'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Spoke to contact, confirmed worker safe...'),
              maxLines: 3,
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final adminId =
                    FirebaseAuth.instance.currentUser?.uid ?? 'admin';
                context.read<SafetyBloc>().add(LogManualContact(
                      alertId: alert.id,
                      adminId: adminId,
                      contactType: contactType,
                      notes: notesCtrl.text.trim(),
                    ));
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResolveDialog(BuildContext context, SafetyAlert alert) {
    final notesCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Alert'),
        content: TextField(
          controller: notesCtrl,
          decoration: const InputDecoration(
              labelText: 'Resolution notes',
              hintText: 'Confirmed safe, no further action needed...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final adminId =
                  FirebaseAuth.instance.currentUser?.uid ?? 'admin';
              context.read<SafetyBloc>().add(ResolveAlert(
                    alertId: alert.id,
                    adminId: adminId,
                    notes: notesCtrl.text.trim(),
                  ));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Mark Resolved',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
