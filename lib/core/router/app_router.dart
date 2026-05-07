import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/place.dart';
import '../../presentation/screens/main_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/favorites_screen.dart';
import '../../presentation/screens/detail_screen.dart';
import '../../presentation/screens/search_filter_screen.dart';

/// Named route paths used throughout the app.
///
/// Declaring them as constants avoids string literals being scattered across
/// widgets.  Any rename only needs to happen here.
class AppRoutes {
  AppRoutes._();

  static const home = '/';
  static const map = '/map';
  static const favorites = '/favorites';
  static const profile = '/profile';
  static const detail = '/detail';
  static const search = '/search';
}

/// Central [GoRouter] instance used by [MaterialApp.router].
///
/// Structure:
///   ShellRoute  →  MainScreen (Drawer + BottomNav shell, persists across tabs)
///     ├── /            HomeScreen
///     ├── /map         Map placeholder
///     ├── /favorites   FavoritesScreen
///     └── /profile     Profile placeholder
///
///   GoRoute /detail   DetailScreen  (full-screen push, outside shell)
///   GoRoute /search   SearchFilterScreen  (full-screen push, outside shell)
///
/// Passing complex objects:
///   DetailScreen and SearchFilterScreen receive a [Place] via [GoRouterState.extra]
///   so no JSON serialisation is needed — the in-memory object is passed directly.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    // ── Shell: persistent scaffold with Drawer + BottomNav ─────────────────
    ShellRoute(
      /// [MainScreen] acts as the shell.  It receives the currently active tab
      /// body as [child] and renders it inside its own Scaffold body area.
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return MainScreen(child: child, location: state.matchedLocation);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.map,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Map — Coming Soon')),
          ),
        ),
        GoRoute(
          path: AppRoutes.favorites,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FavoritesScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: Center(child: Text('Profile — Coming Soon')),
          ),
        ),
      ],
    ),

    // ── Full-screen routes (outside the shell / no bottom nav) ─────────────
    GoRoute(
      path: AppRoutes.detail,
      /// [Place] is passed via [GoRouterState.extra] — no serialisation needed.
      builder: (context, state) {
        final place = state.extra! as Place;
        return DetailScreen(place: place);
      },
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const SearchFilterScreen(),
    ),
  ],
);
