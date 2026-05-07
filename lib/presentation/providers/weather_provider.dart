import 'package:flutter/material.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';

/// Loading states for weather data in [DetailScreen].
enum WeatherStatus { initial, loading, loaded, error }

/// Manages real-time weather data for the currently open [DetailScreen].
///
/// Lifecycle:
///   1. [DetailScreen.initState] calls [loadWeather] with the place's lat/lon.
///   2. Status moves initial → loading → loaded (or error).
///   3. [WeatherCard] listens via [Consumer] and renders accordingly.
///   4. When navigating away, [reset] is NOT called automatically — weather
///      data stays in memory so revisiting the same detail screen is instant.
///      Call [reset] explicitly if you want to force a fresh fetch.
///
/// A single [WeatherProvider] instance is shared across the app (registered in
/// [main]).  This means only one place's weather is held at a time, which is
/// sufficient because only one [DetailScreen] is open at a time.
class WeatherProvider extends ChangeNotifier {
  final WeatherRepository _repository;

  WeatherProvider(this._repository);

  Weather? _weather;
  WeatherStatus _status = WeatherStatus.initial;
  String _errorMessage = '';

  Weather? get weather => _weather;
  WeatherStatus get status => _status;
  String get errorMessage => _errorMessage;

  /// Fetches current weather for [latitude]/[longitude].
  ///
  /// Updates status to [WeatherStatus.error] on failure, preserving
  /// [errorMessage] so [DetailScreen] can show a retry option.
  Future<void> loadWeather(double latitude, double longitude) async {
    _status = WeatherStatus.loading;
    notifyListeners();

    try {
      _weather = await _repository.getWeather(latitude, longitude);
      _status = WeatherStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = WeatherStatus.error;
    }

    notifyListeners();
  }

  /// Clears weather data and resets status to [WeatherStatus.initial].
  ///
  /// Call before navigating to a different [DetailScreen] if you want to
  /// prevent stale weather from briefly showing for a new destination.
  void reset() {
    _weather = null;
    _status = WeatherStatus.initial;
    _errorMessage = '';
  }
}
