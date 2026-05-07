import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../providers/places_provider.dart';
import '../widgets/place_card.dart';
import '../widgets/filter_chips.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_states.dart';

/// Home screen body — shown at nav-index 0 inside [MainScreen]'s Scaffold.
///
/// This widget intentionally does NOT wrap itself in a [Scaffold].
/// The AppBar and Drawer live in [MainScreen] so that the hamburger menu
/// button can call [ScaffoldState.openDrawer] on the correct (outer) Scaffold.
///
/// Responsibilities:
///   - Trigger the initial [PlacesProvider.loadPlaces] on first build.
///   - Debounced search field wired to [PlacesProvider.searchWithDebounce].
///   - All/Favorites/Recent filter chips wired to [PlacesProvider.setFilter].
///   - Infinite-scroll via [ScrollController] → [PlacesProvider.loadMore].
///   - Shimmer skeleton while loading, empty state when no results.
///   - Offline banner when [PlacesProvider.isOffline] is true.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Fade-in animation played once when the screen first renders.
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // Trigger infinite scroll when the user nears the bottom of the list.
    _scrollController.addListener(_onScroll);

    // Defer the first data load until the widget is fully mounted so that
    // Provider.of reads are safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlacesProvider>().loadPlaces();
    });
  }

  /// Fires [PlacesProvider.loadMore] when within 200 px of the bottom.
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PlacesProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // No Scaffold here — MainScreen owns the only Scaffold in this route.
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // ── Search bar + filter icon ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      // PlacesProvider debounces this by 500 ms internally.
                      context.read<PlacesProvider>().searchWithDebounce(value);
                      setState(() {}); // refresh clear-button visibility
                    },
                    decoration: InputDecoration(
                      hintText: 'Search places...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<PlacesProvider>()
                                    .searchWithDebounce('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Filter icon button — opens the full SearchFilterScreen.
                Container(
                  decoration: BoxDecoration(
                    color: theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, size: 20),
                    // GoRouter push preserves the back-stack so
                    // the user can return to Home with the back button.
                    onPressed: () => context.push(AppRoutes.search),
                  ),
                ),
              ],
            ),
          ),

          // ── All / Favorites / Recent filter chips ─────────────────────────
          Consumer<PlacesProvider>(
            builder: (context, provider, _) {
              return FilterChips(
                selectedIndex: provider.activeFilter.index,
                labels: const ['All', 'Favorites', 'Recent'],
                onSelected: (index) =>
                    provider.setFilter(PlaceFilter.values[index]),
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Places list ───────────────────────────────────────────────────
          Expanded(
            child: Consumer<PlacesProvider>(
              builder: (context, provider, _) {
                switch (provider.status) {
                  case PlacesStatus.initial:
                  case PlacesStatus.loading:
                    // Shimmer skeleton while the first page loads.
                    return const ShimmerList();

                  case PlacesStatus.error:
                    return ErrorState(
                      message: provider.errorMessage,
                      onRetry: () => provider.loadPlaces(refresh: true),
                    );

                  case PlacesStatus.offline:
                  case PlacesStatus.loaded:
                    if (provider.places.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No places found',
                        subtitle:
                            'Try adjusting your search or filter to find '
                            'what you\'re looking for.',
                        buttonText: 'Clear Filters',
                        onButtonPressed: () {
                          _searchController.clear();
                          provider.searchWithDebounce('');
                          provider.setFilter(PlaceFilter.all);
                        },
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => provider.loadPlaces(refresh: true),
                      color: theme.colorScheme.primary,
                      child: AnimatedList(
                        // Keying by activeFilter forces list to rebuild when
                        // switching between All/Favorites/Recent so animations
                        // replay correctly.
                        key: ValueKey(provider.activeFilter),
                        controller: _scrollController,
                        initialItemCount: provider.places.length +
                            (provider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index, animation) {
                          // Show a spinner as the last item while loading more.
                          if (index >= provider.places.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final place = provider.places[index];

                          // Each card enters with a combined size + fade transition.
                          return SizeTransition(
                            sizeFactor: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: PlaceCard(
                                place: place,
                                index: index,
                                onTap: () {
                                  // Pass the Place object as GoRouter extra —
                                  // no JSON serialisation needed.
                                  context.push(AppRoutes.detail, extra: place);
                                },
                                onFavoriteToggle: () =>
                                    provider.toggleFavorite(place),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                }
              },
            ),
          ),

          // ── Offline banner (only shown when isOffline and not in error) ───
          Consumer<PlacesProvider>(
            builder: (context, provider, _) {
              if (provider.isOffline &&
                  provider.status != PlacesStatus.error) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: Colors.orange.shade800,
                  width: double.infinity,
                  child: const Text(
                    'You\'re offline — Showing cached data',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
