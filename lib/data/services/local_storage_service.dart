import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/place.dart';

/// Thin wrapper around [SharedPreferences] that handles three persistence
/// concerns: the places cache, the set of favourite IDs, and the theme setting.
///
/// All keys are private constants to avoid typos across call sites.
///
/// Why SharedPreferences instead of a local database?
///   — The data set is small (≤ 100 places) and structured as flat JSON, so
///     the overhead of SQLite is not justified here.  SharedPreferences is
///     simpler, synchronous to read (after the initial async load in main()),
///     and sufficient for offline caching of this scale.
class LocalStorageService {
  static const String _placesKey = 'cached_places';
  static const String _favoritesKey = 'favorite_ids';
  static const String _themeKey = 'dark_mode';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // ── Places cache ───────────────────────────────────────────────────────────

  /// Serialises [places] to JSON and stores the string under [_placesKey].
  ///
  /// Called by [PlaceRepositoryImpl.fetchPlaces] on the first page load so
  /// that subsequent offline sessions can still display content.
  Future<void> cachePlaces(List<Place> places) async {
    final jsonList = places.map((p) => p.toJson()).toList();
    await _prefs.setString(_placesKey, json.encode(jsonList));
  }

  /// Reads and deserialises the cached places JSON.
  ///
  /// Returns an empty list if no cache exists (first launch or cleared data).
  /// Synchronous because [SharedPreferences] pre-loads all keys on init.
  List<Place> getCachedPlaces() {
    final data = _prefs.getString(_placesKey);
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((j) => Place.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ── Favourites ─────────────────────────────────────────────────────────────

  /// Persists the full set of favourite [ids] as a string list.
  ///
  /// Replacing the entire set on each toggle is safe because the set is small
  /// (typically < 50 entries) and SharedPreferences writes are atomic.
  Future<void> saveFavoriteIds(Set<int> ids) async {
    await _prefs.setStringList(
      _favoritesKey,
      ids.map((id) => id.toString()).toList(),
    );
  }

  /// Reads the persisted favourite IDs and returns them as a [Set<int>].
  Set<int> getFavoriteIds() {
    final list = _prefs.getStringList(_favoritesKey) ?? [];
    return list.map((s) => int.parse(s)).toSet();
  }

  // ── Theme ──────────────────────────────────────────────────────────────────

  /// Persists the dark-mode preference so [ThemeProvider] can restore it on
  /// the next app launch.
  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_themeKey, value);
  }

  /// Returns the stored dark-mode flag; defaults to [false] (light mode).
  bool isDarkMode() {
    return _prefs.getBool(_themeKey) ?? false;
  }
}
