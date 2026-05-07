import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';

/// Possible loading states for the places list.
enum PlacesStatus { initial, loading, loaded, error, offline }

/// Active filter applied to the places list in [HomeScreen].
enum PlaceFilter { all, favorites, recent }

/// Central state manager for the places feature.
///
/// Responsibilities:
///   - Initiating and paginating place loads via [PlaceRepository].
///   - Applying [PlaceFilter] and live search filtering.
///   - Tracking online/offline connectivity and auto-retrying on reconnect.
///   - Persisting favourite toggles through [PlaceRepository.toggleFavorite].
///   - Debouncing search input to avoid firing a filter pass on every keystroke.
///
/// Consumed by [HomeScreen], [FavoritesScreen], [SearchFilterScreen], and
/// [DetailScreen] via [context.read] / [context.watch].
class PlacesProvider extends ChangeNotifier {
  final PlaceRepository _repository;

  PlacesProvider(this._repository) {
    // Listen for connectivity changes so the UI can react immediately.
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        final isConnected = results.any((r) => r != ConnectivityResult.none);
        if (isConnected && _status == PlacesStatus.offline) {
          // Back online — refresh from the network.
          loadPlaces();
        } else if (!isConnected) {
          _isOffline = true;
          notifyListeners();
        }
      },
    );
  }

  List<Place> _places = [];
  List<Place> _filteredPlaces = [];
  PlacesStatus _status = PlacesStatus.initial;
  PlaceFilter _activeFilter = PlaceFilter.all;
  String _searchQuery = '';
  String _errorMessage = '';
  bool _isOffline = false;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  /// Timer used to debounce search-text changes (fires after 500 ms of silence).
  Timer? _debounceTimer;
  StreamSubscription? _connectivitySubscription;

  // ── Public getters ─────────────────────────────────────────────────────────

  /// The filtered and searched subset of [_places] shown in the list.
  List<Place> get places => _filteredPlaces;
  PlacesStatus get status => _status;
  PlaceFilter get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  String get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  /// All places currently marked as favourite (used by [FavoritesScreen]).
  List<Place> get favoritesList => _places.where((p) => p.isFavorite).toList();

  // ── Data loading ───────────────────────────────────────────────────────────

  /// Loads places from [PlaceRepository].
  ///
  /// Pass [refresh: true] to reset pagination and re-fetch from page 1.
  /// Automatically falls back to cached data and sets [isOffline] accordingly.
  Future<void> loadPlaces({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    // Show full loading skeleton only on first/refresh loads.
    if (_currentPage == 1) {
      _status = PlacesStatus.loading;
      notifyListeners();
    }

    try {
      final connectivity = await Connectivity().checkConnectivity();
      _isOffline = connectivity.every((r) => r == ConnectivityResult.none);

      final newPlaces = await _repository.fetchPlaces(
        page: _currentPage,
        limit: 20,
      );

      if (refresh || _currentPage == 1) {
        _places = newPlaces;
      } else {
        // Append page results for infinite scroll.
        _places.addAll(newPlaces);
      }

      // Fewer than 20 results means we've reached the last page.
      _hasMore = newPlaces.length >= 20;
      _applyFilters();
      _status = _isOffline ? PlacesStatus.offline : PlacesStatus.loaded;
    } catch (e) {
      // Network error — try to hydrate from the local cache.
      try {
        final cached = await _repository.getCachedPlaces();
        if (cached.isNotEmpty) {
          _places = cached;
          _applyFilters();
          _status = PlacesStatus.offline;
          _isOffline = true;
        } else {
          _errorMessage = e.toString();
          _status = PlacesStatus.error;
        }
      } catch (_) {
        _errorMessage = e.toString();
        _status = PlacesStatus.error;
      }
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Loads the next page of places (infinite scroll).
  ///
  /// No-op if already loading or no more pages exist.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    _currentPage++;
    await loadPlaces();
  }

  // ── Search & filter ────────────────────────────────────────────────────────

  /// Updates the search query and re-filters after a 500 ms debounce.
  ///
  /// Clearing the query bypasses the debounce for immediate feedback.
  void searchWithDebounce(String query) {
    _debounceTimer?.cancel();
    _searchQuery = query;

    if (query.isEmpty) {
      _applyFilters();
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
      notifyListeners();
    });
  }

  /// Changes the active [PlaceFilter] and immediately re-filters.
  void setFilter(PlaceFilter filter) {
    _activeFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  /// Applies both the search query and the active filter to [_places],
  /// storing the result in [_filteredPlaces].
  void _applyFilters() {
    var result = List<Place>.from(_places);

    // Step 1 — text search (title or country).
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.country.toLowerCase().contains(query);
      }).toList();
    }

    // Step 2 — category filter.
    switch (_activeFilter) {
      case PlaceFilter.favorites:
        result = result.where((p) => p.isFavorite).toList();
        break;
      case PlaceFilter.recent:
        // "Recent" shows the first 5 loaded places as a proxy for recently viewed.
        result = result.take(5).toList();
        break;
      case PlaceFilter.all:
        break;
    }

    _filteredPlaces = result;
  }

  // ── Favourites ─────────────────────────────────────────────────────────────

  /// Toggles the favourite state of [place] in both the repository and the
  /// local [_places] list, then re-filters so all screens update instantly.
  Future<void> toggleFavorite(Place place) async {
    await _repository.toggleFavorite(place);

    final index = _places.indexWhere((p) => p.id == place.id);
    if (index != -1) {
      _places[index] = _places[index].copyWith(
        isFavorite: !_places[index].isFavorite,
      );
    }

    _applyFilters();
    notifyListeners();
  }

  /// Returns true if the place with [placeId] is currently a favourite.
  bool isFavorite(int placeId) {
    final matches = _places.where((p) => p.id == placeId);
    return matches.isNotEmpty && matches.first.isFavorite;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
