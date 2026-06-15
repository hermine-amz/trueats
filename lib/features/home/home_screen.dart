import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/restaurant_logo.dart';
import '../restaurant/restaurant_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const HomeScreen({super.key, this.onProfileTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  User? _currentUser;
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String _query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentUser = ServiceLocator.authService.currentUser;
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final list = _query.trim().isEmpty
        ? await ServiceLocator.restaurantService.getRestaurants()
        : await ServiceLocator.restaurantService.searchRestaurants(_query);
    if (mounted) {
      setState(() {
        _restaurants = list;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _query = value;
      _isLoading = true;
    });
    _loadRestaurants();
  }

  void _onRestaurantTap(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RestaurantDetailsScreen(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final userName = _currentUser?.name ?? 'Visiteur';

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: true,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      top: 24,
                      left: 24,
                      right: 24,
                      bottom: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: widget.onProfileTap,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.terracotta,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bienvenue $userName',
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un restaurant...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            fillColor: Colors.white.withValues(alpha: 0.12),
                            filled: true,
                            hintStyle: const TextStyle(color: Colors.white70),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _restaurants.isEmpty
                                ? _buildNotRegisteredMessage(context)
                                : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _restaurants.length,
                                itemBuilder: (context, index) {
                                  final restaurant = _restaurants[index];
                                  return _buildRestaurantListItem(
                                    context,
                                    restaurant,
                                  );
                                },
                              ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantListItem(BuildContext context, Restaurant restaurant) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grisBordure),
      ),
      child: InkWell(
        onTap: () => _onRestaurantTap(restaurant),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.grisTexte,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.terracotta,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.id == 1
                              ? '4.7'
                              : (restaurant.id == 2 ? '4.6' : '4.8'),
                          style: textTheme.labelLarge?.copyWith(fontSize: 13),
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

  Widget _buildNotRegisteredMessage(BuildContext context) {
    final searchedName = _query.trim();
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grisBordure),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.storefront_outlined,
            color: AppColors.grisTexte,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            searchedName.isEmpty
                ? "Aucun restaurant disponible."
                : "$searchedName n'est pas inscrit sur l'application.",
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            "Essayez un autre nom ou revenez plus tard.",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
