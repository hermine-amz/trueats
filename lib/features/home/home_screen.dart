import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _budgetController = TextEditingController();
  User? _currentUser;
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String _query = "";

  String _selectedCategory = "Tous";

  /// Catégories disponibles construites dynamiquement depuis les restaurants chargés.
  List<String> get _categories {
    final types = _restaurants.map((r) => r.categorie).where((c) => c.isNotEmpty).toSet().toList();
    types.sort();
    return ["Tous", ...types];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentUser = ServiceLocator.authService.currentUser;
    _loadRestaurants();
  }

  String _getAvatarAsset(String? role, String? sexe) {
    final isMale = sexe?.toLowerCase().trim() == 'masculin' || sexe?.toLowerCase().trim() == 'homme';
    switch (role) {
      case 'admin':
        return isMale ? 'assets/avatar_admin_homme.png' : 'assets/avatar_admin_femme.png';
      case 'gerant':
        return isMale ? 'assets/avatar_gerant_homme.png' : 'assets/avatar_gerant_femme.png';
      case 'client':
      case 'utilisateur':
      default:
        return isMale ? 'assets/avatar_client_homme.png' : 'assets/avatar_client_femme.png';
    }
  }

  Future<void> _loadRestaurants() async {
    try {
      List<Restaurant> list = _query.trim().isEmpty
          ? await ServiceLocator.restaurantService.getRestaurants()
          : await ServiceLocator.restaurantService.searchRestaurants(_query);

      // Filtrer par budget max
      final budgetText = _budgetController.text.trim();
      if (budgetText.isNotEmpty) {
        final budget = double.tryParse(budgetText.replaceAll(RegExp(r'[^0-9]'), ''));
        if (budget != null) {
          list = list.where((restaurant) {
            return restaurant.menu.any((plat) => plat.prix <= budget);
          }).toList();
        }
      }

      // Filtrer par type de restaurant (catégorie)
      if (_selectedCategory != "Tous") {
        list = list.where((restaurant) =>
          restaurant.categorie.toLowerCase() == _selectedCategory.toLowerCase()
        ).toList();
      }

      if (mounted) {
        setState(() {
          _restaurants = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des restaurants: $e')),
        );
      }
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
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.cremeFonce,
                                  backgroundImage: AssetImage(
                                    _getAvatarAsset(_currentUser?.role, _currentUser?.sexe),
                                  ),
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
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'Nom, quartier...',
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
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _budgetController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (_) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  _loadRestaurants();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Budget max',
                                  prefixIcon: const Icon(
                                    Icons.attach_money_rounded,
                                    color: Colors.white70,
                                  ),
                                  suffixText: 'FCFA',
                                  suffixStyle: const TextStyle(color: Colors.white70, fontSize: 10),
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_categories.length > 1) ...[  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "TYPE DE RESTAURANT",
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.terracotta,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: AppColors.terracotta,
                            backgroundColor: const Color(0xFFFDFBF7),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.marronFonce,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : AppColors.grisBordure,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _isLoading = true;
                                });
                                _loadRestaurants();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  ],  // end if _categories.length > 1
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
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.id == 1
                              ? '4.7'
                              : (restaurant.id == 2 ? '4.6' : '4.8'),
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.marronFonce,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(color: AppColors.grisTexte, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.grisTexte,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                             restaurant.adresse,
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                             style: textTheme.bodyMedium?.copyWith(
                               color: AppColors.grisTexte,
                               fontSize: 12,
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
