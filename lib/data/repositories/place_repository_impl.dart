import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../services/place_api_service.dart';
import '../services/local_storage_service.dart';

/// Concrete implementation of [PlaceRepository].
///
/// Responsibilities:
///   1. Fetch places from [PlaceApiService] (network).
///   2. Merge the API response with the user's saved favourite IDs so every
///      [Place] object has an accurate [Place.isFavorite] flag.
///   3. Cache the first page to [LocalStorageService] for offline use.
///   4. Fall back to the local cache on any network error.
///
/// The caching strategy is "cache on first page load":
///   - Only page 1 is cached (pages 2+ are pagination top-ups).
///   - On error the full cache is returned so offline sessions still feel rich.
class PlaceRepositoryImpl implements PlaceRepository {
  final PlaceApiService _apiService;
  final LocalStorageService _localStorage;

  PlaceRepositoryImpl(this._apiService, this._localStorage);

  @override
  Future<List<Place>> fetchPlaces({int page = 1, int limit = 20}) async {
    try {
      final places = await _apiService.fetchPlaces(page: page, limit: limit);

      // Re-apply favourite flags from local storage after every fetch so that
      // places favourited offline are still highlighted when going back online.
      final favoriteIds = _localStorage.getFavoriteIds();
      final enrichedPlaces = places.map((p) {
        return p.copyWith(isFavorite: favoriteIds.contains(p.id));
      }).toList();

      // Persist first page as offline cache (subsequent pages are ephemeral).
      if (page == 1) {
        await _localStorage.cachePlaces(enrichedPlaces);
      }

      return enrichedPlaces;
    } catch (e) {
      // Network unavailable — hydrate from local cache if possible.
      final cached = _localStorage.getCachedPlaces();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<List<Place>> searchPlaces(String query) async {
    // Load a larger page to search across more results, then filter in-memory.
    final allPlaces = await fetchPlaces(limit: 100);
    final lowerQuery = query.toLowerCase();
    return allPlaces.where((p) {
      return p.title.toLowerCase().contains(lowerQuery) ||
          p.country.toLowerCase().contains(lowerQuery) ||
          p.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<Place> getPlaceById(int id) async {
    try {
      final place = await _apiService.fetchPlaceById(id);
      final favoriteIds = _localStorage.getFavoriteIds();
      return place.copyWith(isFavorite: favoriteIds.contains(place.id));
    } catch (e) {
      // Try the local cache before giving up.
      final cached = _localStorage.getCachedPlaces();
      final found = cached.where((p) => p.id == id);
      if (found.isNotEmpty) return found.first;
      rethrow;
    }
  }

  @override
  Future<List<Place>> getFavorites() async {
    final favoriteIds = _localStorage.getFavoriteIds();
    if (favoriteIds.isEmpty) return [];

    try {
      final allPlaces = await fetchPlaces(limit: 100);
      return allPlaces.where((p) => favoriteIds.contains(p.id)).toList();
    } catch (e) {
      // Offline: filter the local cache.
      final cached = _localStorage.getCachedPlaces();
      return cached.where((p) => favoriteIds.contains(p.id)).toList();
    }
  }

  @override
  Future<void> toggleFavorite(Place place) async {
    final favoriteIds = _localStorage.getFavoriteIds();
    if (favoriteIds.contains(place.id)) {
      favoriteIds.remove(place.id);
    } else {
      favoriteIds.add(place.id);
    }
    // Atomically replace the stored set.
    await _localStorage.saveFavoriteIds(favoriteIds);
  }

  @override
  Future<List<Place>> getCachedPlaces() async {
    return _localStorage.getCachedPlaces();
  }

  @override
  Future<void> cachePlaces(List<Place> places) async {
    await _localStorage.cachePlaces(places);
  }
}
