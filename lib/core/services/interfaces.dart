// Note de soutenance : Clean Architecture
// Le projet est structuré selon les principes de Clean Architecture pour découpler l'UI des sources de données :
// - interfaces.dart et les modèles dans mock_data.dart représentent la couche Domain (contrats et logique métier pure)
// - http_services.dart et mock_services.dart représentent la couche Data (communication API / base locale)
// - Les écrans dans lib/features/ représentent la couche Presentation (UI)

import '../mock_data.dart';
export '../mock_data.dart';

import 'package:image_picker/image_picker.dart';
export 'package:image_picker/image_picker.dart';

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
  final DateTime? bloqueJusqua;
  final String? telephone;
  final bool isGuest;
  final bool restrictionAvis;
  final bool restrictionGerant;
  final List<Restaurant> restaurants;
  final List<Avis> avis;

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
    this.bloqueJusqua,
    this.telephone,
    this.isGuest = false,
    this.restrictionAvis = false,
    this.restrictionGerant = false,
    this.restaurants = const [],
    this.avis = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Map Laravel roles ('client', 'gerant', 'admin') to Flutter roles ('utilisateur', 'gerant', 'admin')
    String roleMapped = json['role'] ?? 'utilisateur';
    if (roleMapped == 'client') {
      roleMapped = 'utilisateur';
    }

    final DateTime? bloqueJusquaVal = json['bloque_jusqua'] != null ? DateTime.tryParse(json['bloque_jusqua']) : null;
    final bool isRestrictionActive = bloqueJusquaVal != null && bloqueJusquaVal.isAfter(DateTime.now());

    final bool restrictionAvisVal = (json['restriction_avis'] == true || json['restriction_avis'] == 1) && isRestrictionActive;
    final bool restrictionGerantVal = (json['restriction_gerant'] == true || json['restriction_gerant'] == 1) && isRestrictionActive;

    // A user is blocked by date only if bloque_jusqua is in the future AND they don't have functional restrictions active.
    final isBlockedByDate = bloqueJusquaVal != null &&
                            bloqueJusquaVal.isAfter(DateTime.now()) &&
                            !restrictionAvisVal &&
                            !restrictionGerantVal;

    final dynamic activeField = json['compte_active'];
    final isActiveVal = (activeField == 1 || activeField == true || activeField == '1' || activeField == null) && !isBlockedByDate;

    final isGuestVal = json['is_guest'] == 1 || json['is_guest'] == true || json['is_guest'] == '1';

    final List<Restaurant> restaurantsList = [];
    if (json['restaurants'] != null && json['restaurants'] is List) {
      for (final r in json['restaurants']) {
        if (r is Map<String, dynamic>) {
          restaurantsList.add(Restaurant.fromJson(r));
        }
      }
    }

    final List<Avis> avisList = [];
    if (json['avis'] != null && json['avis'] is List) {
      for (final av in json['avis']) {
        if (av is Map<String, dynamic>) {
          avisList.add(Avis.fromJson(av));
        }
      }
    }

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
      bloqueJusqua: bloqueJusquaVal,
      telephone: json['telephone'],
      isGuest: isGuestVal,
      restrictionAvis: restrictionAvisVal,
      restrictionGerant: restrictionGerantVal,
      restaurants: restaurantsList,
      avis: avisList,
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
      'bloque_jusqua': bloqueJusqua?.toIso8601String(),
      'created_at': dateInscription.toIso8601String(),
      'updated_at': dateMaj.toIso8601String(),
      'telephone': telephone,
      'is_guest': isGuest,
      'restriction_avis': restrictionAvis,
      'restriction_gerant': restrictionGerant,
      'restaurants': restaurants.map((r) => r.toJson()).toList(),
      'avis': avis.map((av) => av.toJson()).toList(),
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
    DateTime? bloqueJusqua,
    String? telephone,
    bool? restrictionAvis,
    bool? restrictionGerant,
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
      bloqueJusqua: bloqueJusqua ?? this.bloqueJusqua,
      telephone: telephone ?? this.telephone,
      restrictionAvis: restrictionAvis ?? this.restrictionAvis,
      restrictionGerant: restrictionGerant ?? this.restrictionGerant,
    );
  }
}

