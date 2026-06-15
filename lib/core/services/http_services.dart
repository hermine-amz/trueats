import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'interfaces.dart';

// Helper Client API pour centraliser les requetes HTTP et l'authentification
class ApiClient {
  static String? _token;
  static final _tokenController = StreamController<String?>.broadcast();

  static String get baseUrl {
    // Si l'application tourne sur le web ou sur un appareil physique / simulateur iOS
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    // Si l'application tourne sur l'emulateur Android (redirection localhost)
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  static String? get token => _token;
  static Stream<String?> get onTokenChanged => _tokenController.stream;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _tokenController.add(_token);
  }

  static Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
    _tokenController.add(_token);
  }

  static Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static dynamic _handleResponse(http.Response response) {
    final body = response.body;
    final statusCode = response.statusCode;

    if (statusCode == 401) {
      // Deconnexion automatique si non autorise
      setToken(null);
      throw Exception('Session expiree. Veuillez vous reconnecter.');
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }

    // Gestion des erreurs Laravel
    String errorMessage = 'Une erreur est survenue ($statusCode)';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        errorMessage = decoded['message'];
      } else if (decoded is Map && decoded['errors'] != null) {
        // Validation Laravel
        final errors = decoded['errors'] as Map;
        errorMessage = errors.values.map((e) => (e as List).join(', ')).join('\n');
      }
    } catch (_) {}

    throw Exception(errorMessage);
  }

  static Future<dynamic> get(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur reseau : ${e.toString()}');
    }
  }

  static Future<dynamic> post(String path, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur reseau : ${e.toString()}');
    }
  }

  static Future<dynamic> put(String path, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur reseau : ${e.toString()}');
    }
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur reseau : ${e.toString()}');
    }
  }

  static Future<dynamic> delete(String path) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: _headers(),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur reseau : ${e.toString()}');
    }
  }

  static Future<String> uploadImage(XFile file, {required String type}) async {
    return uploadFile(file, endpoint: '/upload/image', fieldName: 'image', type: type);
  }

  // Méthode générique pour tout upload multipart compatible Web
  static Future<String> uploadFile(
    XFile file, {
    required String endpoint,
    required String fieldName,
    required String type,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      request.headers['Accept'] = 'application/json';
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      request.fields['type'] = type;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            bytes,
            filename: file.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(fieldName, file.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = _handleResponse(response);

      if (data is Map && data['url'] != null) {
        return data['url'] as String;
      }
      throw Exception('URL manquante dans la reponse serveur.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur upload : ${e.toString()}');
    }
  }
}

// Implementation de AuthService via API HTTP
class HttpAuthService implements AuthService {
  User? _currentUser;
  final _authController = StreamController<User?>.broadcast();
  StreamSubscription<String?>? _tokenSubscription;

  HttpAuthService() {
    _tokenSubscription = ApiClient.onTokenChanged.listen((token) {
      if (token == null) {
        _currentUser = null;
        _authController.add(null);
      }
    });
  }

  // Methode pour charger l'utilisateur initial si un token existe
  Future<void> loadInitialUser() async {
    if (ApiClient.token != null) {
      try {
        final data = await ApiClient.get('/user');
        _currentUser = User.fromJson(data);
        _authController.add(_currentUser);
      } catch (_) {
        await ApiClient.setToken(null);
        _currentUser = null;
        _authController.add(null);
      }
    } else {
      _currentUser = null;
      _authController.add(null);
    }
  }

