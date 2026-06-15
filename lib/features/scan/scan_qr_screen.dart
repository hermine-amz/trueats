import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../restaurant/restaurant_details_screen.dart';
import '../restaurant/write_review_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  User? _currentUser;
  bool _isScanning = true;
  Restaurant? _scannedRestaurant;

  @override
  void initState() {
    super.initState();
    _currentUser = ServiceLocator.authService.currentUser;
  }

  Future<void> _requestLocationPermission() async {
    final bool? allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.orangeClair,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.terracotta,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Autoriser la localisation ?',
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.displaySmall?.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'TruEats utilise votre position pour certifier que vous êtes bien sur place.',
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.bodyMedium?.copyWith(height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Refuser'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Autoriser'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (allowed != true) {
      return;
    }

    final granted = await ServiceLocator.locationService.requestPermission();
    if (!granted) {
      _onResetScan();
      return;
    }

    await _simulateScanningSuccess();
  }

  Future<void> _simulateScanningSuccess() async {
    setState(() {
      _isScanning = false;
    });

    final rest = await ServiceLocator.restaurantService.getRestaurantByQrCode(
      'trueats_restaurant_1',
    );
    if (mounted) {
      setState(() {
        _scannedRestaurant = rest;
      });
    }
  }

  void _onResetScan() {
    setState(() {
      _isScanning = true;
      _scannedRestaurant = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isScanning) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.sauge, width: 3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 150,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Placez le QR Code de la table au centre',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 60,
              left: 40,
              right: 40,
              child: ElevatedButton(
                onPressed: _requestLocationPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sauge,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Simuler le scan d'une table"),
              ),
            ),
            Positioned(
              top: 50,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Retour à l'accueil")),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isVisitor = _currentUser?.role == 'visiteur' || _currentUser == null;
    final restaurant = _scannedRestaurant;
    final restaurantName = restaurant?.nom ?? 'Maquis Chez Tanti';
    final restaurantCategory = restaurant != null
        ? '${restaurant.categorie} · ${restaurant.typeCuisine}'
        : 'Maquis · Africain';
    final restaurantInfo = restaurant != null
        ? restaurant.quartier
        : 'Haie-Vive';

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _onResetScan,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Bienvenue $restaurantName',
                textAlign: TextAlign.center,
                style: textTheme.displayLarge?.copyWith(
                  color: AppColors.terracotta,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$restaurantCategory · $restaurantInfo',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.grisTexte,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              InkWell(
                onTap: () {
                  if (restaurant == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RestaurantDetailsScreen(
                        restaurant: restaurant,
                        initialTabIndex: 0,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.terracotta,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voir le menu',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Plats, boissons et prix du jour',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  if (isVisitor) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vous devez posséder un compte utilisateur pour donner un avis.',
                        ),
                        backgroundColor: AppColors.terracotta,
                      ),
                    );
                    return;
                  }

                  if (restaurant == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          WriteReviewScreen(restaurant: restaurant),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.grisBordure),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.vertClair,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.sauge,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Donner mon avis',
                              style: textTheme.titleLarge?.copyWith(
                                color: AppColors.marronFonce,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isVisitor
                                  ? 'Réservé aux membres inscrits'
                                  : 'Noter mon expérience',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.grisTexte,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isVisitor)
                        const Icon(
                          Icons.lock_outline,
                          color: AppColors.grisTexte,
                          size: 18,
                        )
                      else
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.marronFonce,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
