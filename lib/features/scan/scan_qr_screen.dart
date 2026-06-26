import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../restaurant/restaurant_details_screen.dart';
import '../restaurant/write_review_screen.dart';
import '../navigation/main_navigation.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  User? _currentUser;
  bool _isScanning = true;
  bool _isLoading = false;
  bool? _cameraPermissionGranted; // null = chargement, true = accordée, false = refusée
  Restaurant? _scannedRestaurant;
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _currentUser = ServiceLocator.authService.currentUser;
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    // Sur le web, la permission est gérée par le navigateur au moment de l'accès
    if (kIsWeb) {
      setState(() => _cameraPermissionGranted = true);
      return;
    }

    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _cameraPermissionGranted = status.isGranted;
      });
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleQrCodeScanned(String code) async {
    // Demander la permission de géolocalisation
    final bool granted = await ServiceLocator.locationService.requestPermission();
    if (!granted) {
      _onResetScan();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _scannerController.stop();

    try {
      var rest = await ServiceLocator.restaurantService.getRestaurantByQrCode(code);
      
      // Si on est connectés au backend réel et que le code fictif n'existe pas
      if (rest == null && code == 'trueats_restaurant_1') {
        rest = await ServiceLocator.restaurantService.getRestaurantByQrCode('BISTRO_GOURMET_QR');
      }

      // Récupération de secours
      if (rest == null && code == 'trueats_restaurant_1') {
        try {
          final list = await ServiceLocator.restaurantService.getRestaurants();
          if (list.isNotEmpty) {
            rest = list.first;
          }
        } catch (_) {}
      }

      if (mounted) {
        if (rest != null) {
          setState(() {
            _scannedRestaurant = rest;
            _isScanning = false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          showAppNotification(
            context,
            title: "Restaurant non trouvé",
            message: "Restaurant non trouvé pour ce QR Code.",
            type: AppFeedbackType.error,
          );
          _onResetScan();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showAppNotification(
          context,
          title: "Erreur de chargement",
          message: e.toString(),
          type: AppFeedbackType.error,
        );
        _onResetScan();
      }
    }
  }

  void _onResetScan() {
    setState(() {
      _isScanning = true;
      _scannedRestaurant = null;
    });
    _scannerController.start();
  }

  void _goBackOrHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.findAncestorStateOfType<MainNavigationState>()?.setIndex(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // --- Chargement de la permission ---
    if (_cameraPermissionGranted == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goBackOrHome,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // --- Permission refusée ---
    if (_cameraPermissionGranted == false) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goBackOrHome,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_photography_outlined, color: Colors.white60, size: 72),
                const SizedBox(height: 24),
                const Text(
                  'Accès caméra requis',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'TrueAts a besoin d\'accéder à votre caméra pour scanner les QR Codes des restaurants.',
                  style: TextStyle(color: Colors.white60, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Ouvrir les paramètres'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _requestCameraPermission,
                  child: const Text('Réessayer', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.creme,
        appBar: AppBar(
          backgroundColor: AppColors.creme,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.marronFonce),
            onPressed: () {
              setState(() {
                _isLoading = false;
                _isScanning = true;
              });
              _scannerController.start();
            },
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.terracotta),
              SizedBox(height: 16),
              Text(
                'Récupération des informations du restaurant...',
                style: TextStyle(color: AppColors.marronFonce),
              ),
            ],
          ),
        ),
      );
    }

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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) async {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                            await _handleQrCodeScanned(barcodes.first.rawValue!);
                          }
                        },
                      ),
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
              top: 50,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _goBackOrHome,
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
                restaurantName,
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
                  if (restaurant == null) {
                    showAppNotification(
                      context,
                      title: "Erreur",
                      message: "Le restaurant n'est pas chargé.",
                      type: AppFeedbackType.error,
                    );
                    return;
                  }
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
                    showAppNotification(
                      context,
                      title: "Connexion requise",
                      message: "Vous devez posséder un compte utilisateur pour donner un avis.",
                      type: AppFeedbackType.warning,
                    );
                    return;
                  }

                  // Vérification restriction d'avis
                  if (_currentUser?.restrictionAvis == true) {
                    showAppNotification(
                      context,
                      title: "Accès restreint",
                      message: "Votre accès aux avis est suspendu. Contactez l'administrateur.",
                      type: AppFeedbackType.warning,
                    );
                    return;
                  }

                  if (restaurant == null) {
                    showAppNotification(
                      context,
                      title: "Erreur",
                      message: "Le restaurant n'est pas chargé.",
                      type: AppFeedbackType.error,
                    );
                    return;
                  }
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
                              color: _currentUser?.restrictionAvis == true
                                  ? AppColors.grisTexte
                                  : AppColors.marronFonce,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isVisitor
                                  ? 'Réservé aux membres inscrits'
                                  : _currentUser?.restrictionAvis == true
                                      ? 'Accès aux avis suspendu'
                                      : 'Noter mon expérience',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.grisTexte,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isVisitor || _currentUser?.restrictionAvis == true)
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
