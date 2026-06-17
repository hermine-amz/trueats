import 'interfaces.dart';
import 'http_services.dart';
import 'location_service_impl.dart';

class ServiceLocator {
  static final HttpAuthService authService = HttpAuthService();
  static final RestaurantService restaurantService = HttpRestaurantService();
  static final ReviewService reviewService = HttpReviewService();
  // Note de soutenance : Clean Architecture.
  // Nous utilisons l'implémentation réelle GeolocatorLocationService qui interroge directement le matériel GPS
  // (sur Web/Chrome, Android, ou iOS) pour récupérer la vraie position physique de l'utilisateur.
  static final LocationService locationService = GeolocatorLocationService();
  static final AdminService adminService = HttpAdminService();

  static Future<void> init() async {
    await ApiClient.init();
    await authService.loadInitialUser();
  }
}
