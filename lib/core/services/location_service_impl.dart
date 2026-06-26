import 'package:geolocator/geolocator.dart';
import 'interfaces.dart';

class GeolocatorLocationService implements LocationService {
  @override
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }

  @override
  Future<bool> isPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> isPermissionDeniedForever() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }

  @override
  Future<Map<String, double>> getCurrentLocation() async {
    bool serviceEnabled = false;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = true;
    }
    
    if (!serviceEnabled) {
      throw Exception("Le service de localisation GPS est désactivé sur cet appareil.");
    }

    final hasPerm = await requestPermission();
    if (!hasPerm) {
      throw Exception("La permission d'accès GPS a été refusée.");
    }

    Position? position;
    
    // Note de soutenance : La détection de la position sur navigateur Web (surtout desktop)
    // peut se figer indéfiniment sans timeout si le matériel GPS n'est pas présent.
    // L'algorithme ci-dessous applique des replis successifs (précision moyenne puis dernière position connue).
    try {
      // Délai augmenté à 15 secondes pour laisser le temps au matériel GPS de s'activer
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      try {
        // Premier repli : précision basse avec un timeout étendu à 10 secondes
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        ).timeout(const Duration(seconds: 10));
      } catch (_) {
        // Deuxième repli : récupération de la dernière position connue
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          throw Exception("Délai de détection GPS dépassé. Veuillez vous assurer que le partage de position est activé sur votre appareil et que le signal est bon.");
        }
      }
    }
    
    return {
      "latitude": position.latitude,
      "longitude": position.longitude,
    };
  }

  @override
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
