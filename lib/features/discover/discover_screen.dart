import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/restaurant_logo.dart';
import '../restaurant/restaurant_details_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _budgetController = TextEditingController();
  User? _currentUser;
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = ServiceLocator.authService.currentUser;
    _loadRestaurants();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 5 ? 'Bonsoir' : 'Bonjour';
  }

  String _getTimeOfDayLabel() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'ce matin';
    }
    if (hour >= 12 && hour < 18) {
      return 'cet après-midi';
    }
    return 'ce soir';
  }

  int? _parseBudget() {
    final value = _budgetController.text.trim();
    if (value.isEmpty) {
      return null;
    }
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    final budget = _parseBudget();
    final list = budget == null
        ? await ServiceLocator.restaurantService.getRestaurants()
        : await ServiceLocator.restaurantService.getRestaurantsByBudget(
            budget.toDouble(),
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _restaurants = list;
      _isLoading = false;
    });
  }

  void _onBudgetChanged(String _) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                '${_getGreeting()}, $userName',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.grisTexte,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Où mangez-vous\n${_getTimeOfDayLabel()} ?',
                style: textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _onBudgetChanged,
                decoration: InputDecoration(
                  hintText: 'Entrez votre budget',
                  prefixIcon: const Icon(
                    Icons.attach_money_rounded,
                    color: AppColors.grisTexte,
                  ),
                  suffixText: 'FCFA',
                  fillColor: AppColors.cremeFonce,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _budgetController.text.trim().isEmpty
                    ? 'Tous les restaurants'
                    : 'Restaurants accessibles dans votre budget',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.grisTexte,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _restaurants.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun restaurant ne correspond à ce budget.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.grisTexte,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: _restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = _restaurants[index];
                          return _buildResultCard(context, restaurant);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, Restaurant restaurant) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RestaurantLogo(
                logoUrl: restaurant.logoUrl,
                restaurantName: restaurant.nom,
                size: 84,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${restaurant.categorie} · ${restaurant.typeCuisine}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.grisTexte,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.nom,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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
}
