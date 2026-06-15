import '../mock_data.dart';
export '../mock_data.dart';

import 'dart:io';

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

  factory User.fromJson(Map<String, dynamic> json) {
    // Map Laravel roles ('client', 'gerant', 'admin') to Flutter roles ('utilisateur', 'gerant', 'admin')
    String roleMapped = json['role'] ?? 'utilisateur';
    if (roleMapped == 'client') {
      roleMapped = 'utilisateur';
    }

    final isActiveVal = json['compte_active'] == 1 || json['compte_active'] == true || (json['compte_active'] ?? true);

    return User(
      id: json['id'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      role: roleMapped,
      sexe: json['sexe'] ?? 'Non precise',
      dateInscription: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      dateMaj: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      isActive: isActiveVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role == 'utilisateur' ? 'client' : role,
      'sexe': sexe,
      'compte_active': isActive,
      'created_at': dateInscription.toIso8601String(),
      'updated_at': dateMaj.toIso8601String(),
    };
  }

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
    String? telephone,
  });
  Future<void> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    required String sexe,
  });
  Future<List<User>> getAllUsers();
  Future<void> setAccountActive(int userId, bool isActive);
  Future<void> refreshCurrentUser();

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
  Future<void> updateRestaurant({
    required int id,
    required String name,
    required String address,
    String? logoUrl,
    String? photoUrl,
  });
  Future<String> uploadImage(File file, {required String type});
  // Upload d'un document légal (PDF ou image)
  Future<String> uploadDocument(File file, {required String type});
  Future<List<PlatCategory>> getCategories();
  Future<PlatCategory> getOrCreateCategory(String libelle);
}

abstract class AdminService {
  Future<List<DemandeRestaurant>> getDemandes();
  Future<void> validerDemande(int restaurantId, {required bool accepte, String? motifRejet});
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
