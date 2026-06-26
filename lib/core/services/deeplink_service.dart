import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../main.dart'; // pour navigatorKey
import 'service_locator.dart';
import '../../features/restaurant/restaurant_details_screen.dart';

class DeepLinkService {
  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _linkSubscription;

  static void init() {
    // 1. Gérer les liens de démarrage (Cold Start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // 2. Écouter les flux de liens entrants (App en cours d'exécution)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Erreur de flux Deep Link: $err');
      },
    );
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }

  static Future<void> _handleDeepLink(Uri uri) async {
    final path = uri.path;
    debugPrint('Deep Link intercepté : $uri (path: $path)');

    // Format attendu : /scan/<qr_code>
    if (path.startsWith('/scan/')) {
      final parts = path.split('/');
      if (parts.length >= 3) {
        final qrCode = parts[2];
        if (qrCode.isNotEmpty) {
          _navigateToRestaurant(qrCode);
        }
      }
    }
  }

  static Future<void> _navigateToRestaurant(String qrCode) async {
    // Attendre un court instant pour s'assurer que le navigateur global est prêt
    await Future.delayed(const Duration(milliseconds: 600));

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      debugPrint("Redirection annulée : pas de context de navigation disponible.");
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final restaurant = await ServiceLocator.restaurantService.getRestaurantByQrCode(qrCode);
      
      // Fermer l'indicateur de chargement
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pop();
      }

      if (restaurant != null) {
        // Rediriger vers l'écran du restaurant
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(restaurant: restaurant),
          ),
        );
      } else {
        // Établissement introuvable
        if (navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text("Établissement introuvable ou indisponible."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Fermer l'indicateur de chargement si ouvert
      if (navigatorKey.currentContext != null) {
        Navigator.of(navigatorKey.currentContext!).pop();
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la récupération du restaurant : $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
