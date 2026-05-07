import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/places_provider.dart';
import '../widgets/place_card.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'Recommended';
  String _showFilter = 'All';
  String _region = 'All Regions';
  bool _showFilters = true;

  final List<String> _sortOptions = [
    'Recommended',
    'Name (A-Z)',
    'Name (Z-A)',
    'Recently Added',
  ];

  final List<String> _regionOptions = [
    'All Regions',
    'Asia',
    'Europe',
    'Americas',
    'Africa',
    'Oceania',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search places...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? AppColors.cardDark : Colors.grey.shade100,
            ),
            onChanged: (value) {
              context.read<PlacesProvider>().searchWithDebounce(value);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              context.read<PlacesProvider>().searchWithDebounce('');
              context.pop(); // GoRouter-aware pop
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters section
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showFilters
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filters',
                              style: theme.textTheme.titleLarge,
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _sortBy = 'Recommended';
                                  _showFilter = 'All';
                                  _region = 'All Regions';
                                });
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(color: AppColors.primaryPurple),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Sort By
                        Text('Sort By', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        _buildDropdown(_sortBy, _sortOptions, (value) {
                          setState(() => _sortBy = value!);
                        }),

                        const SizedBox(height: 16),

                        // Show filter
                        Text('Show', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildFilterButton('All', _showFilter == 'All', () {
                              setState(() => _showFilter = 'All');
                            }),
                            const SizedBox(width: 8),
                            _buildFilterButton(
                                'Favorites', _showFilter == 'Favorites', () {
                              setState(() => _showFilter = 'Favorites');
                            }),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Region
                        Text('Region', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        _buildDropdown(_region, _regionOptions, (value) {
                          setState(() => _region = value!);
                        }),

                        const SizedBox(height: 16),

                        // Apply button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final provider = context.read<PlacesProvider>();
                              if (_showFilter == 'Favorites') {
                                provider.setFilter(PlaceFilter.favorites);
                              } else {
                                provider.setFilter(PlaceFilter.all);
                              }
                              setState(() => _showFilters = false);
                            },
                            child: const Text('Apply Filters'),
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _showFilters = true);
                      },
                      icon: const Icon(Icons.tune),
                      label: const Text('Show Filters'),
                    ),
                  ),
          ),

          const Divider(height: 1),

          // Search results
          Expanded(
            child: Consumer<PlacesProvider>(
              builder: (context, provider, _) {
                final places = provider.places;
                if (places.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return PlaceListTile(
                      place: place,
                      onTap: () => context.push(AppRoutes.detail, extra: place),
                      onFavoriteToggle: () => provider.toggleFavorite(place),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : Colors.grey.withAlpha(77),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
