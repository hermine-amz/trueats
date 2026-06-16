import 'dart:async';
import 'dart:math';

import 'interfaces.dart';

class MockAuthService implements AuthService {
  final List<User> _users = [
    User(
      id: 1,
      prenom: "Marie",
      nom: "L.",
      email: "marie@exemple.fr",
      role: "utilisateur",
      sexe: "Féminin",
      dateInscription: DateTime(2026, 3, 8),
      dateMaj: DateTime(2026, 6, 12),
    ),
    User(
      id: 2,
      prenom: "Marcel",
      nom: "K.",
      email: "marcel@exemple.fr",
      role: "gerant",
      sexe: "Masculin",
      dateInscription: DateTime(2025, 11, 20),
      dateMaj: DateTime(2026, 6, 10),
    ),
    User(
      id: 3,
      prenom: "Administrateur",
      nom: "TruEats",
      email: "admin@trueats.bj",
      role: "admin",
      sexe: "Masculin",
      dateInscription: DateTime(2025, 1, 1),
      dateMaj: DateTime(2026, 6, 12),
    ),
  ];

  late User? _currentUser = _users.first;
  final _authController = StreamController<User?>.broadcast();

  MockAuthService() {
    _authController.add(_currentUser);
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get onAuthStateChanged => _authController.stream;

  @override
  String get currentRole => _currentUser?.role ?? 'visiteur';

  @override
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final emailLower = email.toLowerCase().trim();
    if (emailLower == 'marie@exemple.fr' || emailLower == 'marie') {
      _currentUser = _users.firstWhere((user) => user.id == 1);
    } else if (emailLower == 'marcel@exemple.fr' || emailLower == 'marcel') {
      _currentUser = _users.firstWhere((user) => user.id == 2);
    } else if (emailLower == 'admin@trueats.bj' || emailLower == 'admin') {
      _currentUser = _users.firstWhere((user) => user.id == 3);
    } else {
      _currentUser = User(
        id: Random().nextInt(1000) + 10,
        prenom: email.split('@').first,
        nom: "",
        email: email,
        role: "utilisateur",
        sexe: "Masculin",
        dateInscription: DateTime.now(),
        dateMaj: DateTime.now(),
      );
      _upsertUser(_currentUser!);
    }

    _authController.add(_currentUser);
    return true;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authController.add(_currentUser);
  }

  @override
  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String sexe,
    String? telephone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = User(
      id: Random().nextInt(1000) + 100,
      nom: nom,
      prenom: prenom,
      email: email,
      role: "utilisateur",
      sexe: sexe,
      dateInscription: DateTime.now(),
      dateMaj: DateTime.now(),
    );
    _upsertUser(_currentUser!);
    _authController.add(_currentUser);
    return true;
  }

  @override
  Future<void> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    required String sexe,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final updatedUser = user.copyWith(
      nom: nom,
      prenom: prenom,
      email: email,
      sexe: sexe,
      dateMaj: DateTime.now(),
    );
    _currentUser = updatedUser;
    _upsertUser(updatedUser);
    _authController.add(_currentUser);
  }

  @override
  Future<List<User>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List<User>.from(_users);
  }

  @override
  Future<void> setAccountActive(int userId, bool isActive, {int? dureeJours}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) {
      return;
    }

    final dateSuspension = dureeJours != null ? DateTime.now().add(Duration(days: dureeJours)) : null;
    final updatedUser = _users[index].copyWith(
      isActive: isActive,
      bloqueJusqua: dateSuspension,
      dateMaj: DateTime.now(),
    );
    _users[index] = updatedUser;

    if (_currentUser?.id == userId) {
      _currentUser = updatedUser;
      _authController.add(_currentUser);
    }
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (_currentUser != null) {
      _users.removeWhere((user) => user.id == _currentUser!.id);
      _currentUser = null;
      _authController.add(null);
    }
  }

  @override
  Future<void> refreshCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 150));
  }

  @override
  void setRole(String role) {
    if (role == 'visiteur') {
      _currentUser = null;
    } else if (role == 'utilisateur') {
      _currentUser = _users.firstWhere((user) => user.id == 1);
    } else if (role == 'gerant') {
      _currentUser = _users.firstWhere((user) => user.id == 2);
    } else if (role == 'admin') {
      _currentUser = _users.firstWhere((user) => user.id == 3);
    }
    _authController.add(_currentUser);
  }

  void _upsertUser(User user) {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index == -1) {
      _users.add(user);
    } else {
      _users[index] = user;
    }
  }
}

