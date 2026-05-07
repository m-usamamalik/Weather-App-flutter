/// Domain entity representing real-time weather at a [Place]'s coordinates.
///
/// Data is fetched from the free Open-Meteo API
/// (https://api.open-meteo.com/v1/forecast) using the place's WGS-84 lat/lon.
/// No API key is required.
///
/// The WMO weather interpretation code ([weatherCode]) maps to a human-readable
/// [description] and an emoji [icon] rendered in [WeatherCard].
class Weather {
  /// Current temperature in degrees Celsius.
  final double temperature;

  /// Wind speed in km/h at 10 m height.
  final double windSpeed;

  /// Relative humidity as a percentage (0–100).
  final int humidity;

  /// Apparent ("feels like") temperature in °C accounting for wind chill /
  /// heat index.
  final double feelsLike;

  /// WMO weather interpretation code.  0 = clear sky, 1–3 = partly cloudy,
  /// 45–48 = fog, 51–57 = drizzle, 61–67 = rain, 71–77 = snow, etc.
  final int weatherCode;

  /// Plain-English description derived from [weatherCode].
  final String description;

  Weather({
    required this.temperature,
    required this.windSpeed,
    required this.humidity,
    required this.feelsLike,
    required this.weatherCode,
    required this.description,
  });

  /// Parses the Open-Meteo JSON response.
  ///
  /// The API nests current conditions under the `"current"` key (v1 format).
  /// Older forecast API versions used `"current_weather"` — both are handled
  /// so cached responses remain compatible.
  factory Weather.fromJson(Map<String, dynamic> json) {
    final current = json['current'] ?? json['current_weather'] ?? {};

    final double temp =
        (current['temperature_2m'] ?? current['temperature'] ?? 0).toDouble();
    final double wind =
        (current['wind_speed_10m'] ?? current['windspeed'] ?? 0).toDouble();
    final int hum = (current['relative_humidity_2m'] ?? 50).toInt();
    final double feels = (current['apparent_temperature'] ?? temp).toDouble();
    final int code =
        (current['weather_code'] ?? current['weathercode'] ?? 0).toInt();

    return Weather(
      temperature: temp,
      windSpeed: wind,
      humidity: hum,
      feelsLike: feels,
      weatherCode: code,
      description: _getWeatherDescription(code),
    );
  }

  /// Emoji icon that visually represents the current [weatherCode].
  ///
  /// Rendered at large size in [WeatherCard] to give an at-a-glance status.
  String get icon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 57) return '🌦️';
    if (weatherCode <= 67) return '🌧️';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 82) return '🌧️';
    if (weatherCode <= 86) return '🌨️';
    if (weatherCode <= 99) return '⛈️';
    return '🌤️';
  }

  /// Maps a WMO code to a short English description shown below the temperature.
  static String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear Sky';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain Showers';
    if (code <= 86) return 'Snow Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}
