import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/worker.dart';

class WorkerProfileEditScreen extends StatefulWidget {
  const WorkerProfileEditScreen({super.key});

  @override
  State<WorkerProfileEditScreen> createState() =>
      _WorkerProfileEditScreenState();
}

class _WorkerProfileEditScreenState extends State<WorkerProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  double _serviceRadius = 10.0;
  bool _loading = true;
  bool _saving = false;
  String? _workerId;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  Future<void> _loadWorker() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        final w = Worker.fromJson(doc.data() as Map<String, dynamic>);
        _workerId = uid;
        _businessNameCtrl.text = w.businessName ?? '';
        _bioCtrl.text = w.bio ?? '';
        _experienceCtrl.text = w.experienceYears?.toString() ?? '';
        _districtCtrl.text = w.district;
        _serviceRadius = w.serviceRadiusKm;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _bioCtrl.dispose();
    _experienceCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _workerId == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('workers')
          .doc(_workerId!)
          .update({
        'businessName': _businessNameCtrl.text.trim().isEmpty
            ? null
            : _businessNameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        'experienceYears': _experienceCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_experienceCtrl.text.trim()),
        'district': _districtCtrl.text.trim(),
        'serviceRadiusKm': _serviceRadius,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop();
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _SectionHeader('Business Information'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessNameCtrl,
                    decoration: _inputDecoration(
                        'Business Name (optional)',
                        'e.g. Saman\'s Plumbing Services',
                        Icons.business),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _districtCtrl,
                    decoration: _inputDecoration(
                        'District', 'e.g. Colombo, Kandy', Icons.location_on),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your district'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader('About You'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: _inputDecoration(
                        'Bio', 'Describe your experience and specialties...',
                        Icons.person),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _experienceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                        'Years of Experience', 'e.g. 5', Icons.work_history),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 0 || n > 50) {
                        return 'Enter a valid number (0-50)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader('Service Radius'),
                  const SizedBox(height: 4),
                  Text(
                    'You will only receive job requests within ${_serviceRadius.toStringAsFixed(0)} km of your home location.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  Slider(
                    value: _serviceRadius,
                    min: 2,
                    max: 50,
                    divisions: 24,
                    label: '${_serviceRadius.toStringAsFixed(0)} km',
                    activeColor: const Color(0xFF1B5E20),
                    onChanged: (v) =>
                        setState(() => _serviceRadius = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('2 km',
                          style: TextStyle(color: Colors.grey[500])),
                      Text('${_serviceRadius.toStringAsFixed(0)} km',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20))),
                      Text('50 km',
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_saving) const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(fontSize: 16)),
                    ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(
      String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1B5E20)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}
