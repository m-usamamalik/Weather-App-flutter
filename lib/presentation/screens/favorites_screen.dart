import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../providers/places_provider.dart';
import '../widgets/place_card.dart';
import '../widgets/empty_states.dart';

/// Favorites screen body — shown at nav-index 3 inside [MainScreen]'s Scaffold.
///
/// Like [HomeScreen], this widget does NOT wrap itself in a [Scaffold].
/// The Drawer lives in [MainScreen]; the hamburger button in [MainScreen]'s
/// AppBar opens it correctly without any nested-scaffold conflicts.
///
/// Reads [PlacesProvider.favoritesList] which is a live in-memory filter —
/// no extra network call is needed.  Any heart tap on HomeScreen or DetailScreen
/// updates the same provider list and this screen rebuilds automatically.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlacesProvider>(
      builder: (context, provider, _) {
        final favorites = provider.favoritesList;

        if (favorites.isEmpty) {
          // Design screen 5 (empty variant) — friendly empty state.
          return const EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No Favorites Yet',
            subtitle:
                'Tap the heart icon on any place to save it here for quick access.',
          );
        }

        // List of favourite places as PlaceListTile rows matching design screen 5.
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final place = favorites[index];

            // Staggered entrance: each card fades + slides in with 60 ms offset.
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + index * 60),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: PlaceListTile(
                place: place,
                onTap: () => context.push(AppRoutes.detail, extra: place),
                // Removing a favourite here updates the list in real time.
                onFavoriteToggle: () => provider.toggleFavorite(place),
              ),
            );
          },
        );
      },
    );
  }
}
