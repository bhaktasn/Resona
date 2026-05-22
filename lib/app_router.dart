import 'package:go_router/go_router.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/connect_screen.dart';
import 'ui/screens/session_screen.dart';
import 'ui/screens/summary_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'session/session_model.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/connect',
      builder: (context, state) => const ConnectScreen(),
    ),
    GoRoute(
      path: '/session',
      builder: (context, state) => const SessionScreen(),
    ),
    GoRoute(
      path: '/summary',
      builder: (context, state) => SummaryScreen(
        summary: state.extra as SessionSummary,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
