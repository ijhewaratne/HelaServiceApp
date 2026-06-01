import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_repository.dart';

/// Admin screen for viewing and responding to open support tickets.
class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  late Future<List<SupportTicket>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = sl<SupportRepository>()
        .getAllOpenTickets()
        .then((r) => r.fold((_) => <SupportTicket>[], (t) => t));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(_load)),
        ],
      ),
      body: FutureBuilder<List<SupportTicket>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets = snap.data ?? [];
          if (tickets.isEmpty) {
            return Center(
                child: Text('No open tickets.',
                    style: TextStyle(color: Colors.grey.shade600)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (ctx, i) => _AdminTicketCard(
              ticket: tickets[i],
              onUpdated: () => setState(_load),
            ),
          );
        },
      ),
    );
  }
}

class _AdminTicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onUpdated;
  const _AdminTicketCard({required this.ticket, required this.onUpdated});

  Color get _statusColor {
    switch (ticket.status) {
      case TicketStatus.open:
        return Colors.orange;
      case TicketStatus.inProgress:
        return Colors.blue;
      case TicketStatus.resolved:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(ticket.status.label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor)),
            ),
            const SizedBox(width: 8),
            Text(ticket.category.label,
                style: const TextStyle(fontSize: 11)),
            const Spacer(),
            Text(
              _elapsed(ticket.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ]),
          const SizedBox(height: 8),
          Text(ticket.subject,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(ticket.description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          Text('Customer: ${ticket.customerId.substring(0, 8)}…',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showResponseDialog(context, TicketStatus.inProgress),
                child: const Text('In Progress'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green),
                onPressed: () => _showResponseDialog(context, TicketStatus.resolved),
                child: const Text('Resolve',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showResponseDialog(
      BuildContext context, TicketStatus newStatus) {
    final responseCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus == TicketStatus.resolved
            ? 'Resolve Ticket'
            : 'Mark In Progress'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Subject: ${ticket.subject}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            controller: responseCtrl,
            decoration: const InputDecoration(
                labelText: 'Response to customer *',
                hintText:
                    'Explain the action taken or ask for more information…'),
            maxLines: 4,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (responseCtrl.text.trim().isEmpty) return;
              final adminId =
                  FirebaseAuth.instance.currentUser?.uid ?? 'admin';
              await sl<SupportRepository>().respondToTicket(
                ticketId: ticket.id,
                adminId: adminId,
                response: responseCtrl.text.trim(),
                newStatus: newStatus,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              onUpdated();
            },
            child: const Text('Send Response'),
          ),
        ],
      ),
    );
  }

  static String _elapsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
