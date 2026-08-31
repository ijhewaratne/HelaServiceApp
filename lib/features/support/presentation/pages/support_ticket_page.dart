import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_repository.dart';

/// Customer-facing page for filing a support ticket and viewing prior tickets.
class SupportTicketPage extends StatefulWidget {
  const SupportTicketPage({super.key});

  @override
  State<SupportTicketPage> createState() => _SupportTicketPageState();
}

class _SupportTicketPageState extends State<SupportTicketPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
        title: const Text('Help & Support'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'New Request'),
            Tab(text: 'My Tickets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_NewTicketTab(), _MyTicketsTab()],
      ),
    );
  }
}

// ── Tab 1: new ticket form ────────────────────────────────────────────────────

class _NewTicketTab extends StatefulWidget {
  const _NewTicketTab();

  @override
  State<_NewTicketTab> createState() => _NewTicketTabState();
}

class _NewTicketTabState extends State<_NewTicketTab> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TicketCategory _category = TicketCategory.other;
  bool _submitting = false;

  static const _categories = [
    TicketCategory.billing,
    TicketCategory.workerBehavior,
    TicketCategory.serviceQuality,
    TicketCategory.appIssue,
    TicketCategory.other,
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);
    try {
      final ticket = SupportTicket(
        id: '',
        customerId: uid,
        category: _category,
        subject: _subjectCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        createdAt: DateTime.now(),
      );
      final result = await sl<SupportRepository>().createTicket(ticket);
      if (!mounted) return;
      result.fold(
        (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${f.message}'),
            backgroundColor: Colors.red,
          ),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ticket submitted. We\'ll respond within 24 hours.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _subjectCtrl.clear();
          _descCtrl.clear();
          setState(() => _category = TicketCategory.other);
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we help you?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TicketCategory>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? TicketCategory.other),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject *',
                hintText: 'Brief summary of the issue',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText:
                    'Describe the issue in detail. Include booking ID if relevant.',
              ),
              maxLines: 5,
              validator: (v) => (v == null || v.trim().length < 20)
                  ? 'Please provide at least 20 characters.'
                  : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Support Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 2: customer's prior tickets ─────────────────────────────────────────

class _MyTicketsTab extends StatefulWidget {
  const _MyTicketsTab();

  @override
  State<_MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<_MyTicketsTab> {
  late Future<List<SupportTicket>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _future = sl<SupportRepository>()
        .getCustomerTickets(uid)
        .then((r) => r.fold((_) => <SupportTicket>[], (t) => t));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SupportTicket>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tickets = snap.data ?? [];
        if (tickets.isEmpty) {
          return Center(
            child: Text(
              'No tickets yet.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length,
          itemBuilder: (ctx, i) => _TicketCard(ticket: tickets[i]),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  const _TicketCard({required this.ticket});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.status.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ticket.category.label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              ticket.subject,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              ticket.description,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (ticket.adminResponse != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Support Response:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.adminResponse!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
