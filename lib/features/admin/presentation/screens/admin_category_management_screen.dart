import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/pending_approval.dart';
import '../../domain/repositories/approval_repository.dart';

class AdminCategoryManagementScreen extends StatelessWidget {
  const AdminCategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Categories'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context, null),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_catalog')
            .orderBy('displayName')
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No categories yet'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showCategoryDialog(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snap.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;
              final name = data['displayName'] as String? ?? '';
              final basePrice =
                  (data['basePrice'] as num?)?.toDouble() ?? 0.0;
              final isActive = data['isActive'] as bool? ?? true;
              final description = data['description'] as String?;
              final iconName = data['iconName'] as String?;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive
                        ? const Color(0xFFE8F5E9)
                        : Colors.grey[200],
                    child: Icon(
                      _iconFromName(iconName),
                      color: isActive
                          ? const Color(0xFF1B5E20)
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Inactive',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    'Base: LKR ${basePrice.toStringAsFixed(0)}'
                    '${description != null && description.isNotEmpty ? ' · $description' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        onChanged: (v) => v
                            // Turning a category back on is low-risk and stays
                            // a direct action; turning one off needs a second
                            // admin's sign-off (see docs/SPEC_DECISIONS.md).
                            ? FirebaseFirestore.instance
                                .collection('service_catalog')
                                .doc(id)
                                .update({'isActive': true})
                            : _proposeDeactivation(context, id, name),
                        activeColor: const Color(0xFF1B5E20),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showCategoryDialog(
                            context, docs[i]),
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

  IconData _iconFromName(String? name) {
    switch (name) {
      case 'cleaning':    return Icons.cleaning_services;
      case 'plumbing':    return Icons.plumbing;
      case 'electrical':  return Icons.electrical_services;
      case 'ac_repair':   return Icons.ac_unit;
      case 'gardening':   return Icons.grass;
      case 'babysitting': return Icons.child_care;
      case 'cooking':     return Icons.restaurant;
      case 'laundry':     return Icons.local_laundry_service;
      default:            return Icons.home_repair_service;
    }
  }

  void _showCategoryDialog(BuildContext context, DocumentSnapshot? doc) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryDialog(doc: doc),
    );
  }

  Future<void> _proposeDeactivation(
      BuildContext context, String categoryId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Propose deactivation'),
        content: Text(
          'Deactivating "$name" needs sign-off from a second admin before '
          'it takes effect. This will create a pending approval.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Propose'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final proposedBy = FirebaseAuth.instance.currentUser?.uid ?? '';
    final result = await sl<ApprovalRepository>().propose(
      type: ApprovalType.categoryDeactivation,
      payload: {'categoryId': categoryId, 'categoryName': name},
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

class _CategoryDialog extends StatefulWidget {
  final DocumentSnapshot? doc;
  const _CategoryDialog({this.doc});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _iconCtrl;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data() as Map<String, dynamic>?;
    _nameCtrl = TextEditingController(
        text: data?['displayName'] as String? ?? '');
    _descCtrl = TextEditingController(
        text: data?['description'] as String? ?? '');
    _priceCtrl = TextEditingController(
        text: (data?['basePrice'] as num?)?.toStringAsFixed(0) ?? '');
    _iconCtrl = TextEditingController(
        text: data?['iconName'] as String? ?? '');
    _isActive = data?['isActive'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final data = {
        'displayName': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'basePrice':
            double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'iconName': _iconCtrl.text.trim().isEmpty
            ? null
            : _iconCtrl.text.trim(),
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (widget.doc == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('service_catalog')
            .add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('service_catalog')
            .doc(widget.doc!.id)
            .update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.doc == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration:
                  const InputDecoration(labelText: 'Category Name *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration:
                  const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                  labelText: 'Base Price (LKR)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _iconCtrl,
              decoration: const InputDecoration(
                  labelText: 'Icon Name',
                  hintText: 'e.g. cleaning, plumbing'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: const Color(0xFF1B5E20),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
