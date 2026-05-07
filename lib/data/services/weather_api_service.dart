import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/weather.dart';

/// HTTP client for the Open-Meteo free weather API.
///
/// Endpoint: https://api.open-meteo.com/v1/forecast
/// No API key required — rate-limited by IP but sufficient for demo use.
///
/// The `current` query parameter requests only the fields needed by [Weather]:
///   - temperature_2m       → current air temperature in °C
///   - relative_humidity_2m → humidity percentage
///   - apparent_temperature  → "feels like" temperature in °C
///   - weather_code          → WMO weather interpretation code
///   - wind_speed_10m        → wind speed in km/h
///
/// An injectable [http.Client] allows unit tests to stub the response.
class WeatherApiService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  final http.Client _client;

  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns a [Weather] snapshot for the given [latitude] and [longitude].
  ///
  /// Throws an [Exception] on non-200 responses; the caller ([WeatherProvider])
  /// catches this and updates its status to [WeatherStatus.error].
  Future<Weather> getWeather(double latitude, double longitude) async {
    final uri = Uri.parse(
      '$_baseUrl?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
      'weather_code,wind_speed_10m',
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Weather.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to fetch weather: ${response.statusCode}');
    }
  }
}
