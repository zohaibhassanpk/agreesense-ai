import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:agrisenseaiapp/core/router/route_names.dart';
import 'package:agrisenseaiapp/core/extensions/context_extensions.dart';
import 'package:agrisenseaiapp/core/providers/auth_session_provider.dart';
import 'package:agrisenseaiapp/features/auth/presentation/screens/auth_login_screen.dart';
import 'package:agrisenseaiapp/features/navbar/presentation/screens/navbar_screen.dart';
import 'package:agrisenseaiapp/features/profile/presentation/screens/profile_screen.dart';
import 'package:agrisenseaiapp/features/splash_onboarding/presentation/screens/onboarding_screen.dart';
import 'package:agrisenseaiapp/features/splash_onboarding/presentation/screens/splash_screen.dart';

class AppRouter {
  AppRouter({required AuthSessionProvider authSessionProvider})
    : _authSessionProvider = authSessionProvider;

  final AuthSessionProvider _authSessionProvider;

  GoRouter get router => _router;

  late final GoRouter _router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: _authSessionProvider,
    redirect: (context, state) {
      if (!_authSessionProvider.isReady) return null;

      final location = state.matchedLocation;
      if (location == RouteNames.splash) {
        return null;
      }
      final isAuthenticated = _authSessionProvider.isAuthenticated;
      final isAuthFlow = location == RouteNames.auth;
      final isPublic = location == RouteNames.onboarding;

      if (!isAuthenticated && !(isAuthFlow || isPublic)) {
        return RouteNames.auth;
      }

      if (isAuthenticated && (isAuthFlow || isPublic)) {
        return RouteNames.navbar;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.auth,
        name: 'auth',
        builder: (context, state) => const AuthLoginScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.navbar,
        name: 'navbar',
        builder: (context, state) => const NavbarScreen(),
      ),
    ],
    // Error page
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        body: Center(
          child: Text(
            'Something went wrong!',
            style: context.textTheme.bodyLarge,
          ),
        ),
      ),
    ),
  );
}
