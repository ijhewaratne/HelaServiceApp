import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndRoute();
  }

  Future<void> _checkAuthAndRoute() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/auth');
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = userDoc.data();
      final userType = data?['userType'] as String? ?? 'unknown';
      final isOnboarded = data?['isOnboarded'] as bool? ?? false;

      // New user or unknown role — pick a role first
      if (userType == 'unknown' || !isOnboarded) {
        context.go('/auth/role-select');
        return;
      }

      switch (userType) {
        case 'customer':
          context.go('/customer/home');
          break;

        case 'admin':
        case 'superAdmin':
        case 'super_admin':
          context.go('/admin/dashboard');
          break;

        case 'worker':
          await _routeWorker(user.uid);
          break;

        default:
          context.go('/auth/role-select');
      }
    } catch (e) {
      if (mounted) context.go('/auth');
    }
  }

  Future<void> _routeWorker(String uid) async {
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (!workerDoc.exists) {
        context.go('/worker/onboard/nic');
        return;
      }

      final status = workerDoc.data()?['status'] as String? ?? 'pending';
      switch (status) {
        case 'approved':
          context.go('/worker/dashboard');
          break;
        case 'pending':
        case 'underReview':
        case 'trainingRequired':
          context.go('/worker/onboard/pending', extra: uid);
          break;
        case 'pendingDocs':
        case 'documentsSubmitted':
          context.go('/worker/onboard/documents', extra: uid);
          break;
        case 'contractPending':
          context.go('/worker/onboard/contract');
          break;
        default:
          context.go('/worker/onboard/nic');
      }
    } catch (e) {
      if (mounted) context.go('/worker/onboard/nic');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cleaning_services,
                size: 60,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'HelaService',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Trusted Home Services in Sri Lanka',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}