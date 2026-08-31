import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../../injection_container.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/session_repository.dart';

/// FR-AUTH-007 — view and (collectively) revoke active sessions. Firebase
/// Auth cannot revoke a single device's session, only every one at once
/// except the device that asks — this screen is upfront about that instead
/// of implying per-device control it can't actually deliver.
class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  late Future<List<UserSession>> _future;
  bool _signingOutOthers = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UserSession>> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final result = await sl<SessionRepository>().getSessions(uid);
    return result.fold((_) => [], (sessions) => sessions);
  }

  Future<void> _signOutOtherDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out other devices?'),
        content: const Text(
          'This signs you out everywhere except this device. Firebase does '
          "not support signing out a single other device — it's all of "
          'them or none.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign out others'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _signingOutOthers = true);
    final result = await sl<SessionRepository>().signOutOtherDevices(uid);
    if (!mounted) return;

    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: ${failure.message}'))),
      (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Other devices signed out'))),
    );
    setState(() {
      _signingOutOthers = false;
      _future = _load();
    });
  }

  String _platformLabel(String platform) {
    switch (platform) {
      case 'android':
        return 'Android';
      case 'iOS':
        return 'iPhone/iPad';
      case 'web':
        return 'Web browser';
      default:
        return platform;
    }
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'android':
        return Icons.phone_android;
      case 'iOS':
        return Icons.phone_iphone;
      case 'web':
        return Icons.computer;
      default:
        return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Sessions')),
      body: FutureBuilder<List<UserSession>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final sessions = snap.data ?? [];
          final activeSessions = sessions
              .where((s) => s.revokedAt == null)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeSessions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      'No session history yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                )
              else
                ...activeSessions.map(
                  (session) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(_platformIcon(session.platform)),
                      title: Row(
                        children: [
                          Text(_platformLabel(session.platform)),
                          if (session.isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'This device',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        'Last active ${DateFormat.yMMMd().add_jm().format(session.lastActiveAt)}',
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (activeSessions.length > 1)
                ElevatedButton.icon(
                  onPressed: _signingOutOthers ? null : _signOutOtherDevices,
                  icon: _signingOutOthers
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Sign out other devices'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
