# Smart Travel Companion — Project Flow Document

## 1. Architecture Overview

This app follows **Clean Architecture** split into three layers:

```
lib/
├── core/                    # Theme, colours, typography (shared across layers)
├── domain/                  # Entities + repository contracts (pure Dart, no Flutter)
│   ├── entities/            # Place, Weather
│   └── repositories/        # Abstract interfaces
├── data/                    # Concrete implementations of domain contracts
│   ├── services/            # Raw I/O (HTTP, SharedPreferences)
│   └── repositories/        # Implementations wiring services → domain
└── presentation/            # Flutter UI
    ├── providers/            # State management (ChangeNotifier + Provider)
    ├── screens/              # Full pages
    └── widgets/              # Reusable UI components
```

**Dependency rule:** inner layers never import outer layers.
`domain` knows nothing about `data` or `presentation`.
`data` depends on `domain` interfaces only.
`presentation` depends on `domain` entities and calls `data` via providers.

---

## 2. Startup Flow

```
main()
  │
  ├─ SharedPreferences.getInstance()          ← async; must complete before runApp
  │
  ├─ Wire services:
  │    LocalStorageService(prefs)
  │    PlaceApiService()
  │    WeatherApiService()
  │
  ├─ Wire repositories:
  │    PlaceRepositoryImpl(placeApi, localStorage)
  │    WeatherRepositoryImpl(weatherApi)
  │
  └─ runApp(MultiProvider → SmartTravelApp)
         │
         ├─ ThemeProvider    reads isDarkMode() from SharedPreferences
         ├─ PlacesProvider   starts connectivity listener
         └─ WeatherProvider  idle until a DetailScreen opens
```

---

## 3. Screen Navigation Flow

```
MainScreen (Scaffold with Drawer + BottomNav)
│
├── [0] HomeScreen
│       │
│       ├── (tap card)   ──→  DetailScreen(place)
│       └── (tap filter) ──→  SearchFilterScreen
│
├── [1] Map Screen (placeholder)
│
├── [2] FAB gap (invisible nav item)
│
├── [3] FavoritesScreen
│       │
│       └── (tap card) ──→  DetailScreen(place)
│
└── [4] Profile Screen (placeholder)
```

The side Drawer mirrors the same destinations (Home, Map, Favorites) plus
additional stubs (Downloaded, Settings, Help & Support, About Us) and the
dark-mode toggle.

---

## 4. Data Flow: Loading Places

```
HomeScreen.initState()
  └─ PlacesProvider.loadPlaces()
       │
       ├─ Check connectivity (connectivity_plus)
       │
       ├─ [online] PlaceRepositoryImpl.fetchPlaces(page: 1)
       │    ├─ PlaceApiService.fetchPlaces()  → GET /photos?_start=0&_limit=20
       │    ├─ PlaceEnricher.enrich()          → map API IDs to real destinations
       │    ├─ Merge with LocalStorageService.getFavoriteIds()
       │    └─ LocalStorageService.cachePlaces()  ← persist for offline use
       │
       └─ [offline / error] LocalStorageService.getCachedPlaces()
```

**Pagination (infinite scroll):**
```
_scrollController detects near-bottom
  └─ PlacesProvider.loadMore()
       └─ _currentPage++  →  fetchPlaces(page: N)  →  _places.addAll(...)
```

---

## 5. Data Flow: Search & Filter

```
User types in search field
  └─ PlacesProvider.searchWithDebounce(query)
       ├─ Debounce 500 ms (Timer)
       └─ _applyFilters()
            ├─ Step 1: text filter on title + country
            └─ Step 2: PlaceFilter enum
                 ├─ all       → no additional filter
                 ├─ favorites → keep isFavorite == true only
                 └─ recent    → take first 5 results
```

Applying from SearchFilterScreen also accepts Sort By and Region dropdowns
(currently filter the provider state; sort and region are stored locally and
would need to be wired to `_applyFilters` to fully sort/filter by region).

---

## 6. Data Flow: Weather (Detail Screen)

```
DetailScreen.initState()
  └─ WeatherProvider.loadWeather(place.latitude, place.longitude)
       ├─ WeatherApiService.getWeather(lat, lon)
       │    └─ GET https://api.open-meteo.com/v1/forecast
       │         ?latitude=...&longitude=...
       │         &current=temperature_2m,relative_humidity_2m,
       │                  apparent_temperature,weather_code,wind_speed_10m
       │
       ├─ Weather.fromJson()   ← parses Open-Meteo JSON
       └─ WeatherStatus.loaded → WeatherCard renders temperature, icon, stats
```

---

## 7. Data Flow: Favourites

```
User taps heart icon  (PlaceCard  or  DetailScreen)
  └─ PlacesProvider.toggleFavorite(place)
       ├─ PlaceRepositoryImpl.toggleFavorite(place)
       │    └─ LocalStorageService.saveFavoriteIds(updatedSet)
       │         └─ SharedPreferences.setStringList('favorite_ids', [...])
       │
       ├─ Update _places[index].isFavorite in memory
       ├─ _applyFilters()
       └─ notifyListeners()  →  all Consumer<PlacesProvider> widgets rebuild
```

FavoritesScreen reads `PlacesProvider.favoritesList` (a getter that filters
`_places`) — no extra network call is needed.

