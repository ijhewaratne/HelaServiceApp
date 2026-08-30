import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/admin_scope.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/pending_approval.dart';
import '../../domain/repositories/admin_permissions_repository.dart';
import '../../domain/repositories/approval_repository.dart';

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
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'toggle') {
                              _toggleUserStatus(context, uid, isSuspended);
                            } else if (v == 'permissions') {
                              _managePermissions(context, uid, name);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'permissions',
                              child: Text('Manage permissions'),
                            ),
                            if (!isSuperAdmin)
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                    isSuspended ? 'Reactivate' : 'Suspend'),
                              ),
                          ],
                        ),
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

  Future<void> _managePermissions(
      BuildContext context, String adminUid, String name) async {
    final repository = sl<AdminPermissionsRepository>();
    final currentScopesResult = await repository.getScopes(adminUid);
    if (!context.mounted) return;

    final currentScopes =
        currentScopesResult.fold((_) => <AdminScope>{}, (s) => s);

    final updated = await showDialog<Set<AdminScope>>(
      context: context,
      builder: (_) => _PermissionsDialog(
        name: name,
        initialScopes: currentScopes,
      ),
    );
    if (updated == null || !context.mounted) return;

    final proposedBy = FirebaseAuth.instance.currentUser?.uid ?? '';
    final result = await sl<ApprovalRepository>().propose(
      type: ApprovalType.permissionGrant,
      payload: {
        'adminUid': adminUid,
        'adminName': name,
        'scopes': updated.map((s) => s.name).toList(),
      },
      proposedBy: proposedBy,
    );
    if (!context.mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to propose: ${failure.message}'))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Proposed — awaiting a second admin\'s approval in Pending Approvals'))),
    );
  }
}

class _PermissionsDialog extends StatefulWidget {
  final String name;
  final Set<AdminScope> initialScopes;

  const _PermissionsDialog({required this.name, required this.initialScopes});

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog> {
  late final Set<AdminScope> _selected = {...widget.initialScopes};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Permissions — ${widget.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'These scopes are not yet enforced — every admin keeps '
                  'full access until scope-based rules are turned on. '
                  'Assign them now so access is ready to narrow later.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              ...AdminScope.values.map((scope) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(scope.label),
                    value: _selected.contains(scope),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _selected.add(scope);
                      } else {
                        _selected.remove(scope);
                      }
                    }),
                  )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
