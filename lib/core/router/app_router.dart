import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';
import '../../features/worker/presentation/pages/nic_input_page.dart';
import '../../features/worker/presentation/pages/service_selection_page.dart';
import '../../features/worker/presentation/pages/document_upload_page.dart';
import '../../features/worker/presentation/pages/verification_pending_page.dart';
import '../../features/worker/presentation/pages/online_toggle_page.dart';
import '../../features/worker/presentation/pages/job_offer_page.dart';
import '../../features/worker/presentation/pages/active_job_page.dart';
import '../../features/incident/presentation/pages/incident_report_page.dart';
import '../../features/admin/presentation/pages/emergency_dashboard.dart';
import '../../features/worker/domain/entities/worker_application.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  
  // Redirect logic: Handle auth state and onboarding completion
  redirect: (BuildContext context, GoRouterState state) async {
    final user = FirebaseAuth.instance.currentUser;
    final currentPath = state.uri.path;
    
    // Allow splash and auth screens always
    if (currentPath == '/' || currentPath == '/auth') {
      return null;
    }
    
    // Not logged in? -> Auth
    if (user == null) {
      return '/auth';
    }
    
    // Check if worker has completed onboarding (simplified check)
    // In production, check Firestore worker document status
    // If not onboarded, redirect to onboarding flow
    
    return null; // No redirect
  },
  
  routes: [
    // Splash/Loading
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    
    // Authentication
    GoRoute(
      path: '/auth',
      builder: (context, state) => const PhoneAuthPage(),
    ),
    
    // WORKER ONBOARDING FLOW
    GoRoute(
      path: '/worker/onboard/nic',
      builder: (context, state) => const NICInputPage(),
    ),
    GoRoute(
      path: '/worker/onboard/services',
      builder: (context, state) {
        final app = state.extra as WorkerApplication?;
        if (app == null) return const NICInputPage(); // Fallback
        return ServiceSelectionPage(application: app);
      },
    ),
    GoRoute(
      path: '/worker/onboard/documents',
      builder: (context, state) {
        final workerId = state.extra as String?;
        if (workerId == null) return const NICInputPage();
        return DocumentUploadPage(workerId: workerId);
      },
    ),
    GoRoute(
      path: '/worker/onboard/pending',
      builder: (context, state) {
        final workerId = state.extra as String?;
        return VerificationPendingPage(workerId: workerId ?? '');
      },
    ),
    
    // WORKER ACTIVE FLOW (Post-approval)
    GoRoute(
      path: '/worker/dashboard',
      builder: (context, state) => const OnlineTogglePage(),
    ),
    GoRoute(
      path: '/worker/job-offers',
      builder: (context, state) {
        final workerId = state.extra as String? ?? 
                        FirebaseAuth.instance.currentUser?.uid ?? '';
        return JobOfferPage(workerId: workerId);
      },
    ),
    GoRoute(
      path: '/worker/active-job/:jobId',
      builder: (context, state) {
        final jobId = state.pathParameters['jobId']!;
        return ActiveJobPage(jobId: jobId);
      },
    ),
    
    // INCIDENT REPORTING (Accessible from multiple contexts)
    GoRoute(
      path: '/incident/report',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>?;
        return IncidentReportPage(
          reporterId: params?['reporterId'] ?? '',
          reporterType: params?['reporterType'] ?? UserType.worker,
          jobId: params?['jobId'],
          subjectId: params?['subjectId'],
        );
      },
    ),
    
    // ADMIN/SAFETY COMMAND
    GoRoute(
      path: '/admin/emergency',
      builder: (context, state) => const EmergencyDashboard(),
    ),
    
    // CUSTOMER FLOW (Stub for future)
    GoRoute(
      path: '/customer/home',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Customer Home - To be implemented')),
      ),
    ),
  ],
  
  // Error handling
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Page Not Found',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(state.error?.toString() ?? 'Unknown error'),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);