  @override
  Future<void> refreshCurrentUser() async {
    if (ApiClient.token != null) {
      try {
        final data = await ApiClient.get('/user');
        _currentUser = User.fromJson(data);
        _authController.add(_currentUser);
      } catch (e) {
        rethrow;
      }
    }
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> get onAuthStateChanged => _authController.stream;

  @override
  String get currentRole => _currentUser?.role ?? 'visiteur';

  @override
  Future<bool> login(String email, String password) async {
    try {
      final response = await ApiClient.post('/login', {
        'email': email.trim(),
        'password': password,
      });

      if (response != null && response['access_token'] != null) {
        await ApiClient.setToken(response['access_token']);
        _currentUser = User.fromJson(response['user']);
        _authController.add(_currentUser);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      if (ApiClient.token != null) {
        await ApiClient.post('/logout', {});
      }
    } catch (_) {
      // Ignorer l'erreur pour forcer la deconnexion locale
    } finally {
      await ApiClient.setToken(null);
      _currentUser = null;
      _authController.add(null);
    }
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
    try {
      final response = await ApiClient.post('/register', {
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'email': email.trim(),
        'password': password,
        'sexe': sexe,
        'role': 'client', // role par defaut pour l'inscription
        if (telephone != null && telephone.isNotEmpty)
          'telephone': telephone,
      });

      if (response != null && response['access_token'] != null) {
        await ApiClient.setToken(response['access_token']);
        _currentUser = User.fromJson(response['user']);
        _authController.add(_currentUser);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    required String sexe,
  }) async {
    try {
      final response = await ApiClient.put('/user/profile', {
        'nom': nom.trim(),
        'prenom': prenom.trim(),
        'email': email.trim(),
        'sexe': sexe,
      });

      if (response != null && response['user'] != null) {
        _currentUser = User.fromJson(response['user']);
        _authController.add(_currentUser);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final data = await ApiClient.get('/admin/users');
      if (data is List) {
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> setAccountActive(int userId, bool isActive) async {
    try {
      // Laravel attend 'bloque' => boolean (true pour bloquer, false pour debloquer)
      await ApiClient.post('/admin/users/$userId/bloquer', {
        'bloque': !isActive,
      });
      // Mettre a jour localement si c'est l'utilisateur en cours
      if (_currentUser?.id == userId) {
        _currentUser = _currentUser!.copyWith(isActive: isActive);
        _authController.add(_currentUser);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  void setRole(String role) {
    // Permet de forcer localement un role pour le dev si besoin, 
    // mais dans une vraie API ce role depend de la reponse serveur.
    if (role == 'visiteur') {
      ApiClient.setToken(null);
      _currentUser = null;
      _authController.add(null);
    } else if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: role);
      _authController.add(_currentUser);
    }
  }

  void dispose() {
    _tokenSubscription?.cancel();
    _authController.close();
  }
}

// Implementation de RestaurantService via API HTTP
class HttpRestaurantService implements RestaurantService {
  @override
  Future<List<Restaurant>> getRestaurants() async {
    try {
      final data = await ApiClient.get('/restaurants');
      if (data is List) {
        return data.map((json) => Restaurant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      final data = await ApiClient.get('/restaurants?search=${Uri.encodeComponent(query)}');
      if (data is List) {
        return data.map((json) => Restaurant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Restaurant>> getRestaurantsByBudget(double maxBudget) async {
    try {
      final data = await ApiClient.get('/restaurants?max_budget=$maxBudget');
      if (data is List) {
        return data.map((json) => Restaurant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Restaurant?> getRestaurantById(int id) async {
    try {
      final data = await ApiClient.get('/restaurants/$id');
      if (data != null) {
        return Restaurant.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Restaurant?> getRestaurantByQrCode(String code) async {
    try {
      final data = await ApiClient.get('/restaurants/qr/$code');
      if (data != null) {
        return Restaurant.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ExplorationList>> getExplorationLists() async {
    try {
      // Recupere les explorations de l'utilisateur connecte
      final data = await ApiClient.get('/explorations');
      final List<Restaurant> exploredRestaurants = [];
      if (data is List) {
        for (final item in data) {
          if (item['restaurant'] != null) {
            exploredRestaurants.add(Restaurant.fromJson(item['restaurant']));
          }
        }
      }
      // On encapsule dans l'unique liste d'exploration attendue par l'UI
      return [
        ExplorationList(
          id: 1,
          nom: 'À explorer',
          adresses: exploredRestaurants,
          isShared: false,
          iconTypes: ['⭐'],
        )
      ];
    } catch (e) {
      return [
        const ExplorationList(
          id: 1,
          nom: 'À explorer',
          adresses: [],
          isShared: false,
          iconTypes: ['⭐'],
        )
      ];
    }
  }

  @override
  Future<void> createExplorationList(
    String name,
    bool isShared,
    List<String> iconTypes,
  ) async {
    // Le backend ne supportant pas de multiples listes nommees personnalisees, 
    // cette operation est locale ou sans effet.
    return;
  }

  @override
  Future<void> addRestaurantToExploration(int listId, int restaurantId) async {
    try {
      // Laravel expose /api/restaurants/{id}/explore
      await ApiClient.post('/restaurants/$restaurantId/explore', {});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PlatCategory>> getCategories() async {
    try {
      final data = await ApiClient.get('/categories');
      if (data is List) {
        return data.map((json) => PlatCategory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PlatCategory> getOrCreateCategory(String libelle) async {
    final trimmed = libelle.trim();
    if (trimmed.isEmpty) {
      throw Exception('Le nom de la categorie est obligatoire.');
    }

    try {
      final categories = await getCategories();
      for (final category in categories) {
        if (category.libelle.toLowerCase() == trimmed.toLowerCase()) {
          return category;
        }
      }

      final response = await ApiClient.post('/categories', {
        'libelle': trimmed,
      });
      return PlatCategory.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<int> _resolveCategoryId(String categoryName) async {
    final category = await getOrCreateCategory(categoryName);
    return category.id;
  }

  @override
  Future<void> addPlatToRestaurant(int restaurantId, Plat plat) async {
    try {
      await ApiClient.post('/plats', {
        'nom': plat.nom,
        'description': plat.description,
        'prix': plat.prix,
        'disponible': plat.disponible,
        'restaurant_id': restaurantId,
        'categorie_id': await _resolveCategoryId(plat.categorie),
        'image_url': plat.imageUrl,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePlatInRestaurant(int restaurantId, Plat plat) async {
    try {
      await ApiClient.put('/plats/${plat.id}', {
        'nom': plat.nom,
        'description': plat.description,
        'prix': plat.prix,
        'disponible': plat.disponible,
        'categorie_id': await _resolveCategoryId(plat.categorie),
        'image_url': plat.imageUrl,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removePlatFromRestaurant(int restaurantId, int platId) async {
    try {
      await ApiClient.delete('/plats/$platId');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Restaurant>> getRestaurantsByManager(int managerId) async {
    try {
      final data = await ApiClient.get('/restaurants?manager_id=$managerId');
      if (data is List) {
        return data.map((json) => Restaurant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Restaurant> createRestaurant(Restaurant restaurant) async {
    try {
      final response = await ApiClient.post('/restaurants', {
        'nom': restaurant.nom,
        'adresse': restaurant.adresse,
        'quartier': restaurant.quartier,
        'categorie': restaurant.categorie,
        'type_cuisine': restaurant.typeCuisine,
        'latitude': restaurant.latitude,
        'longitude': restaurant.longitude,
        'superficie': restaurant.superficie ?? 150,
        // Documents légaux transmis après upload séparé
        if (restaurant.cipUrl != null) 'cip_url': restaurant.cipUrl,
        if (restaurant.ifuNumero != null) 'ifu_numero': restaurant.ifuNumero,
        if (restaurant.ifuAttestationUrl != null) 'ifu_attestation_url': restaurant.ifuAttestationUrl,
        if (restaurant.rccmNumero != null) 'rccm_numero': restaurant.rccmNumero,
        if (restaurant.rccmExtraitUrl != null) 'rccm_extrait_url': restaurant.rccmExtraitUrl,
      });

      if (response != null && response['restaurant'] != null) {
        return Restaurant.fromJson(response['restaurant']);
      }
      throw Exception('Erreur de creation du restaurant');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateRestaurant({
    required int id,
    required String name,
    required String address,
    String? logoUrl,
    String? photoUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        'nom': name,
        'adresse': address,
      };
      if (logoUrl != null) {
        payload['logo_url'] = logoUrl;
      }
      if (photoUrl != null) {
        payload['photo_url'] = photoUrl;
      }
      await ApiClient.put('/restaurants/$id', payload);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String> uploadImage(XFile file, {required String type}) async {
    return ApiClient.uploadImage(file, type: type);
  }

  @override
  Future<String> uploadDocument(XFile file, {required String type}) async {
    // Upload multipart vers /upload/document avec le champ 'document'
    return ApiClient.uploadFile(file, endpoint: '/upload/document', fieldName: 'document', type: type);
  }
}

// Implementation de ReviewService via API HTTP
class HttpReviewService implements ReviewService {
  @override
  Future<List<Avis>> getReviewsForRestaurant(int restaurantId) async {
    try {
      final data = await ApiClient.get('/restaurants/$restaurantId/avis');
      if (data is List) {
        return data.map((json) => Avis.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Avis>> getAllReviews() async {
    try {
      final data = await ApiClient.get('/avis');
      if (data is List) {
        return data.map((json) => Avis.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
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
    try {
      await ApiClient.post('/avis', {
        'restaurant_id': restaurantId,
        'note': note,
        'commentaire': comment,
        'latitude_client': lat,
        'longitude_client': lon,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> reportReview({
    required int avisId,
    required String reason,
    required String reporterName,
  }) async {
    try {
      await ApiClient.post('/avis/$avisId/signal', {
        'libelle': reason,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Signalement>> getSignalements() async {
    try {
      final data = await ApiClient.get('/admin/signalements');
      if (data is List) {
        return data.map((json) => Signalement.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> handleSignalement(int signalementId, bool keepReview) async {
    try {
      await ApiClient.post('/admin/signalements/$signalementId/handle', {
        'keep_review': keepReview,
      });
    } catch (e) {
      rethrow;
    }
  }
}

// Service admin pour les demandes d'inscription restaurant
class HttpAdminService implements AdminService {
  @override
  Future<List<DemandeRestaurant>> getDemandes() async {
    try {
      final data = await ApiClient.get('/admin/demandes');
      if (data is List) {
        return data.map((json) => DemandeRestaurant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> validerDemande(
    int restaurantId, {
    required bool accepte,
    String? motifRejet,
  }) async {
    await ApiClient.patch(
      '/admin/restaurants/$restaurantId/valider',
      {
        'est_valide': accepte,
        if (!accepte && motifRejet != null) 'motif_rejet': motifRejet,
      },
    );
  }
}
