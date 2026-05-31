import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';

// Worker imports
import '../../features/worker/presentation/pages/nic_input_page.dart';
import '../../features/worker/presentation/pages/document_upload_page.dart';
import '../../features/worker/presentation/pages/verification_pending_page.dart';
import '../../features/worker/presentation/screens/contract_acceptance_page.dart';
import '../../features/worker/presentation/screens/online_toggle_page.dart';
import '../../features/worker/presentation/pages/job_offer_page.dart';
import '../../features/worker/presentation/pages/active_job_page.dart';
import '../../features/worker/presentation/pages/worker_dashboard_screen.dart';
import '../../features/worker/presentation/pages/bank_account_page.dart';
import '../../features/worker/presentation/pages/blue_tier_upgrade_page.dart';

// Customer imports
import '../../features/customer/presentation/screens/customer_home_screen.dart';
import '../../features/customer/presentation/screens/booking_form_screen.dart';
import '../../features/customer/presentation/screens/live_tracking_page.dart';
import '../../features/booking/presentation/pages/booking_flow_screen.dart';

// Admin imports
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_workers_screen.dart';
import '../../features/admin/presentation/pages/emergency_dashboard.dart';

// Payment / Wallet
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/payment/presentation/pages/payout_history_page.dart';
import '../../features/wallet/presentation/pages/wallet_topup_page.dart';

// Shared
import '../../features/incident/presentation/pages/incident_report_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',

  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final currentPath = state.uri.path;

    if (currentPath == '/' || currentPath == '/auth') return null;
    if (user == null) return '/auth';
    return null;
  },

  routes: [
    // ── Splash & Auth ────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const PhoneAuthPage(),
    ),

    // ── Worker Routes ────────────────────────────────────────────────────────
    GoRoute(
      path: '/worker/onboard/nic',
      builder: (context, state) => NICInputPage(),
    ),
    GoRoute(
      path: '/worker/onboard/services',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Service Selection')),
      ),
    ),
    GoRoute(
      path: '/worker/onboard/documents',
      builder: (context, state) {
        final workerId = state.extra as String? ??
            FirebaseAuth.instance.currentUser?.uid ?? '';
        return DocumentUploadPage(workerId: workerId);
      },
    ),
    GoRoute(
      path: '/worker/onboard/pending',
      builder: (context, state) {
        final workerId = state.extra as String? ??
            FirebaseAuth.instance.currentUser?.uid ?? '';
        return VerificationPendingPage(workerId: workerId);
      },
    ),
    GoRoute(
      path: '/worker/onboard/contract',
      builder: (context, state) => const ContractAcceptancePage(),
    ),
    GoRoute(
      path: '/worker/dashboard',
      builder: (context, state) => const WorkerDashboardScreen(),
    ),
    GoRoute(
      path: '/worker/status',
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
    GoRoute(
      path: '/worker/bank-account',
      builder: (context, state) => const BankAccountPage(),
    ),
    GoRoute(
      path: '/worker/blue-tier',
      builder: (context, state) => const BlueTierUpgradePage(),
    ),
    GoRoute(
      path: '/worker/payouts',
      builder: (context, state) => const PayoutHistoryPage(),
    ),

    // ── Wallet Routes ────────────────────────────────────────────────────────
    GoRoute(
      path: '/wallet/topup',
      builder: (context, state) => const WalletTopUpPage(),
    ),

    // ── Customer Routes ──────────────────────────────────────────────────────
    GoRoute(
      path: '/customer/home',
      builder: (context, state) => const CustomerHomeScreen(),
    ),
    GoRoute(
      path: '/customer/book',
      builder: (context, state) => const BookingFlowScreen(),
    ),
    GoRoute(
      path: '/customer/book/legacy',
      builder: (context, state) => const BookingFormScreen(),
    ),
    GoRoute(
      path: '/customer/track/:jobId',
      builder: (context, state) => const LiveTrackingPage(),
    ),
    GoRoute(
      path: '/customer/payment/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        final params = state.extra as Map<String, dynamic>?;
        return PaymentPage(
          bookingId: bookingId,
          amount: (params?['amount'] as num?)?.toInt() ?? 0,
          description: params?['description'] as String?,
        );
      },
    ),

    // ── Admin Routes ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/verify/:workerId',
      builder: (context, state) => const AdminWorkersScreen(),
    ),
    GoRoute(
      path: '/admin/dispatch',
      builder: (context, state) => const EmergencyDashboard(),
    ),

    // ── Shared Routes ────────────────────────────────────────────────────────
    GoRoute(
      path: '/chat/:jobId',
      builder: (context, state) {
        final jobId = state.pathParameters['jobId']!;
        return ChatPage(jobId: jobId);
      },
    ),
    GoRoute(
      path: '/incident/report',
      builder: (context, state) {
        final params = state.extra as Map<String, dynamic>?;
        return IncidentReportPage(
          reporterId: (params?['reporterId'] as String?) ?? '',
          reporterType: (params?['reporterType'] as String?) ?? 'worker',
          jobId: params?['jobId'] as String?,
        );
      },
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);
