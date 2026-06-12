import '../mock_data.dart';
export '../mock_data.dart';

class User {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String role; // 'visiteur', 'utilisateur', 'gerant', 'admin'
  final String sexe;
  final DateTime dateInscription;
  final DateTime dateMaj;
  final bool isActive;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    required this.sexe,
    required this.dateInscription,
    required this.dateMaj,
    this.isActive = true,
  });

  String get name {
    final fullName = '$prenom $nom'.trim();
    return fullName.isEmpty ? email.split('@').first : fullName;
  }

  User copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? email,
    String? role,
    String? sexe,
    DateTime? dateInscription,
    DateTime? dateMaj,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      role: role ?? this.role,
      sexe: sexe ?? this.sexe,
      dateInscription: dateInscription ?? this.dateInscription,
      dateMaj: dateMaj ?? this.dateMaj,
      isActive: isActive ?? this.isActive,
    );
  }
}

abstract class AuthService {
  User? get currentUser;
  Stream<User?> get onAuthStateChanged;

  Future<bool> login(String email, String password);
  Future<void> logout();
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String sexe,
  });
  Future<void> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    required String sexe,
  });
  Future<List<User>> getAllUsers();
  Future<void> setAccountActive(int userId, bool isActive);

  // Utilitaire pour basculer de role lors du developpement
  void setRole(String role);
  String get currentRole;
}

abstract class RestaurantService {
  Future<List<Restaurant>> getRestaurants();
  Future<List<Restaurant>> searchRestaurants(String query);
  Future<List<Restaurant>> getRestaurantsByBudget(double maxBudget);
  Future<Restaurant?> getRestaurantById(int id);
  Future<Restaurant?> getRestaurantByQrCode(String code);

  // Listes d'explorations
  Future<List<ExplorationList>> getExplorationLists();
  Future<void> createExplorationList(
    String name,
    bool isShared,
    List<String> iconTypes,
  );
  Future<void> addRestaurantToExploration(int listId, int restaurantId);
  Future<void> addPlatToRestaurant(int restaurantId, Plat plat);
  Future<void> updatePlatInRestaurant(int restaurantId, Plat plat);
  Future<void> removePlatFromRestaurant(int restaurantId, int platId);

  Future<List<Restaurant>> getRestaurantsByManager(int managerId);
  Future<Restaurant> createRestaurant(Restaurant restaurant);
}

abstract class ReviewService {
  Future<List<Avis>> getReviewsForRestaurant(int restaurantId);
  Future<List<Avis>> getAllReviews();
  Future<void> submitReview({
    required int restaurantId,
    required int note,
    required String comment,
    required double lat,
    required double lon,
    required bool isVerified,
    List<String>? photos,
    String? authorName,
  });

  // Signalements
  Future<void> reportReview({
    required int avisId,
    required String reason,
    required String reporterName,
  });
  Future<List<Signalement>> getSignalements();
  Future<void> handleSignalement(int signalementId, bool keepReview);
}

abstract class LocationService {
  Future<bool> requestPermission();
  Future<bool> isPermissionGranted();

  // Position GPS actuelle (lat/lon)
  Future<Map<String, double>> getCurrentLocation();

  // Calcul de distance en metres
  double calculateDistance(double lat1, double lon1, double lat2, double lon2);
}
