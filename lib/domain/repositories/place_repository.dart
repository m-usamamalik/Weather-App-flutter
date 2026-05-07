import '../entities/place.dart';

/// Contract between the presentation layer and the data layer for place data.
///
/// All UI code depends on this abstract interface, not on any concrete
/// implementation.  This makes the data source swappable (e.g. switching from
/// JSONPlaceholder to a real travel API) without touching any widget.
///
/// Implementations live in `data/repositories/`.
abstract class PlaceRepository {
  /// Fetches a paginated list of places from the remote API.
  ///
  /// [page] is 1-based; [limit] controls how many places per page.
  /// Falls back to the local cache when the network is unavailable.
  Future<List<Place>> fetchPlaces({int page = 1, int limit = 20});

  /// Returns all places whose [Place.title], [Place.country], or
  /// [Place.description] contains [query] (case-insensitive).
  Future<List<Place>> searchPlaces(String query);

  /// Fetches a single place by its [id] — first from network, then from cache.
  Future<Place> getPlaceById(int id);

  /// Returns only places currently marked as favourites by the user.
  Future<List<Place>> getFavorites();

  /// Flips the [Place.isFavorite] flag and persists the updated favourite-ID
  /// set to SharedPreferences via [LocalStorageService].
  Future<void> toggleFavorite(Place place);

  /// Returns all places stored in the local SharedPreferences cache.
  /// Used to hydrate the UI while offline.
  Future<List<Place>> getCachedPlaces();

  /// Writes [places] to the local cache, replacing the previous snapshot.
  Future<void> cachePlaces(List<Place> places);
}
