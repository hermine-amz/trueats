import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/restaurant_logo.dart';
import 'restaurant_management_screen.dart';

class ManagedRestaurantsScreen extends StatefulWidget {
  const ManagedRestaurantsScreen({super.key});

  @override
  State<ManagedRestaurantsScreen> createState() =>
      _ManagedRestaurantsScreenState();
}

class _ManagedRestaurantsScreenState extends State<ManagedRestaurantsScreen> {
  List<Restaurant> _managedRestaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadManagedRestaurants();
  }

  Future<void> _loadManagedRestaurants() async {
    final currentUser = ServiceLocator.authService.currentUser;
    if (currentUser == null) {
      setState(() {
        _managedRestaurants = [];
        _isLoading = false;
      });
      return;
    }

    final list = await ServiceLocator.restaurantService.getRestaurantsByManager(
      currentUser.id,
    );
    if (!mounted) return;
    setState(() {
      _managedRestaurants = list;
      _isLoading = false;
    });
  }

  void _openRestaurant(Restaurant restaurant) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            RestaurantManagementScreen(restaurant: restaurant),
      ),
    );
    _loadManagedRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text('Gestion restaurants'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadManagedRestaurants,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            children: [
              Text(
                'MES RESTAURANTS',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.terracotta,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Etablissements que je gere',
                style: textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_managedRestaurants.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.grisBordure),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.terracotta,
                        size: 36,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Vous ne gerez encore aucun restaurant.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge?.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inscrivez un restaurant pour l ajouter a votre gestion.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              else
                ..._managedRestaurants.map(
                  (restaurant) => _buildRestaurantCard(context, restaurant),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grisBordure),
      ),
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
                      '${restaurant.typeCuisine} · ${restaurant.quartier}',
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
}
