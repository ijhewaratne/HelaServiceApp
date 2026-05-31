import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Blue Tier Upgrade Page (11.2.x)
// Workers submit: police clearance + 2 reference contacts
// Admin reviews and approves via admin dashboard
// ──────────────────────────────────────────────────────────────────────────────

class BlueTierUpgradePage extends StatefulWidget {
  const BlueTierUpgradePage({super.key});

  @override
  State<BlueTierUpgradePage> createState() => _BlueTierUpgradePageState();
}

class _BlueTierUpgradePageState extends State<BlueTierUpgradePage> {
  File? _clearanceFront;
  File? _clearanceBack;
  DateTime? _clearanceExpiry;
  final _ref1NameCtrl = TextEditingController();
  final _ref1PhoneCtrl = TextEditingController();
  final _ref1RelationCtrl = TextEditingController();
  final _ref2NameCtrl = TextEditingController();
  final _ref2PhoneCtrl = TextEditingController();
  final _ref2RelationCtrl = TextEditingController();
  bool _submitting = false;
  bool _alreadySubmitted = false;

  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkExistingSubmission();
  }

  Future<void> _checkExistingSubmission() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await sl<FirebaseFirestore>()
        .collection('worker_verifications')
        .doc(uid)
        .get();
    if (snap.exists && mounted) {
      final data = snap.data()!;
      final tier = data['requestedTier'] as String? ?? '';
      if (tier == 'blue' || data['currentTier'] == 'blue') {
        setState(() => _alreadySubmitted = true);
      }
    }
  }

  Future<File?> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) setState(() => _clearanceExpiry = date);
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      final ref = sl<FirebaseStorage>().ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clearanceFront == null || _clearanceExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload police clearance and set expiry date.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final frontUrl = await _uploadFile(
          _clearanceFront!, 'workers/$uid/police_clearance_front.jpg');
      final backUrl = _clearanceBack != null
          ? await _uploadFile(
              _clearanceBack!, 'workers/$uid/police_clearance_back.jpg')
          : null;

      await sl<FirebaseFirestore>()
          .collection('worker_verifications')
          .doc(uid)
          .set({
        'workerId': uid,
        'requestedTier': 'blue',
        'status': 'pending_review',
        'policeClearance': {
          'frontUrl': frontUrl,
          'backUrl': backUrl,
          'expiryDate': _clearanceExpiry != null
              ? _clearanceExpiry!.toIso8601String()
              : null,
          'uploadedAt': FieldValue.serverTimestamp(),
        },
        'references': [
          {
            'name': _ref1NameCtrl.text.trim(),
            'phone': _ref1PhoneCtrl.text.trim(),
            'relation': _ref1RelationCtrl.text.trim(),
            'verificationStatus': 'pending',
          },
          {
            'name': _ref2NameCtrl.text.trim(),
            'phone': _ref2PhoneCtrl.text.trim(),
            'relation': _ref2RelationCtrl.text.trim(),
            'verificationStatus': 'pending',
          },
        ],
        'submittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update main worker doc
      await sl<FirebaseFirestore>()
          .collection('workers')
          .doc(uid)
          .update({
        'verificationStatus': 'pending_review',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _submitting = false;
        _alreadySubmitted = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Application submitted. Admin will review within 3–5 business days.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _ref1NameCtrl.dispose();
    _ref1PhoneCtrl.dispose();
    _ref1RelationCtrl.dispose();
    _ref2NameCtrl.dispose();
    _ref2PhoneCtrl.dispose();
    _ref2RelationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Blue Tier')),
      body: _alreadySubmitted ? _SubmittedView() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tier info banner
            _TierInfoBanner(),
            const SizedBox(height: 24),

            // ── Police clearance ──
            _SectionHeader(
              icon: Icons.verified_user_outlined,
              title: 'Police Clearance Certificate',
              subtitle: 'Issued within the last 12 months',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PhotoUploadBox(
                    label: 'Front *',
                    file: _clearanceFront,
                    onTap: () async {
                      final f = await _pickImage();
                      if (f != null) setState(() => _clearanceFront = f);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoUploadBox(
                    label: 'Back (optional)',
                    file: _clearanceBack,
                    onTap: () async {
                      final f = await _pickImage();
                      if (f != null) setState(() => _clearanceBack = f);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _clearanceExpiry == null
                          ? 'Set expiry date *'
                          : '${_clearanceExpiry!.day}/${_clearanceExpiry!.month}/${_clearanceExpiry!.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _clearanceExpiry != null
                          ? AppTheme.successColor
                          : null,
                    ),
                    onPressed: _pickExpiry,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Reference 1 ──
            _SectionHeader(
              icon: Icons.person_search_outlined,
              title: 'Reference Contact 1',
              subtitle: 'Previous employer or supervisor',
            ),
            const SizedBox(height: 12),
            _ReferenceFields(
              nameCtrl: _ref1NameCtrl,
              phoneCtrl: _ref1PhoneCtrl,
              relationCtrl: _ref1RelationCtrl,
              number: 1,
            ),

            const SizedBox(height: 24),

            // ── Reference 2 ──
            _SectionHeader(
              icon: Icons.person_search_outlined,
              title: 'Reference Contact 2',
              subtitle: 'Second previous employer or supervisor',
            ),
            const SizedBox(height: 12),
            _ReferenceFields(
              nameCtrl: _ref2NameCtrl,
              phoneCtrl: _ref2PhoneCtrl,
              relationCtrl: _ref2RelationCtrl,
              number: 2,
            ),

            const SizedBox(height: 32),

            // Consent note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'By submitting, you consent to HelaService contacting your references to verify your background. '
                'All documents are stored securely and used only for verification purposes.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.warningColor),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit for Blue Tier Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ──────────────────────────────────────────────────────────────────────────────

class _TierInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.workspace_premium,
              color: Color(0xFF3B82F6), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Blue Tier Benefits',
                    style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '• +10% hourly rate multiplier\n'
                  '• Access to Elder Companionship & Babysitting services\n'
                  '• Blue badge on your worker profile',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: const Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _PhotoUploadBox extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;

  const _PhotoUploadBox({
    required this.label,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: file != null
              ? AppTheme.successColor.withValues(alpha: 0.06)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null
                ? AppTheme.successColor
                : Theme.of(context).colorScheme.outline,
            width: file != null ? 2 : 1,
          ),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(file!, fit: BoxFit.cover),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined,
                      color: AppTheme.primaryColor),
                  const SizedBox(height: 4),
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.primaryColor),
                      textAlign: TextAlign.center),
                ],
              ),
      ),
    );
  }
}

class _ReferenceFields extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController relationCtrl;
  final int number;

  const _ReferenceFields({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.relationCtrl,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Full name *',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: phoneCtrl,
          decoration: const InputDecoration(
            labelText: 'Phone number *',
            hintText: '07X XXX XXXX',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (v.trim().length < 9) return 'Enter valid phone number';
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: relationCtrl,
          decoration: const InputDecoration(
            labelText: 'Relationship / Role',
            hintText: 'e.g. Previous employer, supervisor',
            prefixIcon: Icon(Icons.work_outline),
          ),
        ),
      ],
    );
  }
}

class _SubmittedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top_rounded,
                size: 72, color: AppTheme.warningColor),
            const SizedBox(height: 20),
            Text('Application Under Review',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'Your Blue Tier application has been submitted.\n\n'
              'Our team will verify your documents and contact your references within 3–5 business days.\n\n'
              'You\'ll receive a notification when your status is updated.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