class MockRestaurantService implements RestaurantService {
  final List<Restaurant> _restaurants = List.from(MockData.restaurants);
  final List<ExplorationList> _explorations = List.from(
    MockData.initialExplorations,
  );

  @override
  Future<List<Restaurant>> getRestaurants() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _restaurants;
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (query.trim().isEmpty) return _restaurants;

    final lowerQuery = query.toLowerCase().trim();
    return _restaurants.where((restaurant) {
      return restaurant.nom.toLowerCase().contains(lowerQuery) ||
          restaurant.quartier.toLowerCase().contains(lowerQuery) ||
          restaurant.typeCuisine.toLowerCase().contains(lowerQuery) ||
          restaurant.categorie.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<List<Restaurant>> getRestaurantsByBudget(double maxBudget) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _restaurants.where((restaurant) {
      return restaurant.menu.any((plat) => plat.prix <= maxBudget);
    }).toList();
  }

  @override
  Future<Restaurant?> getRestaurantById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _restaurants.firstWhere((restaurant) => restaurant.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Restaurant?> getRestaurantByQrCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _restaurants.firstWhere((restaurant) => restaurant.qrCode == code);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ExplorationList>> getExplorationLists() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _explorations;
  }

  @override
  Future<void> createExplorationList(
    String name,
    bool isShared,
    List<String> iconTypes,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newList = ExplorationList(
      id: _explorations.length + 1,
      nom: name,
      adresses: [],
      isShared: isShared,
      iconTypes: iconTypes.isEmpty ? ["bookmark"] : iconTypes,
    );
    _explorations.add(newList);
  }

  @override
  Future<void> addRestaurantToExploration(int listId, int restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _explorations.indexWhere((list) => list.id == listId);
    final restaurant = _restaurants.firstWhere(
      (item) => item.id == restaurantId,
    );

    if (index != -1) {
      final list = _explorations[index];
      final exists = list.adresses.any((item) => item.id == restaurantId);
      if (exists) {
        _explorations[index] = ExplorationList(
          id: list.id,
          nom: list.nom,
          adresses: list.adresses.where((item) => item.id != restaurantId).toList(),
          isShared: list.isShared,
          iconTypes: list.iconTypes,
        );
      } else {
        _explorations[index] = ExplorationList(
          id: list.id,
          nom: list.nom,
          adresses: List.from(list.adresses)..add(restaurant),
          isShared: list.isShared,
          iconTypes: list.iconTypes,
        );
      }
    }
  }

  @override
  Future<void> addPlatToRestaurant(int restaurantId, Plat plat) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _restaurants.indexWhere((item) => item.id == restaurantId);
    if (index == -1) return;

    final restaurant = _restaurants[index];
    final nextId = restaurant.menu.isEmpty
        ? 1
        : restaurant.menu.map((dish) => dish.id).reduce(max) + 1;
    final newPlat = plat.copyWith(id: plat.id == 0 ? nextId : plat.id);
    _restaurants[index] = restaurant.copyWith(
      menu: List<Plat>.from(restaurant.menu)..add(newPlat),
    );
  }

  @override
  Future<void> updatePlatInRestaurant(int restaurantId, Plat plat) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final restaurantIndex = _restaurants.indexWhere(
      (restaurant) => restaurant.id == restaurantId,
    );
    if (restaurantIndex == -1) return;

    final restaurant = _restaurants[restaurantIndex];
    final menu = List<Plat>.from(restaurant.menu);
    final platIndex = menu.indexWhere((dish) => dish.id == plat.id);
    if (platIndex == -1) return;

