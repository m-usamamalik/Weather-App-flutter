import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../services/weather_api_service.dart';

/// Delegates weather fetching directly to [WeatherApiService].
///
/// Currently there is no local caching for weather because weather data becomes
/// stale quickly.  If offline weather caching is needed in the future, this
/// class is the right place to add it — the interface contract remains unchanged.
class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherApiService _apiService;

  WeatherRepositoryImpl(this._apiService);

  @override
  Future<Weather> getWeather(double latitude, double longitude) async {
    return await _apiService.getWeather(latitude, longitude);
  }
}
