import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../injection_container.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';

// Worker imports
import '../../features/worker/presentation/pages/gold_tier_training_page.dart';
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

// Auth screens
import '../../features/auth/presentation/screens/role_select_screen.dart';

// Customer imports
import '../../features/customer/presentation/screens/customer_home_screen.dart';
import '../../features/customer/presentation/screens/booking_form_screen.dart';
import '../../features/customer/presentation/screens/live_tracking_page.dart';
import '../../features/customer/presentation/screens/location_permission_screen.dart';
import '../../features/customer/presentation/screens/provider_profile_screen.dart';
import '../../features/customer/presentation/screens/my_bookings_screen.dart';
import '../../features/customer/presentation/screens/booking_detail_screen.dart';
import '../../features/customer/presentation/screens/review_provider_screen.dart';
import '../../features/customer/presentation/screens/customer_profile_screen.dart';
import '../../features/booking/presentation/pages/booking_flow_screen.dart';
import '../../features/booking/presentation/pages/booking_confirmation_page.dart';
import '../../features/booking/domain/entities/booking.dart' as booking_entity;

// Admin imports
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_bookings_screen.dart';
import '../../features/admin/presentation/screens/admin_incidents_screen.dart';
import '../../features/admin/presentation/screens/admin_workers_screen.dart';
import '../../features/admin/presentation/screens/admin_customers_screen.dart';
import '../../features/admin/presentation/screens/admin_review_moderation_screen.dart';
import '../../features/admin/presentation/screens/admin_dispute_screen.dart';
import '../../features/admin/presentation/screens/admin_audit_log_screen.dart';
import '../../features/admin/presentation/screens/admin_user_management_screen.dart';
import '../../features/admin/presentation/screens/admin_category_management_screen.dart';
import '../../features/admin/presentation/pages/emergency_dashboard.dart';
import '../../features/admin/presentation/viewmodels/admin_dashboard_viewmodel.dart';

// Worker screens
import '../../features/worker/presentation/screens/worker_profile_edit_screen.dart';
import '../../features/worker/presentation/screens/worker_reviews_screen.dart';

// Payment / Wallet
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/payment/presentation/pages/payout_history_page.dart';
import '../../features/wallet/presentation/pages/wallet_topup_page.dart';

// Shared
import '../../features/incident/presentation/pages/incident_report_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/support/presentation/pages/support_ticket_page.dart';
import '../../features/support/presentation/pages/admin_support_screen.dart';
import '../../features/admin/presentation/screens/admin_revenue_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

Widget _withAdminViewModel(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => sl<AdminViewModel>(),
    child: child,
  );
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',

  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final currentPath = state.uri.path;

    // Always allow splash and auth screens
    if (currentPath == '/' || currentPath == '/auth' ||
        currentPath == '/auth/role-select') return null;

    if (user == null) return '/auth';

    // Redirect to role-select only when the user has not chosen a role yet.
    // Workers have isOnboarded=false throughout their KYC process, so we
    // must not use isOnboarded as the gate for them — only userType matters.
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userType = doc.data()?['userType'] as String? ?? 'unknown';
      if (userType == 'unknown') {
        if (!currentPath.startsWith('/worker/onboard') &&
            !currentPath.startsWith('/auth')) {
          return '/auth/role-select';
        }
      }
    } catch (_) {
      // Firestore unavailable — force re-auth rather than granting silent access
      return '/auth';
    }

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
    GoRoute(
      path: '/auth/role-select',
      builder: (context, state) => const RoleSelectScreen(),
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
      path: '/worker/training',
      builder: (context, state) => const GoldTierTrainingPage(),
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
      path: '/customer/booking-confirm',
      builder: (context, state) {
        final booking = state.extra as booking_entity.Booking;
        return BookingConfirmationPage(booking: booking);
      },
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
    GoRoute(
      path: '/customer/location-permission',
      builder: (context, state) => const LocationPermissionScreen(),
    ),
    GoRoute(
      path: '/customer/provider/:providerId',
      builder: (context, state) {
        final providerId = state.pathParameters['providerId']!;
        return ProviderProfileScreen(providerId: providerId);
      },
    ),
    GoRoute(
      path: '/customer/bookings',
      builder: (context, state) => const MyBookingsScreen(),
    ),
    GoRoute(
      path: '/customer/bookings/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId']!;
        final booking = state.extra as booking_entity.Booking?;
        return BookingDetailScreen(
            bookingId: bookingId, initialBooking: booking);
      },
    ),
    GoRoute(
      path: '/customer/review/:requestId',
      builder: (context, state) {
        final requestId = state.pathParameters['requestId']!;
        final booking = state.extra as booking_entity.Booking?;
        return ReviewProviderScreen(
            requestId: requestId, booking: booking);
      },
    ),
    GoRoute(
      path: '/customer/profile',
      builder: (context, state) => const CustomerProfileScreen(),
    ),

    // ── Worker Profile Routes ─────────────────────────────────────────────────
    GoRoute(
      path: '/worker/profile/edit',
      builder: (context, state) => const WorkerProfileEditScreen(),
    ),
    GoRoute(
      path: '/worker/reviews',
      builder: (context, state) => const WorkerReviewsScreen(),
    ),

    // ── Admin Routes ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/workers',
      builder: (context, state) => _withAdminViewModel(
        const AdminWorkersScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/verify/:workerId',
      builder: (context, state) => _withAdminViewModel(
        const AdminWorkersScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/bookings',
      builder: (context, state) => _withAdminViewModel(
        const AdminBookingsScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/incidents',
      builder: (context, state) => _withAdminViewModel(
        const AdminIncidentsScreen(),
      ),
    ),
    GoRoute(
      path: '/admin/dispatch',
      builder: (context, state) => const EmergencyDashboard(),
    ),
    GoRoute(
      path: '/admin/revenue',
      builder: (context, state) => const AdminRevenueScreen(),
    ),
    GoRoute(
      path: '/admin/customers',
      builder: (context, state) => const AdminCustomersScreen(),
    ),
    GoRoute(
      path: '/admin/reviews',
      builder: (context, state) => const AdminReviewModerationScreen(),
    ),
    GoRoute(
      path: '/admin/disputes',
      builder: (context, state) => const AdminDisputeScreen(),
    ),
    GoRoute(
      path: '/admin/audit-log',
      builder: (context, state) => const AdminAuditLogScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUserManagementScreen(),
    ),
    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => const AdminCategoryManagementScreen(),
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
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportTicketPage(),
    ),
    GoRoute(
      path: '/admin/support',
      builder: (context, state) => const AdminSupportScreen(),
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