    menu[platIndex] = plat;
    _restaurants[restaurantIndex] = restaurant.copyWith(menu: menu);
  }

  @override
  Future<void> removePlatFromRestaurant(int restaurantId, int platId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final restaurantIndex = _restaurants.indexWhere(
      (restaurant) => restaurant.id == restaurantId,
    );
    if (restaurantIndex == -1) return;

    final restaurant = _restaurants[restaurantIndex];
    _restaurants[restaurantIndex] = restaurant.copyWith(
      menu: restaurant.menu.where((dish) => dish.id != platId).toList(),
    );
  }

  @override
  Future<List<Restaurant>> getRestaurantsByManager(int managerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _restaurants
        .where((restaurant) => restaurant.gerantId == managerId)
        .toList();
  }

  @override
  Future<Restaurant> createRestaurant(Restaurant restaurant) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final nextId = _restaurants.isEmpty
        ? 1
        : _restaurants.map((item) => item.id).reduce(max) + 1;
    final newRestaurant = restaurant.copyWith(
      id: nextId,
      qrCode: restaurant.qrCode.isEmpty
          ? 'trueats_restaurant_$nextId'
          : restaurant.qrCode,
    );
    _restaurants.add(newRestaurant);
    return newRestaurant;
  }

  @override
  Future<void> updateRestaurant({
    required int id,
    required String name,
    required String address,
    String? quartier,
    String? category,
    String? typeCuisine,
    double? latitude,
    double? longitude,
    int? superficie,
    String? logoUrl,
    String? photoUrl,
    String? cipUrl,
    String? ifuNumero,
    String? ifuAttestationUrl,
    bool? estArchive,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _restaurants.indexWhere((item) => item.id == id);
    if (index != -1) {
      final currentRes = _restaurants[index];
      final nameChanged = currentRes.nom != name;
      final shouldResetValidation = nameChanged || (!currentRes.estValide && currentRes.motifRejet != null);
      _restaurants[index] = currentRes.copyWith(
        nom: name,
        adresse: address,
        quartier: quartier,
        categorie: category,
        typeCuisine: typeCuisine,
        latitude: latitude,
        longitude: longitude,
        superficie: superficie,
        logoUrl: logoUrl,
        photoUrl: photoUrl,
        cipUrl: cipUrl,
        ifuNumero: ifuNumero,
        ifuAttestationUrl: ifuAttestationUrl,
        estArchive: estArchive,
        motifRejet: shouldResetValidation ? null : currentRes.motifRejet,
        estValide: shouldResetValidation ? false : currentRes.estValide,
      );
    }
  }

  @override
  Future<void> deleteRestaurant(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _restaurants.removeWhere((item) => item.id == id);
  }

  @override
  Future<String> uploadImage(XFile file, {required String type}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return file.path;
  }

  @override
  Future<String> uploadDocument(XFile file, {required String type}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return file.path;
  }

  static const List<PlatCategory> _defaultCategories = [
    PlatCategory(id: 1, libelle: 'Pizzas'),
    PlatCategory(id: 2, libelle: 'Burgers'),
    PlatCategory(id: 3, libelle: 'Boissons'),
    PlatCategory(id: 4, libelle: 'Plats Principaux'),
    PlatCategory(id: 5, libelle: 'Accompagnements'),
    PlatCategory(id: 6, libelle: 'Brunch'),
    PlatCategory(id: 7, libelle: 'Cafétéria'),
    PlatCategory(id: 8, libelle: 'Desserts'),
  ];

  @override
  Future<List<PlatCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List<PlatCategory>.from(_defaultCategories);
  }

  @override
  Future<PlatCategory> getOrCreateCategory(String libelle) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final trimmed = libelle.trim();
    for (final category in _defaultCategories) {
      if (category.libelle.toLowerCase() == trimmed.toLowerCase()) {
        return category;
      }
    }
    return PlatCategory(
      id: _defaultCategories.length + 1,
      libelle: trimmed,
    );
  }
}

class MockReviewService implements ReviewService {
  final List<Avis> _avisList = List.from(MockData.initialAvis);
  final List<Signalement> _signalements = List.from(
    MockData.initialSignalements,
  );

  @override
  Future<List<Avis>> getReviewsForRestaurant(int restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _avisList
        .where((avis) => avis.restaurantId == restaurantId && avis.estPublie)
        .toList();
  }

