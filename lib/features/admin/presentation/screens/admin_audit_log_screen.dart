import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuditLogScreen extends StatelessWidget {
  const AdminAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('audit_logs')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No audit log entries'));
          }

          final docs = snap.data!.docs;
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final actionType = data['actionType'] as String? ?? 'unknown';
              final entityType = data['entityType'] as String? ?? '';
              final entityId = data['entityId'] as String? ?? '';
              final adminId = data['adminUserId'] as String? ?? 'system';
              final ts = data['createdAt'];
              DateTime? time;
              if (ts is Timestamp) time = ts.toDate();

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _actionColor(actionType).withOpacity(0.1),
                  child: Icon(
                    _actionIcon(actionType),
                    color: _actionColor(actionType),
                    size: 18,
                  ),
                ),
                title: Text(
                  _formatAction(actionType),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '$entityType${entityId.isNotEmpty ? ' · ${entityId.substring(0, entityId.length > 8 ? 8 : entityId.length)}...' : ''}\nAdmin: ${adminId.length > 8 ? adminId.substring(0, 8) : adminId}...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                trailing: time != null
                    ? Text(
                        '${time.day}/${time.month}/${time.year}\n${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        textAlign: TextAlign.right,
                      )
                    : null,
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }

  Color _actionColor(String action) {
    if (action.startsWith('approve')) return Colors.green;
    if (action.startsWith('hide') || action.startsWith('suspend')) {
      return Colors.red;
    }
    if (action.startsWith('flag')) return Colors.orange;
    if (action.startsWith('update')) return Colors.blue;
    return Colors.grey;
  }

  IconData _actionIcon(String action) {
    if (action.startsWith('approve')) return Icons.check_circle;
    if (action.startsWith('hide')) return Icons.visibility_off;
    if (action.startsWith('flag')) return Icons.flag;
    if (action.startsWith('suspend')) return Icons.block;
    if (action.startsWith('update')) return Icons.edit;
    return Icons.history;
  }

  String _formatAction(String action) {
    return action
        .replaceAllMapped(RegExp(r'_([a-z])'), (m) => ' ${m[1]!.toUpperCase()}')
        .replaceFirst(action[0], action[0].toUpperCase());
  }
}
