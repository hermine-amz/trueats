import 'interfaces.dart';
import 'mock_services.dart';

class ServiceLocator {
  static final AuthService authService = MockAuthService();
  static final RestaurantService restaurantService = MockRestaurantService();
  static final ReviewService reviewService = MockReviewService();
  static final LocationService locationService = MockLocationService();
}
