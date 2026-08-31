import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Soft-launch MFA enrollment (see docs/SPEC_DECISIONS.md): admins can
/// enroll here now, but nothing in the app requires it yet. Once a user
/// enrolls, Firebase Auth itself starts requiring the second factor on
/// every future sign-in for that account — that part is not optional or
/// configurable by us, so the sign-in flow (phone_auth_page.dart) already
/// handles the resulting challenge.
class MfaEnrollmentScreen extends StatefulWidget {
  const MfaEnrollmentScreen({super.key});

  @override
  State<MfaEnrollmentScreen> createState() => _MfaEnrollmentScreenState();
}

class _MfaEnrollmentScreenState extends State<MfaEnrollmentScreen> {
  List<MultiFactorInfo> _enrolledFactors = [];
  bool _loading = true;

  // Enrollment-in-progress state
  TotpSecret? _pendingSecret;
  String? _pendingQrUrl;
  final _codeController = TextEditingController();
  bool _enrolling = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    final factors = await user?.multiFactor.getEnrolledFactors() ?? [];
    if (!mounted) return;
    setState(() {
      _enrolledFactors = factors;
      _loading = false;
    });
  }

  Future<void> _startEnrollment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _enrolling = true);
    try {
      final session = await user.multiFactor.getSession();
      final secret = await TotpMultiFactorGenerator.generateSecret(session);
      final qrUrl = await secret.generateQrCodeUrl(
        accountName: user.email ?? user.phoneNumber ?? user.uid,
        issuer: 'HelaService',
      );
      if (!mounted) return;
      setState(() {
        _pendingSecret = secret;
        _pendingQrUrl = qrUrl;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start enrollment: $e')));
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  Future<void> _completeEnrollment() async {
    final user = FirebaseAuth.instance.currentUser;
    final secret = _pendingSecret;
    if (user == null || secret == null) return;
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter the 6-digit code')));
      return;
    }

    setState(() => _enrolling = true);
    try {
      final assertion =
          await TotpMultiFactorGenerator.getAssertionForEnrollment(
            secret,
            code,
          );
      await user.multiFactor.enroll(
        assertion,
        displayName: 'Authenticator app',
      );
      if (!mounted) return;
      setState(() {
        _pendingSecret = null;
        _pendingQrUrl = null;
        _codeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-factor authentication enabled')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid code — try again ($e)')));
    } finally {
      if (mounted) setState(() => _enrolling = false);
    }
  }

  Future<void> _unenroll(MultiFactorInfo factor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove two-factor authentication?'),
        content: const Text(
          'Your account will only require your phone OTP to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    await user?.multiFactor.unenroll(multiFactorInfo: factor);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Two-Factor Authentication')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _pendingSecret != null
                  ? _buildEnrollmentStep()
                  : _buildStatusView(),
            ),
    );
  }

  Widget _buildStatusView() {
    if (_enrolledFactors.isNotEmpty) {
      return ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Colors.green.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Two-factor authentication is enabled'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._enrolledFactors.map(
            (factor) => Card(
              child: ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(factor.displayName ?? 'Authenticator app'),
                trailing: TextButton(
                  onPressed: () => _unenroll(factor),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add a second step to your sign-in using any authenticator app '
          '(Google Authenticator, Authy, 1Password, etc.). This is optional '
          'for now, but strongly recommended for admin accounts.',
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _enrolling ? null : _startEnrollment,
          icon: _enrolling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.shield_outlined),
          label: const Text('Enable two-factor authentication'),
        ),
      ],
    );
  }

  Widget _buildEnrollmentStep() {
    return ListView(
      children: [
        const Text(
          'Scan this code with your authenticator app, or enter the key '
          'manually, then type the 6-digit code it shows.',
        ),
        const SizedBox(height: 20),
        Center(
          child: QrImageView(
            data: _pendingQrUrl!,
            size: 200,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: SelectableText(
            _pendingSecret!.secretKey,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: '6-digit code',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _enrolling
                    ? null
                    : () => setState(() {
                        _pendingSecret = null;
                        _pendingQrUrl = null;
                      }),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _enrolling ? null : _completeEnrollment,
                child: _enrolling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verify & Enable'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
