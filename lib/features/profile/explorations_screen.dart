import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/restaurant_logo.dart';
import '../restaurant/restaurant_details_screen.dart';

class ExplorationsScreen extends StatefulWidget {
  const ExplorationsScreen({super.key});

  @override
  State<ExplorationsScreen> createState() => _ExplorationsScreenState();
}

class _ExplorationsScreenState extends State<ExplorationsScreen> {
  List<Restaurant> _restaurantsToExplore = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExplorations();
  }

  Future<void> _loadExplorations() async {
    final lists = await ServiceLocator.restaurantService.getExplorationLists();
    final exploreLists = lists.where(_isExploreList).toList();
    final restaurants = <Restaurant>[];

    for (final list in exploreLists) {
      for (final restaurant in list.adresses) {
        if (!restaurants.any((item) => item.id == restaurant.id)) {
          restaurants.add(restaurant);
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _restaurantsToExplore = restaurants;
      _isLoading = false;
    });
  }

  bool _isExploreList(ExplorationList list) {
    final normalized = list.nom.toLowerCase().trim();
    return normalized == 'a explorer' || normalized == 'à explorer';
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RestaurantDetailsScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text("A explorer"),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadExplorations,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              Text(
                "A EXPLORER",
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.terracotta,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Restaurants a visiter",
                style: textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                "${_restaurantsToExplore.length} restaurant${_restaurantsToExplore.length > 1 ? 's' : ''}",
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.grisTexte,
                ),
              ),
              const SizedBox(height: 22),
              if (_isLoading)
                const SizedBox(
                  height: 320,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_restaurantsToExplore.isEmpty)
                _buildEmptyState(context)
              else
                ..._restaurantsToExplore.map(
                  (restaurant) => _buildRestaurantCard(context, restaurant),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.bookmark_add_outlined,
            color: AppColors.terracotta,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            "Aucun restaurant ajoute",
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            "Les restaurants ajoutes depuis leur fiche apparaitront ici.",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: _cardDecoration(),
      child: InkWell(
        onTap: () => _openRestaurant(restaurant),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              RestaurantLogo(
                logoUrl: restaurant.logoUrl,
                restaurantName: restaurant.nom,
                size: 76,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.nom,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant.typeCuisine} - ${restaurant.quartier}',
                      style: textTheme.bodyMedium?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.grisTexte,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant.adresse,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: AppColors.grisTexte,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.grisTexte,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFDFBF7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.grisBordure),
    );
  }
}
