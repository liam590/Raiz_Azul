import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/profile_screen.dart';
import '../screens/main_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final location = state.matchedLocation;

      if (!isAuthenticated && location != '/login') {
        return '/login';
      }

      if (isAuthenticated && location == '/login') {
        return '/dashboard';
      }

      return null;
    },
  );
}