class BlockedAccountException implements Exception {
  final String message;
  final String? motif;
  final DateTime? bloqueJusqua;
  final bool isPermanent;
  final String? email;
  final int? userId;

  BlockedAccountException({
    required this.message,
    this.motif,
    this.bloqueJusqua,
    required this.isPermanent,
    this.email,
    this.userId,
  });

  @override
  String toString() => message;
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
    String? telephone,
    String? password,
    String? passwordConfirmation,
    String? currentPassword,
  });
  Future<List<User>> getAllUsers();
  Future<void> setAccountActive(
    int userId,
    bool isActive, {
    int? dureeJours,
    String? motif,
    bool? restrictionAvis,
    bool? restrictionGerant,
  });
  Future<void> deleteAccount();
  Future<void> requestAccountDeletion({required String email, required String reason, String? comment});
  Future<void> confirmAccountDeletion({required String code});
  Future<void> refreshCurrentUser();
  Future<void> sendForgotPasswordCode({required String email});
  Future<void> verifyForgotPasswordCode({required String email, required String code});
  Future<void> resetPassword({required String email, required String code, required String password});

  // Notifications et Recours
  Future<List<AppNotification>> getNotifications();
  Future<void> markNotificationRead(int id);
  Future<void> submitAppeal({required String message, String? email, String? password});
  Future<List<UserAppeal>> getAppeals();
  Future<void> processAppeal(int appealId, {required bool accept});

  // Utilitaire pour basculer de role lors du developpement
  void setRole(String role);
  String get currentRole;
}

class AdminActionLog {
  final int id;
  final int adminId;
  final String adminName;
  final String action;
  final String? targetType;
  final int? targetId;
  final String? details;
  final DateTime createdAt;

  AdminActionLog({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    this.targetType,
    this.targetId,
    this.details,
    required this.createdAt,
  });

  factory AdminActionLog.fromJson(Map<String, dynamic> json) {
    return AdminActionLog(
      id: json['id'],
      adminId: json['admin_id'],
      adminName: json['admin_name'] ?? 'Admin inconnu',
      action: json['action'] ?? '',
      targetType: json['target_type'],
      targetId: json['target_id'],
      details: json['details'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
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
    String? telephone,
    String? horaires,
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
  });
  Future<void> deleteRestaurant(int id);
  Future<String> uploadImage(XFile file, {required String type});
  // Upload d'un document légal (PDF ou image)
  Future<String> uploadDocument(XFile file, {required String type});
  Future<List<PlatCategory>> getCategories();
  Future<PlatCategory> getOrCreateCategory(String libelle);
}

abstract class AdminService {
  Future<List<DemandeRestaurant>> getDemandes();
  Future<void> validerDemande(int restaurantId, {required bool accepte, String? motifRejet});
  Future<Map<String, dynamic>> getStats();
  Future<void> deleteUser(int userId);
  Future<List<AdminActionLog>> getAdminActionLogs();
}


abstract class ReviewService {
  Future<List<Avis>> getReviewsForRestaurant(int restaurantId);
  Future<List<Avis>> getAllReviews();
  Future<List<Avis>> getReviewsByUser(int userId);
  Future<void> submitReview({
    required int restaurantId,
    required int note,
    required String comment,
    required double lat,
    required double lon,
    required bool isVerified,
    List<String>? photos,
    String? authorName,
    int? userId,
    bool estAnonyme = false,
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
  Future<bool> isPermissionDeniedForever();

  // Position GPS actuelle (lat/lon)
  Future<Map<String, double>> getCurrentLocation();

  // Calcul de distance en metres
  double calculateDistance(double lat1, double lon1, double lat2, double lon2);
}

class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String type; // 'sanction', 'info', 'sanction_lifted', etc.
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.type,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'info',
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class UserAppeal {
  final int id;
  final int userId;
  final String? userName;
  final String? userEmail;
  final String? userRole;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  UserAppeal({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userRole,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory UserAppeal.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] as Map<String, dynamic>?;
    return UserAppeal(
      id: json['id'],
      userId: json['user_id'],
      userName: userMap != null ? "${userMap['prenom'] ?? ''} ${userMap['nom'] ?? ''}".trim() : 'Inconnu',
      userEmail: userMap != null ? userMap['email'] : null,
      userRole: userMap != null ? userMap['role'] : null,
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}
