import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../providers/theme_provider.dart';

/// Persistent shell scaffold — rendered by [ShellRoute] in [appRouter].
///
/// Receives the currently active tab body as [child] and the current router
/// [location] string.  All routing decisions (tab switches, drawer nav) are
/// made via [GoRouter] (`context.go()`), which updates [location] and causes
/// the shell to rebuild with the new [child].
///
/// Only ONE [Scaffold] exists in the entire tab navigation tree.
/// [HomeScreen] and [FavoritesScreen] return their content directly (no
/// Scaffold wrapper) so the Drawer can be opened correctly via [_scaffoldKey].
class MainScreen extends StatelessWidget {
  /// The currently active tab body widget, injected by [ShellRoute].
  final Widget child;

  /// Current GoRouter matched location (e.g. "/", "/favorites").
  /// Used to highlight the correct drawer item and bottom nav tab.
  final String location;

  const MainScreen({
    super.key,
    required this.child,
    required this.location,
  });

  /// Direct handle to the Scaffold so any button can call openDrawer() without
  /// relying on Scaffold.of(context) which would find the wrong scaffold inside
  /// any nested widget.
  static final _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Tab definitions ────────────────────────────────────────────────────────

  /// Ordered tab descriptors used to build the BottomNavigationBar and AppBar.
  ///
  /// Index 2 is the invisible FAB gap — it has no route and taps are blocked.
  static const _tabs = [
    _TabDef(AppRoutes.home, 'Explore Places', Icons.home_outlined, Icons.home),
    _TabDef(AppRoutes.map, 'Map', Icons.map_outlined, Icons.map),
    _TabDef('', '', Icons.add, Icons.add), // FAB placeholder — no route
    _TabDef(AppRoutes.favorites, 'My Favorites', Icons.favorite_border, Icons.favorite),
    _TabDef(AppRoutes.profile, 'Profile', Icons.person_outline, Icons.person),
  ];

  /// Maps the current [location] to a bottom-nav index (0–4).
  int get _navIndex {
    if (location.startsWith(AppRoutes.favorites)) return 3;
    if (location.startsWith(AppRoutes.map)) return 1;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0; // default Home
  }

  /// Human-readable title for the current tab.
  String get _title {
    if (location.startsWith(AppRoutes.favorites)) return 'My Favorites';
    if (location.startsWith(AppRoutes.map)) return 'Map';
    if (location.startsWith(AppRoutes.profile)) return 'Profile';
    return 'Explore Places';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          // Opens drawer via key — guaranteed to target THIS scaffold's drawer.
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(_title),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),

      // ── Side Drawer ────────────────────────────────────────────────────────
      // Matches design screen 7: avatar header, nav links, dark-mode toggle.
      drawer: Drawer(
        child: Column(
          children: [
            // Profile header.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(color: AppColors.primaryPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: AppColors.primaryPurple),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aarav Mehta',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'aarav.mehta@gmail.com',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Nav links.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(context, Icons.home_outlined, 'Home',
                      location == AppRoutes.home, AppRoutes.home),
                  _drawerItem(context, Icons.map_outlined, 'Map',
                      location.startsWith(AppRoutes.map), AppRoutes.map),
                  _drawerItem(context, Icons.favorite_border, 'Favorites',
                      location.startsWith(AppRoutes.favorites), AppRoutes.favorites),
                  _drawerItem(context, Icons.download_outlined, 'Downloaded', false, null),
                  const Divider(),
                  _drawerItem(context, Icons.settings_outlined, 'Settings', false, null),
                  _drawerItem(context, Icons.help_outline, 'Help & Support', false, null),
                  _drawerItem(context, Icons.info_outline, 'About Us', false, null),
                ],
              ),
            ),

            // Dark Mode toggle.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDark ? Icons.dark_mode : Icons.light_mode,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                      const SizedBox(width: 12),
                      Text('Dark Mode', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (_) => themeProvider.toggleTheme(),
                    activeTrackColor: AppColors.primaryPurple,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Body — active tab child injected by ShellRoute ─────────────────────
      body: child,

      // ── Bottom nav + centre FAB ────────────────────────────────────────────
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          BottomNavigationBar(
            currentIndex: _navIndex,
            onTap: (index) {
              if (index == 2) return; // FAB gap — block tap
              final route = _tabs[index].route;
              if (route.isNotEmpty) context.go(route);
            },
            items: _tabs.map((tab) {
              return BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Icon(tab.activeIcon),
                label: tab.label,
              );
            }).toList(),
          ),
          // Centre FAB floats above the nav bar.
          Positioned(
            top: -20,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Builds a drawer [ListTile].
  ///
  /// If [route] is null the item is a stub (tapping just closes the drawer).
  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    bool isSelected,
    String? route,
  ) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryPurple : null),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isSelected ? AppColors.primaryPurple : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); // close drawer
        if (route != null) context.go(route);
      },
    );
  }
}

/// Immutable descriptor for a bottom-nav tab.
class _TabDef {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabDef(this.route, this.label, this.icon, this.activeIcon);
}
