import '../entities/weather.dart';

/// Contract for retrieving real-time weather data.
///
/// Currently implemented by [WeatherRepositoryImpl] which delegates to the
/// Open-Meteo free forecast API.  A mock implementation can be injected for
/// unit tests without any network dependency.
abstract class WeatherRepository {
  /// Fetches current weather conditions for the given [latitude]/[longitude].
  ///
  /// Throws an [Exception] if the network request fails and there is no cached
  /// weather data to fall back on.
  Future<Weather> getWeather(double latitude, double longitude);
}
