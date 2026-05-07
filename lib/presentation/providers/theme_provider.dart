import 'package:flutter/material.dart';
import '../../data/services/local_storage_service.dart';

/// Manages the app-wide light / dark theme preference.
///
/// The preference is persisted via [LocalStorageService] (SharedPreferences)
/// so it survives app restarts.  [SmartTravelApp] watches this provider and
/// passes [themeMode] directly to [MaterialApp.themeMode].
///
/// The toggle is exposed in the [MainScreen] side drawer via a [Switch] widget.
class ThemeProvider extends ChangeNotifier {
  final LocalStorageService _localStorage;

  /// Initialise from persisted preference; defaults to light mode.
  ThemeProvider(this._localStorage) {
    _isDarkMode = _localStorage.isDarkMode();
  }

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  /// [ThemeMode] consumed directly by [MaterialApp.themeMode].
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Flips the theme and persists the new value to disk.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _localStorage.setDarkMode(_isDarkMode);
    notifyListeners();
  }
}
