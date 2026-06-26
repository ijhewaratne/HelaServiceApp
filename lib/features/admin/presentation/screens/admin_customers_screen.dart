import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../features/customer/domain/entities/customer_profile.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customer_profiles')
                  .orderBy('fullName')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }

                var profiles = snap.data!.docs
                    .map((d) => CustomerProfile.fromFirestore(d))
                    .toList();

                if (_search.isNotEmpty) {
                  profiles = profiles
                      .where((p) =>
                          p.fullName.toLowerCase().contains(_search) ||
                          p.mobileNumber.contains(_search))
                      .toList();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  itemCount: profiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) =>
                      _CustomerTile(profile: profiles[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final CustomerProfile profile;
  const _CustomerTile({required this.profile});

  Future<String?> _getStatus(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    return doc.data()?['status'] as String?;
  }

  Future<void> _toggleStatus(
      BuildContext context, String userId, String? currentStatus) async {
    final isSuspended = currentStatus == 'suspended';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSuspended ? 'Reactivate Customer' : 'Suspend Customer'),
        content: Text(isSuspended
            ? 'Allow this customer to use the platform again?'
            : 'Prevent this customer from making new bookings?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuspended ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isSuspended ? 'Reactivate' : 'Suspend'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'status': isSuspended ? 'active' : 'suspended'});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isSuspended
                ? 'Customer reactivated'
                : 'Customer suspended')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getStatus(profile.userId),
      builder: (context, snap) {
        final status = snap.data;
        final isSuspended = status == 'suspended';

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSuspended
                  ? Colors.red[100]
                  : const Color(0xFFE8F5E9),
              child: Text(
                profile.fullName.isNotEmpty
                    ? profile.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: isSuspended
                        ? Colors.red
                        : const Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(profile.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.mobileNumber),
                if (isSuspended)
                  const Text('SUSPENDED',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'toggle') {
                  _toggleStatus(context, profile.userId, status);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(isSuspended ? Icons.lock_open : Icons.block,
                          color: isSuspended ? Colors.green : Colors.red,
                          size: 18),
                      const SizedBox(width: 8),
                      Text(isSuspended ? 'Reactivate' : 'Suspend'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
