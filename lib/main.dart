import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/repositories/place_repository_impl.dart';
import 'data/repositories/weather_repository_impl.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/place_api_service.dart';
import 'data/services/weather_api_service.dart';
import 'presentation/providers/places_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/weather_provider.dart';

/// Entry point.
///
/// Dependency wiring order (bottom-up):
///   SharedPreferences → LocalStorageService
///   LocalStorageService + PlaceApiService → PlaceRepositoryImpl
///   WeatherApiService → WeatherRepositoryImpl
///   Repositories → Providers (injected into the widget tree via MultiProvider)
///
/// Navigation is handled by [appRouter] (GoRouter) configured in
/// [core/router/app_router.dart].  [MaterialApp.router] delegates all routing
/// to GoRouter instead of Flutter's default Navigator 1.0 stack.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disk-backed key-value store — theme pref and place cache.
  final prefs = await SharedPreferences.getInstance();

  // ── Services (raw I/O) ────────────────────────────────────────────────────
  final localStorageService = LocalStorageService(prefs);
  final placeApiService = PlaceApiService();
  final weatherApiService = WeatherApiService();

  // ── Repositories (business-logic adapters over services) ─────────────────
  final placeRepository = PlaceRepositoryImpl(placeApiService, localStorageService);
  final weatherRepository = WeatherRepositoryImpl(weatherApiService);

  runApp(
    MultiProvider(
      providers: [
        // Persists light/dark preference between sessions.
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(localStorageService),
        ),
        // Manages places list, pagination, search, filters, offline state.
        ChangeNotifierProvider(
          create: (_) => PlacesProvider(placeRepository),
        ),
        // Holds weather data for the currently viewed place detail.
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(weatherRepository),
        ),
      ],
      child: const SmartTravelApp(),
    ),
  );
}

/// Root widget that wires [GoRouter] into [MaterialApp.router].
///
/// [MaterialApp.router] hands all navigation control to [appRouter].
/// Theme selection is delegated to [ThemeProvider] so the dark-mode toggle
/// in the side drawer persists across restarts.
class SmartTravelApp extends StatelessWidget {
  const SmartTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Smart Travel Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // All routing is controlled by GoRouter.
      routerConfig: appRouter,
    );
  }
}