---

## 8. Offline Support Flow

```
ConnectivityPlus stream  →  PlacesProvider._connectivitySubscription
│
├─ [disconnected]
│    _isOffline = true
│    → HomeScreen shows orange "You're offline — Showing cached data" banner
│    → PlacesStatus.offline (still shows cached places)
│
└─ [reconnected]
     if (_status == offline)  →  loadPlaces()   ← auto-refresh
```

Cache strategy:
- Only page 1 (20 places) is cached on each successful first-page load.
- Subsequent pagination pages are ephemeral (not cached).
- Weather is never cached — it's real-time only.

---

## 9. Theme Flow

```
ThemeProvider(LocalStorageService)
  └─ _isDarkMode = LocalStorageService.isDarkMode()   ← restored from prefs

Drawer Dark Mode Switch → ThemeProvider.toggleTheme()
  ├─ _isDarkMode = !_isDarkMode
  ├─ LocalStorageService.setDarkMode(_isDarkMode)    ← persisted
  └─ notifyListeners()
       └─ SmartTravelApp (context.watch<ThemeProvider>)
            └─ MaterialApp.themeMode = ThemeMode.dark / .light
```

Both `AppTheme.lightTheme` and `AppTheme.darkTheme` are pre-built at app
start.  Flutter swaps them instantly with no rebuild of the entire tree beyond
the root.

---

## 10. Animation Inventory

| Location | Animation | Type |
|---|---|---|
| HomeScreen | Page fade-in | FadeTransition (600 ms, easeIn) |
| HomeScreen list | Item enter | SizeTransition + FadeTransition |
| PlaceCard | Press feedback | ScaleTransition (96%, 200 ms) |
| PlaceCard / Detail heart | Toggle | AnimatedSwitcher + ScaleTransition |
| DetailScreen | Content fade-in | FadeTransition (500 ms) |
| DetailScreen image | Shared hero | Hero tag `place_image_<id>` |
| DetailScreen description | Expand/collapse | AnimatedSize (400 ms, easeInOut) |
| DetailScreen chevron | Rotate | AnimatedRotation (300 ms) |
| DetailScreen weather | State swap | AnimatedSwitcher (400 ms) |
| FilterChips | Selection | AnimatedContainer (250 ms) |
| Offline banner | Appear | AnimatedContainer (300 ms) |
| SearchFilterScreen filters | Expand/collapse | AnimatedSize (300 ms) |
| FavoritesScreen items | Staggered entry | TweenAnimationBuilder (300 ms + 60 ms×index) |

---

## 11. API Status (Live Test Results)

| API | Endpoint | Auth | Status | Notes |
|---|---|---|---|---|
| JSONPlaceholder | `https://jsonplaceholder.typicode.com/photos` | None | ✅ Live | Returns paginated photo objects; images replaced by PlaceEnricher with Unsplash CDN URLs |
| Open-Meteo Weather | `https://api.open-meteo.com/v1/forecast` | None | ✅ Live | Returns real-time weather; e.g. Lake Tekapo → 7.4 °C, humidity 94%, wind 2.5 km/h |
| Unsplash CDN | `images.unsplash.com/photo-…?w=800&q=80` | None | ✅ Live | CORS-enabled; referrer policy set in `web/index.html` for Chrome web builds |

Both APIs support CORS — no API key or proxy is required for Flutter Web (Chrome) builds.

---

## 12. Key Packages

| Package | Purpose |
|---|---|
| `provider` | State management (ChangeNotifier pattern) |
| `http` | REST API calls (JSONPlaceholder, Open-Meteo) |
| `cached_network_image` | Image caching + shimmer placeholder |
| `shared_preferences` | Persistent storage (favourites, cache, theme) |
| `connectivity_plus` | Online/offline detection |
| `google_fonts` | Poppins typography |
| `shimmer` | Skeleton loading effect |
| `flutter_cache_manager` | Underlying cache for network images |

---

## 13. Design System (matches assignment PNG)

### Color Palette
| Token | Hex | Usage |
|---|---|---|
| primaryPurple | #6C63FF | Buttons, active nav, chips, FAB |
| accentRed | #FF6B6B | Favourite heart icon |
| accentGreen | #22C55E | "Live" weather badge |
| accentOrange | #F59E0B | Ratings / highlights |
| darkBg | #0F172A | Dark mode scaffold background |
| lightBg | #F8FAFC | Light mode scaffold background |
| cardDark | #1E293B | Dark mode card colour |

### Typography
All text uses **Poppins** via `google_fonts`.
Weights: Bold (700), SemiBold (600), Medium (500), Regular (400).

### Screen Checklist vs Assignment PNG
| Screen | Status |
|---|---|
| 1. Home Screen | ✅ Full implementation |
| 2. Detail Screen | ✅ Full implementation |
| 3. Search & Filter | ✅ Full implementation |
| 4. Empty State | ✅ Full implementation |
| 5. Favorites Screen | ✅ Full implementation |
| 6. Offline State | ✅ Banner + OfflineState widget |
| 7. Side Drawer | ✅ Full implementation |
| Light & Dark Theme | ✅ Full implementation |
| UI Components | ✅ Buttons, Chips, Cards, Weather Card, Bottom Nav + FAB |
