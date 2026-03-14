import 'package:go_router/go_router.dart';
import '../../features/customer/presentation/screens/customer_home_screen.dart';
import '../../features/customer/presentation/screens/booking_form_screen.dart';
import '../../features/customer/presentation/screens/booking_summary_screen.dart';
import '../../features/customer/presentation/screens/zone_checker_page.dart';
import '../../features/customer/presentation/screens/service_selection_page.dart';
import '../../features/customer/presentation/screens/worker_matching_page.dart';
import '../../features/customer/presentation/screens/live_tracking_page.dart';
import '../../features/worker/presentation/screens/worker_home_screen.dart';
import '../../features/worker/presentation/screens/worker_profile_screen.dart';
import '../../features/worker/presentation/screens/worker_documents_screen.dart';
import '../../features/worker/presentation/screens/worker_availability_screen.dart';
import '../../features/worker/presentation/screens/nic_verification_page.dart';
import '../../features/worker/presentation/screens/skill_selection_page.dart';
import '../../features/worker/presentation/screens/training_video_page.dart';
import '../../features/worker/presentation/screens/contract_acceptance_page.dart';
import '../../features/worker/presentation/screens/online_toggle_page.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_workers_screen.dart';
import '../../features/admin/presentation/screens/admin_bookings_screen.dart';
import '../../features/admin/presentation/screens/admin_incidents_screen.dart';

// New BLoC-based onboarding pages
import '../../features/worker/presentation/pages/nic_input_page.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/role_select_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpScreen(),
    ),
    GoRoute(
      path: '/role-select',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/customer',
      builder: (context, state) => const CustomerHomeScreen(),
    ),
    GoRoute(
      path: '/customer/book/zone',
      builder: (context, state) => const ZoneCheckerPage(),
    ),
    GoRoute(
      path: '/customer/book/services',
      builder: (context, state) => const ServiceSelectionPage(),
    ),
    GoRoute(
      path: '/customer/book/form',
      builder: (context, state) => const BookingFormScreen(),
    ),
    GoRoute(
      path: '/customer/book/summary',
      builder: (context, state) => const BookingSummaryScreen(),
    ),
    GoRoute(
      path: '/customer/book/matching',
      builder: (context, state) => const WorkerMatchingPage(),
    ),
    GoRoute(
      path: '/customer/tracking',
      builder: (context, state) => const LiveTrackingPage(),
    ),
    GoRoute(
      path: '/worker',
      builder: (context, state) => const WorkerHomeScreen(),
    ),
    GoRoute(
      path: '/worker/profile',
      builder: (context, state) => const WorkerProfileScreen(),
    ),
    GoRoute(
      path: '/worker/documents',
      builder: (context, state) => const WorkerDocumentsScreen(),
    ),
    GoRoute(
      path: '/worker/availability',
      builder: (context, state) => const WorkerAvailabilityScreen(),
    ),
    GoRoute(
      path: '/worker/onboarding/nic',
      builder: (context, state) => const NicVerificationPage(),
    ),
    GoRoute(
      path: '/worker/onboarding/skills',
      builder: (context, state) => const SkillSelectionPage(),
    ),
    GoRoute(
      path: '/worker/onboarding/training',
      builder: (context, state) => const TrainingVideoPage(),
    ),
    GoRoute(
      path: '/worker/onboarding/contract',
      builder: (context, state) => const ContractAcceptancePage(),
    ),
    GoRoute(
      path: '/worker/dashboard/live',
      builder: (context, state) => const OnlineTogglePage(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/workers',
      builder: (context, state) => const AdminWorkersScreen(),
    ),
    GoRoute(
      path: '/admin/bookings',
      builder: (context, state) => const AdminBookingsScreen(),
    ),
    GoRoute(
      path: '/admin/incidents',
      builder: (context, state) => const AdminIncidentsScreen(),
    ),
  ],
);
