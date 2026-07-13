import 'package:go_router/go_router.dart';
import '../../presentation/pages/role_selection_page.dart';
import '../../presentation/pages/dashboard_page.dart';
import '../../presentation/pages/navigation_page.dart';
import '../../presentation/pages/transport_page.dart';
import '../../presentation/pages/accessibility_page.dart';
import '../../presentation/pages/volunteer_dashboard_page.dart';
import '../../presentation/pages/organizer_dashboard_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const RoleSelectionPage()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/navigation',
      builder: (context, state) => const NavigationPage(),
    ),
    GoRoute(
      path: '/transport',
      builder: (context, state) => const TransportPage(),
    ),
    GoRoute(
      path: '/accessibility',
      builder: (context, state) => const AccessibilityPage(),
    ),
    GoRoute(
      path: '/volunteer',
      builder: (context, state) => const VolunteerDashboardPage(),
    ),
    GoRoute(
      path: '/organizer',
      builder: (context, state) => const OrganizerDashboardPage(),
    ),
  ],
);
