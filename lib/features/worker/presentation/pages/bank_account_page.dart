import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Worker Bank Account Setup — stored in workers/{id}/private_data/bank_account
// Required before weekly payouts can be processed.
// ──────────────────────────────────────────────────────────────────────────────

class BankAccountPage extends StatefulWidget {
  const BankAccountPage({super.key});

  @override
  State<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends State<BankAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  String _bankName = 'Commercial Bank';
  String _branchName = '';
  bool _loading = false;
  bool _saved = false;

  static const _sriLankanBanks = [
    'Bank of Ceylon',
    'Commercial Bank',
    'Hatton National Bank',
    'National Savings Bank',
    'Peoples Bank',
    'Sampath Bank',
    'Seylan Bank',
    'Union Bank',
    'Pan Asia Banking Corporation',
    'Nations Trust Bank',
    'DFCC Bank',
    'NDB Bank',
    'Amana Bank',
    'MCB Bank',
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await sl<FirebaseFirestore>()
        .collection('workers')
        .doc(uid)
        .collection('private_data')
        .doc('bank_account')
        .get();
    if (snap.exists && mounted) {
      final data = snap.data()!;
      setState(() {
        _bankName = data['bankName'] as String? ?? _bankName;
        _holderController.text = data['accountHolder'] as String? ?? '';
        _accountController.text = data['accountNumber'] as String? ?? '';
        _branchName = data['branchName'] as String? ?? '';
        _saved = true;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      await sl<FirebaseFirestore>()
          .collection('workers')
          .doc(uid)
          .collection('private_data')
          .doc('bank_account')
          .set({
        'bankName': _bankName,
        'accountHolder': _holderController.text.trim(),
        'accountNumber': _accountController.text.trim(),
        'branchName': _branchName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Mirror bank name to main worker doc for payout processing
      await sl<FirebaseFirestore>()
          .collection('workers')
          .doc(uid)
          .update({'bankAccountSet': true});
      setState(() => _saved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank account saved. You\'re ready for payouts.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payout Bank Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.infoColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: AppTheme.infoColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your bank details are encrypted and stored securely. '
                        'They are only used for weekly payout transfers (every Monday, min LKR 1,000).',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppTheme.infoColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Bank', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _bankName,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance),
                ),
                items: _sriLankanBanks
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _bankName = v);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Branch name',
                  hintText: 'e.g. Colombo Fort',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (v) => _branchName = v,
                initialValue: _branchName,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _holderController,
                decoration: const InputDecoration(
                  labelText: 'Account holder name *',
                  hintText: 'Exactly as shown on bank passbook',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Required'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Account number *',
                  hintText: '0000000000',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 8) return 'Enter full account number';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              if (_saved)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.successColor.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppTheme.successColor, size: 16),
                      SizedBox(width: 8),
                      Text('Bank account on file',
                          style: TextStyle(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_saved ? 'Update Bank Account' : 'Save Bank Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
