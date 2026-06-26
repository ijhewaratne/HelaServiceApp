import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Super-admin-only screen to view and manage admin user accounts.
/// Actual role changes (Firebase custom claims) must be done via
/// Cloud Functions — this screen exposes the user list and account status.
class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.amber[50],
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Role assignments require Firebase Admin SDK. Contact your super admin to promote/demote users.',
                    style: TextStyle(color: Colors.amber[900], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Admin Users',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('userType', whereIn: ['admin', 'superAdmin'])
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return const Center(child: Text('No admin users found'));
                }
                final docs = snap.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final uid = docs[i].id;
                    final name = data['fullName'] as String? ??
                        data['displayName'] as String? ??
                        'Unknown';
                    final phone = data['phoneNumber'] as String? ?? '';
                    final userType =
                        data['userType'] as String? ?? 'admin';
                    final status =
                        data['status'] as String? ?? 'active';
                    final isSuspended = status == 'suspended';
                    final isSuperAdmin = userType == 'superAdmin';

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSuperAdmin
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFFE8F5E9),
                          child: Icon(
                            isSuperAdmin
                                ? Icons.admin_panel_settings
                                : Icons.manage_accounts,
                            color: isSuperAdmin
                                ? Colors.white
                                : const Color(0xFF1B5E20),
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            if (isSuperAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Super Admin',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10)),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '$phone\nUID: ${uid.substring(0, 12)}...'
                          '${isSuspended ? ' · SUSPENDED' : ''}',
                          style: TextStyle(
                              color: isSuspended
                                  ? Colors.red
                                  : Colors.grey[500],
                              fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: !isSuperAdmin
                            ? PopupMenuButton<String>(
                                onSelected: (v) =>
                                    _toggleUserStatus(
                                        context, uid, isSuspended),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Text(isSuspended
                                        ? 'Reactivate'
                                        : 'Suspend'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(
      BuildContext context, String uid, bool isSuspended) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSuspended ? 'Reactivate User' : 'Suspend User'),
        content:
            Text('Are you sure you want to ${isSuspended ? 'reactivate' : 'suspend'} this admin?'),
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
        .doc(uid)
        .update({'status': isSuspended ? 'active' : 'suspended'});
  }
}
