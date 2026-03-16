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
    await Future.delayed(Duration(seconds: 2)); // Minimum splash time
    
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      // Not logged in -> Phone Auth
      if (mounted) context.go('/auth');
      return;
    }
    
    // Check if worker profile exists and status
    try {
      final workerDoc = await FirebaseFirestore.instance
          .collection('worker_applications')
          .doc(user.uid)
          .get();
      
      if (!mounted) return;
      
      if (!workerDoc.exists) {
        // New worker -> Start onboarding
        context.go('/worker/onboard/nic');
      } else {
        final status = workerDoc.data()?['status'] as String?;
        
        switch (status) {
          case 'approved':
            context.go('/worker/dashboard');
            break;
          case 'underReview':
          case 'trainingRequired':
            context.go('/worker/onboard/pending', extra: user.uid);
            break;
          case 'pendingDocs':
            context.go('/worker/onboard/documents', extra: user.uid);
            break;
          default:
            context.go('/worker/onboard/nic');
        }
      }
    } catch (e) {
      // Error checking status, assume onboarding
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