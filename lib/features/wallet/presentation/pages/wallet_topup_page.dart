import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../injection_container.dart';
import '../../../../core/config/theme.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Wallet Top-Up Page (10.1)
// Calls generatePayHereUrl CF → opens browser → webhook credits wallet
// ──────────────────────────────────────────────────────────────────────────────

class WalletTopUpPage extends StatefulWidget {
  const WalletTopUpPage({super.key});

  @override
  State<WalletTopUpPage> createState() => _WalletTopUpPageState();
}

class _WalletTopUpPageState extends State<WalletTopUpPage> {
  static const _presets = [500, 1000, 2000, 5000, 10000];
  int? _selectedPreset;
  final _customCtrl = TextEditingController();
  bool _isCustom = false;
  bool _loading = false;
  double? _currentBalance;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await sl<FirebaseFirestore>()
        .collection('wallets')
        .doc(uid)
        .get();
    if (snap.exists && mounted) {
      setState(() {
        // balance is stored in integer cents.
        _currentBalance =
            ((snap.data()?['balance'] as num?)?.toInt() ?? 0) / 100;
      });
    }
  }

  int get _selectedAmount {
    if (_isCustom) {
      return int.tryParse(_customCtrl.text.trim()) ?? 0;
    }
    return _selectedPreset ?? 0;
  }

  // Gate 0: in-app payments (PayHere) are disabled for this MVP release —
  // see functions/src/payhereWebhook.ts's PAYMENTS_ENABLED flag, which is
  // the authoritative, server-side enforcement (generatePayHereUrl now
  // throws regardless of this client-side check). This short-circuit exists
  // so a user sees a clear, honest message instead of a raw error.
  static const bool _paymentsEnabled = false;

  Future<void> _initiateTopUp() async {
    if (!_paymentsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wallet top-up is not available in this release.'),
        ),
      );
      return;
    }

    final amount = _selectedAmount;
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum top-up is LKR 100.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    setState(() => _loading = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'generatePayHereUrl',
      );
      final result = await callable.call<Map<String, dynamic>>({
        'type': 'topup',
        'amount': amount,
        'customerName': user.displayName ?? 'Customer',
        'customerPhone': user.phoneNumber ?? '0770000000',
        'customerEmail': user.email,
      });

      final url = result.data['url'] as String;
      final uri = Uri.parse(url);

      if (!await canLaunchUrl(uri)) {
        throw Exception('Cannot open browser');
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Complete payment in your browser. '
              'Wallet will be updated automatically.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initiate payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Up Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentBalance == null
                        ? 'Loading…'
                        : 'LKR ${_currentBalance!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Select amount',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),

            // Preset grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: _presets.length,
              itemBuilder: (_, i) {
                final amt = _presets[i];
                final sel = !_isCustom && _selectedPreset == amt;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedPreset = amt;
                    _isCustom = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primaryColor
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel
                            ? AppTheme.primaryColor
                            : Theme.of(context).colorScheme.outline,
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      'LKR $amt',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Custom amount
            GestureDetector(
              onTap: () => setState(() {
                _isCustom = true;
                _selectedPreset = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isCustom
                        ? AppTheme.primaryColor
                        : Theme.of(context).colorScheme.outline,
                    width: _isCustom ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _customCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Custom amount (LKR)',
                    border: InputBorder.none,
                    prefixText: 'LKR ',
                  ),
                  onTap: () => setState(() {
                    _isCustom = true;
                    _selectedPreset = null;
                  }),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Payment methods info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accepted payment methods',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: const [
                      _MethodChip(
                        label: 'Visa / MasterCard',
                        icon: Icons.credit_card,
                      ),
                      _MethodChip(
                        label: 'Bank Transfer',
                        icon: Icons.account_balance,
                      ),
                      _MethodChip(label: 'eZCash', icon: Icons.phone_android),
                      _MethodChip(label: 'mCash', icon: Icons.phone_iphone),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (_loading || _selectedAmount < 100)
                    ? null
                    : _initiateTopUp,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _selectedAmount >= 100
                            ? 'Pay LKR $_selectedAmount via PayHere'
                            : 'Select an amount',
                      ),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Secured by PayHere · Funds appear within 5 minutes.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MethodChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }
}
