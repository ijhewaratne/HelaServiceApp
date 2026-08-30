import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/customer_profile.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('customer_profiles')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return _EmptyProfile(uid: uid);
          }
          final profile = CustomerProfile.fromFirestore(snap.data!);
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _EmptyProfile extends StatelessWidget {
  final String uid;
  const _EmptyProfile({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No profile found'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showEditDialog(context, null, uid),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, CustomerProfile? profile, String uid) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _EditProfileDialog(profile: profile, uid: uid),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final CustomerProfile profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ProfileHeader(profile: profile),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoTile(Icons.phone, 'Phone', profile.mobileNumber),
                if (profile.email != null && profile.email!.isNotEmpty)
                  _InfoTile(Icons.email, 'Email', profile.email!),
                if (profile.defaultAddress != null)
                  _InfoTile(Icons.home, 'Default Address',
                      profile.defaultAddress!.fullAddress),
                if (profile.notes != null && profile.notes!.isNotEmpty)
                  _InfoTile(Icons.notes, 'Notes', profile.notes!),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.book_online,
                      color: Color(0xFF1B5E20)),
                  title: const Text('My Bookings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/customer/bookings'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent,
                      color: Color(0xFF1B5E20)),
                  title: const Text('Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/support'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.devices_outlined,
                      color: Color(0xFF1B5E20)),
                  title: const Text('Active Sessions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/account/sessions'),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                const SizedBox(height: 8),
                ListTile(
                  leading:
                      const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out',
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.go('/auth');
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final CustomerProfile profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B5E20),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white,
            backgroundImage: profile.profilePhotoUrl != null
                ? NetworkImage(profile.profilePhotoUrl!)
                : null,
            child: profile.profilePhotoUrl == null
                ? Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20)),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(profile.mobileNumber,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) =>
                  _EditProfileDialog(profile: profile, uid: profile.userId),
            ),
            icon:
                const Icon(Icons.edit, size: 16, color: Colors.white),
            label: const Text('Edit Profile',
                style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12,
                        color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final CustomerProfile? profile;
  final String uid;
  const _EditProfileDialog({this.profile, required this.uid});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile?.fullName ?? '');
    _emailCtrl = TextEditingController(text: widget.profile?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final col = FirebaseFirestore.instance.collection('customer_profiles');
      if (widget.profile == null || widget.profile!.isEmpty) {
        final docRef = col.doc(widget.uid);
        await docRef.set({
          'id': widget.uid,
          'userId': widget.uid,
          'fullName': _nameCtrl.text.trim(),
          'mobileNumber':
              FirebaseAuth.instance.currentUser?.phoneNumber ?? '',
          'email': _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await col.doc(widget.uid).update({
          'fullName': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
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
      title: Text(
          widget.profile == null ? 'Create Profile' : 'Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email (optional)'),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
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
