import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension ContextExtensions on BuildContext {
  // Easy navigation helpers
  void goOnboarding() => go('/worker/onboard/nic');
  void goDashboard() => go('/worker/dashboard');
  void goAuth() => go('/auth');
  
  // Incident reporting from anywhere
  void reportIncident({
    required String reporterId,
    required UserType reporterType,
    String? jobId,
    String? subjectId,
  }) {
    go('/incident/report', extra: {
      'reporterId': reporterId,
      'reporterType': reporterType,
      'jobId': jobId,
      'subjectId': subjectId,
    });
  }
}

enum UserType { worker, customer, admin }