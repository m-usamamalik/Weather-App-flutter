import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/place.dart';
import '../providers/weather_provider.dart';
import '../providers/places_provider.dart';
import '../widgets/weather_card.dart';

class DetailScreen extends StatefulWidget {
  final Place place;

  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  bool _isDescriptionExpanded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.place.latitude != 0.0 && widget.place.longitude != 0.0) {
        context.read<WeatherProvider>().loadWeather(
              widget.place.latitude,
              widget.place.longitude,
            );
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<PlacesProvider>();
    final isFav = context.watch<PlacesProvider>().isFavorite(widget.place.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image with app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(77),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(), // GoRouter-aware back
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(77),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(isFav),
                      color: isFav ? AppColors.accentRed : Colors.white,
                    ),
                  ),
                  onPressed: () {
                    provider.toggleFavorite(widget.place);
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'place_image_${widget.place.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.place.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.place.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.primaryPurple,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.place.country,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      widget.place.description.isNotEmpty
                          ? widget.place.description
                          : 'A stunning destination known for its natural beauty and cultural heritage. A must-visit for nature lovers and photographers.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                      maxLines: _isDescriptionExpanded ? null : 3,
                      overflow: _isDescriptionExpanded
                          ? null
                          : TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Weather section
                    Consumer<WeatherProvider>(
                      builder: (context, weatherProvider, _) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _buildWeatherSection(weatherProvider),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // About the place expandable
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'About the place',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isDescriptionExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(Icons.keyboard_arrow_up),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Expandable content
                    AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: _isDescriptionExpanded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.place.description.isNotEmpty
                                      ? widget.place.description
                                      : 'This beautiful place offers an unforgettable experience for travelers seeking adventure, relaxation, and cultural enrichment. The unique combination of natural beauty and historical significance makes it a must-visit destination.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Coordinates: ${widget.place.latitude.toStringAsFixed(4)}, ${widget.place.longitude.toStringAsFixed(4)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // View on Map button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Map view for ${widget.place.title} (${widget.place.latitude}, ${widget.place.longitude})',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('View on Map'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection(WeatherProvider provider) {
    switch (provider.status) {
      case WeatherStatus.loading:
        return Container(
          key: const ValueKey('loading'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Loading weather data...'),
              ],
            ),
          ),
        );
      case WeatherStatus.loaded:
        return WeatherCard(
          key: const ValueKey('loaded'),
          weather: provider.weather!,
        );
      case WeatherStatus.error:
        return Container(
          key: const ValueKey('error'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(26),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Unable to load weather data'),
              ),
              TextButton(
                onPressed: () {
                  provider.loadWeather(
                    widget.place.latitude,
                    widget.place.longitude,
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      case WeatherStatus.initial:
        return const SizedBox.shrink(key: ValueKey('initial'));
    }
  }
}
