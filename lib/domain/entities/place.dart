/// Domain entity representing a travel destination.
///
/// This class is the single source of truth for place data throughout the app.
/// It is immutable — use [copyWith] to produce a modified copy rather than
/// mutating fields.  Equality is based solely on [id] so [Set] / [Map]
/// containers work correctly when toggling favourites.
///
/// Data flows:
///   API JSON  ──→  [Place.fromJson]  ──→  [Place] (enriched by PlaceEnricher)
///   [Place]   ──→  [Place.toJson]    ──→  SharedPreferences cache
class Place {
  final int id;

  /// Album ID from the JSONPlaceholder API — used internally for pagination.
  final int albumId;

  /// Human-readable place name, e.g. "Lake Tekapo".
  final String title;

  /// Full-resolution image URL (Unsplash CDN).
  final String imageUrl;

  /// Lower-resolution thumbnail — used in list tiles where bandwidth matters.
  final String thumbnailUrl;

  /// City / landmark name, typically the same as [title].
  final String location;

  /// Country the place belongs to, e.g. "New Zealand".
  final String country;

  /// Long-form description shown on the detail screen.
  final String description;

  /// WGS-84 latitude — passed to the Open-Meteo weather API.
  final double latitude;

  /// WGS-84 longitude — passed to the Open-Meteo weather API.
  final double longitude;

  /// Whether the user has saved this place to their favourites list.
  /// Persisted via [LocalStorageService] (SharedPreferences).
  final bool isFavorite;

  /// Timestamp when the place was first favourited (optional).
  final DateTime? addedAt;

  Place({
    required this.id,
    required this.albumId,
    required this.title,
    required this.imageUrl,
    required this.thumbnailUrl,
    this.location = '',
    this.country = '',
    this.description = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isFavorite = false,
    this.addedAt,
  });

  /// Returns a new [Place] with only the specified fields changed.
  ///
  /// Used in [PlacesProvider.toggleFavorite] to flip [isFavorite] without
  /// rebuilding the entire place object from scratch.
  Place copyWith({
    int? id,
    int? albumId,
    String? title,
    String? imageUrl,
    String? thumbnailUrl,
    String? location,
    String? country,
    String? description,
    double? latitude,
    double? longitude,
    bool? isFavorite,
    DateTime? addedAt,
  }) {
    return Place(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      location: location ?? this.location,
      country: country ?? this.country,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFavorite: isFavorite ?? this.isFavorite,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Serialises to a JSON map for writing to SharedPreferences cache.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'albumId': albumId,
      'title': title,
      'url': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'location': location,
      'country': country,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      // Store as int (1/0) for JSON compatibility.
      'isFavorite': isFavorite ? 1 : 0,
      'addedAt': addedAt?.toIso8601String(),
    };
  }

  /// Deserialises from a JSON map.
  ///
  /// Handles both the raw JSONPlaceholder payload (which uses `"url"`) and the
  /// locally cached format produced by [toJson].
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] ?? 0,
      albumId: json['albumId'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      location: json['location'] ?? '',
      country: json['country'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      // Accept both int (1) and bool (true) because older cache may differ.
      isFavorite: json['isFavorite'] == 1 || json['isFavorite'] == true,
      addedAt: json['addedAt'] != null ? DateTime.tryParse(json['addedAt']) : null,
    );
  }

  /// Two [Place] objects with the same [id] are considered equal.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Place && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