  @override
  Future<List<Avis>> getAllReviews() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _avisList;
  }

  @override
  Future<void> submitReview({
    required int restaurantId,
    required int note,
    required String comment,
    required double lat,
    required double lon,
    required bool isVerified,
    List<String>? photos,
    String? authorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final restaurant = MockData.restaurants.firstWhere(
      (item) => item.id == restaurantId,
    );
    final newAvis = Avis(
      id: _avisList.length + 101,
      nomAuteur: authorName ?? "Utilisateur",
      note: note,
      commentaire: comment,
      dateVisite: DateTime.now(),
      latClient: lat,
      longClient: lon,
      estPublie: true,
      isVerified: isVerified,
      photoUrl: photos != null && photos.isNotEmpty ? photos.first : null,
      restaurantId: restaurantId,
      restaurantNom: restaurant.nom,
    );
    _avisList.insert(0, newAvis);
  }

  @override
  Future<void> reportReview({
    required int avisId,
    required String reason,
    required String reporterName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final avis = _avisList.firstWhere((item) => item.id == avisId);
    final newSignalement = Signalement(
      id: _signalements.length + 1,
      avisId: avisId,
      avis: avis,
      auteurSignalement: reporterName,
      raison: reason,
      dateSignalement: DateTime.now(),
    );
    _signalements.add(newSignalement);
  }

  @override
  Future<List<Signalement>> getSignalements() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _signalements;
  }

  @override
  Future<void> handleSignalement(int signalementId, bool keepReview) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final signalementIndex = _signalements.indexWhere(
      (item) => item.id == signalementId,
    );
    if (signalementIndex == -1) return;

    final signalement = _signalements[signalementIndex];
    final updatedSignalement = Signalement(
      id: signalement.id,
      avisId: signalement.avisId,
      avis: signalement.avis.copyWith(estPublie: keepReview),
      auteurSignalement: signalement.auteurSignalement,
      raison: signalement.raison,
      dateSignalement: signalement.dateSignalement,
      estTraite: true,
      decision: keepReview ? 'conserve' : 'retire',
    );
    _signalements[signalementIndex] = updatedSignalement;

    final avisIndex = _avisList.indexWhere((avis) => avis.id == signalement.avisId);
    if (avisIndex != -1) {
      _avisList[avisIndex] = _avisList[avisIndex].copyWith(estPublie: keepReview);
    }
  }
}

class MockLocationService implements LocationService {
  bool _permissionGranted = true;

  // Simule une presence proche du Maquis Chez Tanti.
  static bool isSimulatingNear = true;

  // Permet de surcharger dynamiquement la position simulee pour les tests.
  static Map<String, double>? mockLocationOverride;

  @override
  Future<bool> requestPermission() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _permissionGranted = true;
    return true;
  }

  @override
  Future<bool> isPermissionGranted() async {
    return _permissionGranted;
  }

  @override
  Future<bool> isPermissionDeniedForever() async {
    return false;
  }

  @override
  Future<Map<String, double>> getCurrentLocation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mockLocationOverride != null) {
      return mockLocationOverride!;
    }
    if (isSimulatingNear) {
      return {"latitude": 6.35710, "longitude": 2.40890};
    }

    return {"latitude": 6.35245, "longitude": 2.38000};
  }

  @override
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
}

class MockAdminService implements AdminService {
  final List<DemandeRestaurant> _demandes = [];

  @override
  Future<List<DemandeRestaurant>> getDemandes() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _demandes;
  }

  @override
  Future<void> validerDemande(int restaurantId, {required bool accepte, String? motifRejet}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _demandes.removeWhere((element) => element.id == restaurantId);
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {
      'users': {
        'total': 10,
        'clients': 6,
        'gerants': 3,
        'admins': 1,
      },
      'restaurants': {
        'total': 4,
        'valides': 3,
        'en_attente': 1,
        'bloques': 0,
      },
      'avis': {
        'total': 15,
        'signales': 2,
        'note_moyenne': 4.2,
      }
    };
  }

  @override
  Future<void> deleteUser(int userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
