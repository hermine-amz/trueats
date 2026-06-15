import 'interfaces.dart';
import 'mock_services.dart';
import 'http_services.dart';

class ServiceLocator {
  static final HttpAuthService authService = HttpAuthService();
  static final RestaurantService restaurantService = HttpRestaurantService();
  static final ReviewService reviewService = HttpReviewService();
  static final LocationService locationService = MockLocationService();
  static final AdminService adminService = HttpAdminService();

  static Future<void> init() async {
    await ApiClient.init();
    await authService.loadInitialUser();
  }
}
