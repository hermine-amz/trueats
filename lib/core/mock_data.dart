class PlatCategory {
  final int id;
  final String libelle;

  const PlatCategory({
    required this.id,
    required this.libelle,
  });

  factory PlatCategory.fromJson(Map<String, dynamic> json) {
    return PlatCategory(
      id: json['id'] as int,
      libelle: json['libelle'] as String? ?? '',
    );
  }
}

class Plat {
  final int id;
  final String nom;
  final String description;
  final double prix;
  final bool disponible;
  final String categorie; // ex: Entrée, Plat Principal, Dessert, Boisson
  final String? imageUrl;

  const Plat({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.disponible,
    required this.categorie,
    this.imageUrl,
  });

  factory Plat.fromJson(Map<String, dynamic> json) {
    String categoryName = 'Plats';
    if (json['category'] != null && json['category']['libelle'] != null) {
      categoryName = json['category']['libelle'];
    } else if (json['categorie'] != null) {
      categoryName = json['categorie'];
    }
    
    return Plat(
      id: json['id'],
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      prix: (json['prix'] as num?)?.toDouble() ?? 0.0,
      disponible: json['disponible'] == 1 || json['disponible'] == true || json['disponible'] == null,
      categorie: categoryName,
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'prix': prix,
      'disponible': disponible,
      'categorie': categorie,
      'image_url': imageUrl,
    };
  }

  Plat copyWith({
    int? id,
    String? nom,
    String? description,
    double? prix,
    bool? disponible,
    String? categorie,
    String? imageUrl,
  }) {
    return Plat(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      disponible: disponible ?? this.disponible,
      categorie: categorie ?? this.categorie,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class Avis {
  final int id;
  final String nomAuteur;
  final int note; // sur 5
  final String commentaire;
  final DateTime dateVisite;
  final double latClient;
  final double longClient;
  final bool estPublie;
  final bool isVerified;
  final String? photoUrl;
  final int restaurantId;
  final String restaurantNom;
  final bool estAnonyme;
  final int? userId;

  Avis({
    required this.id,
    required this.nomAuteur,
    required this.note,
    required this.commentaire,
    required this.dateVisite,
    required this.latClient,
    required this.longClient,
    required this.estPublie,
    required this.isVerified,
    this.photoUrl,
    required this.restaurantId,
    required this.restaurantNom,
    this.estAnonyme = false,
    this.userId,
  });

  factory Avis.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final restaurantJson = json['restaurant'];

    String authorName = 'Utilisateur';
    if (userJson != null) {
      final prenom = userJson['prenom'] ?? '';
      final nom = userJson['nom'] ?? '';
      authorName = '$prenom $nom'.trim();
      if (authorName.isEmpty) {
        authorName = userJson['email']?.split('@')?.first ?? 'Utilisateur';
      }
    } else if (json['nom_auteur'] != null) {
      authorName = json['nom_auteur'];
    }

    final lat = (json['lat_client'] as num?)?.toDouble() ?? 0.0;
    final lon = (json['long_client'] as num?)?.toDouble() ?? 0.0;
    final estAnonymeVal = json['est_anonyme'] == 1 || json['est_anonyme'] == true;

    return Avis(
      id: json['id'] as int? ?? 0,
      nomAuteur: estAnonymeVal ? 'Anonyme' : authorName,
      note: json['note'] as int? ?? 5,
      commentaire: json['commentaire'] as String? ?? '',
      dateVisite: json['date_visite'] != null
          ? DateTime.parse(json['date_visite'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      latClient: lat,
      longClient: lon,
      estPublie: json['est_publie'] == 1 || json['est_publie'] == true || json['est_publie'] == null,
      isVerified: lat != 0.0 && lon != 0.0,
      photoUrl: json['photo_url'] as String?,
      restaurantId: json['restaurant_id'] as int? ?? (restaurantJson?['id'] as int? ?? 0),
      restaurantNom: restaurantJson != null ? (restaurantJson['nom'] as String? ?? 'Restaurant') : (json['restaurant_nom'] as String? ?? 'Restaurant'),
      estAnonyme: estAnonymeVal,
      userId: userJson != null ? userJson['id'] as int? : json['user_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': note,
      'commentaire': commentaire,
      'date_visite': dateVisite.toIso8601String(),
      'lat_client': latClient,
      'long_client': longClient,
      'est_publie': estPublie,
      'restaurant_id': restaurantId,
      'est_anonyme': estAnonyme,
      'user_id': userId,
    };
  }

  Avis copyWith({
    int? id,
    String? nomAuteur,
    int? note,
    String? commentaire,
    DateTime? dateVisite,
    double? latClient,
    double? longClient,
    bool? estPublie,
    bool? isVerified,
    String? photoUrl,
    int? restaurantId,
    String? restaurantNom,
    bool? estAnonyme,
    int? userId,
  }) {
    return Avis(
      id: id ?? this.id,
      nomAuteur: nomAuteur ?? this.nomAuteur,
      note: note ?? this.note,
      commentaire: commentaire ?? this.commentaire,
      dateVisite: dateVisite ?? this.dateVisite,
      latClient: latClient ?? this.latClient,
      longClient: longClient ?? this.longClient,
      estPublie: estPublie ?? this.estPublie,
      isVerified: isVerified ?? this.isVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantNom: restaurantNom ?? this.restaurantNom,
      estAnonyme: estAnonyme ?? this.estAnonyme,
      userId: userId ?? this.userId,
    );
  }
}

class Restaurant {
  final int id;
  final String nom;
  final String? telephone;
  final String? horaires;
  final String adresse;
  final String quartier;
  final String categorie;
  final String typeCuisine;
  final String? logoUrl;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final String qrCode;
  final DateTime dateCreation;
  final List<Plat> menu;
  // superficie en m² — le rayon GPS est calculé côté backend (sqrt(S/π) + marge)
  final int? superficie;
  final double rayonMetres; // rayon reçu du backend, utilisé pour vérif GPS
  final int? gerantId;
  final bool estValide;
  // Champs légaux (non affichés aux clients)
  final String? cipUrl;
  final String? ifuNumero;
  final String? ifuAttestationUrl;
  // Motif de rejet de validation (null si non rejeté)
  final String? motifRejet;
  final bool estArchive;

  const Restaurant({
    required this.id,
    required this.nom,
    this.telephone,
    this.horaires,
    required this.adresse,
    required this.quartier,
    required this.categorie,
    required this.typeCuisine,
    this.logoUrl,
    this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.qrCode,
    required this.dateCreation,
    required this.menu,
    this.superficie,
    this.rayonMetres = 150.0,
    this.gerantId,
    this.estValide = true,
    this.cipUrl,
    this.ifuNumero,
    this.ifuAttestationUrl,
    this.motifRejet,
    this.estArchive = false,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final menuList = <Plat>[];
    if (json['plats'] != null) {
      for (final item in json['plats']) {
        menuList.add(Plat.fromJson(item));
      }
    }

    return Restaurant(
      id: json['id'],
      nom: json['nom'] ?? '',
      telephone: json['telephone'],
      horaires: json['horaires'],
      adresse: json['adresse'] ?? '',
      quartier: json['quartier'] ?? 'Cotonou',
      categorie: json['categorie'] ?? 'Restaurant',
      typeCuisine: json['type_cuisine'] ?? 'Cuisine',
      logoUrl: json['logo_url'],
      photoUrl: json['photo_url'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      qrCode: json['qr_code_identifier'] ?? json['qr_code'] ?? '',
      dateCreation: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      menu: menuList,
      superficie: json['superficie'] as int?,
      rayonMetres: (json['rayon_validation'] as num?)?.toDouble() ?? (json['rayon_metres'] as num?)?.toDouble() ?? 150.0,
      gerantId: json['gerant_id'],
      estValide: json['est_valide'] == 1 || json['est_valide'] == true,
      cipUrl: json['cip_url'],
      ifuNumero: json['ifu_numero'],
      ifuAttestationUrl: json['ifu_attestation_url'],
      motifRejet: json['motif_rejet'],
      estArchive: json['est_archive'] == 1 || json['est_archive'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'horaires': horaires,
      'adresse': adresse,
      'quartier': quartier,
      'categorie': categorie,
      'type_cuisine': typeCuisine,
      'logo_url': logoUrl,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'qr_code_identifier': qrCode,
      'gerant_id': gerantId,
      'superficie': superficie,
      'rayon_validation': rayonMetres,
      'est_archive': estArchive,
    };
  }

  Restaurant copyWith({
    int? id,
    String? nom,
    String? telephone,
    String? horaires,
    String? adresse,
    String? quartier,
    String? categorie,
    String? typeCuisine,
    String? logoUrl,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? qrCode,
    DateTime? dateCreation,
    List<Plat>? menu,
    int? superficie,
    double? rayonMetres,
    int? gerantId,
    bool? estValide,
    String? cipUrl,
    String? ifuNumero,
    String? ifuAttestationUrl,
    String? motifRejet,
    bool? estArchive,
  }) {
    return Restaurant(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      horaires: horaires ?? this.horaires,
      adresse: adresse ?? this.adresse,
      quartier: quartier ?? this.quartier,
      categorie: categorie ?? this.categorie,
      typeCuisine: typeCuisine ?? this.typeCuisine,
      logoUrl: logoUrl ?? this.logoUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      qrCode: qrCode ?? this.qrCode,
      dateCreation: dateCreation ?? this.dateCreation,
      menu: menu ?? this.menu,
      superficie: superficie ?? this.superficie,
      rayonMetres: rayonMetres ?? this.rayonMetres,
      gerantId: gerantId ?? this.gerantId,
      estValide: estValide ?? this.estValide,
      cipUrl: cipUrl ?? this.cipUrl,
      ifuNumero: ifuNumero ?? this.ifuNumero,
      ifuAttestationUrl: ifuAttestationUrl ?? this.ifuAttestationUrl,
      motifRejet: motifRejet ?? this.motifRejet,
      estArchive: estArchive ?? this.estArchive,
    );
  }
}

// Modèle pour les demandes d'inscription vues depuis la console admin
class DemandeRestaurant {
  final int id;
  final String nom;
  final String adresse;
  final String? quartier;
  final String? categorie;
  final String? typeCuisine;
  final int? superficie;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String? cipUrl;
  final String? ifuNumero;
  final String? ifuAttestationUrl;
  final Map<String, dynamic>? gerant;
  final bool estValide;
  final String? motifRejet;

  const DemandeRestaurant({
    required this.id,
    required this.nom,
    required this.adresse,
    this.quartier,
    this.categorie,
    this.typeCuisine,
    this.superficie,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.cipUrl,
    this.ifuNumero,
    this.ifuAttestationUrl,
    this.gerant,
    this.estValide = false,
    this.motifRejet,
  });

  factory DemandeRestaurant.fromJson(Map<String, dynamic> json) {
    return DemandeRestaurant(
      id: json['id'],
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      quartier: json['quartier'],
      categorie: json['categorie'],
      typeCuisine: json['type_cuisine'],
      superficie: json['superficie'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      cipUrl: json['cip_url'],
      ifuNumero: json['ifu_numero'],
      ifuAttestationUrl: json['ifu_attestation_url'],
      gerant: json['gerant'] as Map<String, dynamic>?,
      estValide: json['est_valide'] == 1 || json['est_valide'] == true,
      motifRejet: json['motif_rejet'],
    );
  }
}

class ExplorationList {
  final int id;
  final String nom;
  final List<Restaurant> adresses;
  final bool isShared;
  final List<String> iconTypes; // croissants, donuts, cocktail, etc.

  const ExplorationList({
    required this.id,
    required this.nom,
    required this.adresses,
    required this.isShared,
    required this.iconTypes,
  });

  factory ExplorationList.fromJson(Map<String, dynamic> json) {
    final list = <Restaurant>[];
    if (json['adresses'] != null) {
      for (final item in json['adresses']) {
        list.add(Restaurant.fromJson(item));
      }
    }
    return ExplorationList(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? 'À explorer',
      adresses: list,
      isShared: json['is_shared'] == 1 || json['is_shared'] == true,
      iconTypes: json['icon_types'] != null ? List<String>.from(json['icon_types']) : ['⭐'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'adresses': adresses.map((e) => e.toJson()).toList(),
      'is_shared': isShared,
      'icon_types': iconTypes,
    };
  }
}

class Signalement {
  final int id;
  final int avisId;
  final Avis avis;
  final String auteurSignalement;
  final String raison;
  final DateTime dateSignalement;
  final bool estTraite;
  final String? decision;

  const Signalement({
    required this.id,
    required this.avisId,
    required this.avis,
    required this.auteurSignalement,
    required this.raison,
    required this.dateSignalement,
    this.estTraite = false,
    this.decision,
  });

  factory Signalement.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    String authorName = 'Utilisateur';
    if (userJson != null) {
      final prenom = userJson['prenom'] ?? '';
      final nom = userJson['nom'] ?? '';
      authorName = '$prenom $nom'.trim();
      if (authorName.isEmpty) {
        authorName = userJson['email']?.split('@')?.first ?? 'Utilisateur';
      }
    }

    return Signalement(
      id: json['id'],
      avisId: json['avis_id'],
      avis: json['avis'] != null ? Avis.fromJson(json['avis']) : Avis(
        id: json['avis_id'],
        nomAuteur: 'Auteur',
        note: 5,
        commentaire: 'Avis inconnu',
        dateVisite: DateTime.now(),
        latClient: 0.0,
        longClient: 0.0,
        estPublie: true,
        isVerified: false,
        restaurantId: 0,
        restaurantNom: 'Restaurant',
      ),
      auteurSignalement: authorName,
      raison: json['libelle'] ?? 'Contenu inopportun',
      dateSignalement: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      estTraite: json['est_traite'] == 1 || json['est_traite'] == true,
      decision: json['decision'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'avis_id': avisId,
      'avis': avis.toJson(),
      'auteur_signalement': auteurSignalement,
      'raison': raison,
      'date_signalement': dateSignalement.toIso8601String(),
    };
  }
}

// Données statiques initiales
class MockData {
  static final List<Plat> menuTanti = [
    const Plat(
      id: 1,
      nom: "Poulet braisé attiéké",
      description:
          "Poulet mariné grillé au charbon de bois, attiéké fondant, sauce oignons et piment.",
      prix: 3500,
      disponible: true,
      categorie: "Plats Principaux",
    ),
    const Plat(
      id: 2,
      nom: "Poisson braisé alloco",
      description:
          "Dorade entière braisée, bananes plantains frites (alloco), sauce piquante.",
      prix: 4200,
      disponible: true,
      categorie: "Plats Principaux",
    ),
    const Plat(
      id: 3,
      nom: "Alloco simple",
      description: "Portion de bananes plantains mûres frites.",
      prix: 1000,
      disponible: true,
      categorie: "Accompagnements",
    ),
    const Plat(
      id: 4,
      nom: "Jus de Bissap maison",
      description: "Jus de fleurs d'hibiscus infusé à la menthe fraîche.",
      prix: 800,
      disponible: true,
      categorie: "Boissons",
    ),
  ];

  static final List<Plat> menuBissap = [
    const Plat(
      id: 10,
      nom: "Toast Avocat & OEuf Poché",
      description:
          "Pain de campagne grillé, purée d'avocat assaisonnée, oeuf poché, graines de courge.",
      prix: 2800,
      disponible: true,
      categorie: "Brunch",
    ),
    const Plat(
      id: 11,
      nom: "Pancakes aux fruits de saison",
      description:
          "Trois pancakes moelleux, sirop d'érable, bananes et mangues fraîches.",
      prix: 2500,
      disponible: true,
      categorie: "Brunch",
    ),
    const Plat(
      id: 12,
      nom: "Café Latte",
      description: "Double expresso avec mousse de lait crémeuse.",
      prix: 1500,
      disponible: true,
      categorie: "Cafétéria",
    ),
    const Plat(
      id: 13,
      nom: "Bissap Royal",
      description: "Bissap avec morceaux de mangue et zeste de citron.",
      prix: 1200,
      disponible: true,
      categorie: "Boissons",
    ),
  ];

  static final List<Plat> menuMarcel = [
    const Plat(
      id: 20,
      nom: "Filet de capitaine grillé",
      description:
          "Poisson capitaine local grillé, purée de patates douces au piment doux.",
      prix: 6500,
      disponible: true,
      categorie: "Plats Principaux",
    ),
    const Plat(
      id: 21,
      nom: "Carpaccio de mangue et sa glace",
      description:
          "Fines tranches de mangues béninoises, glace vanille et coulis de fruits de la passion.",
      prix: 2000,
      disponible: true,
      categorie: "Desserts",
    ),
  ];

  static final List<Restaurant> restaurants = [
    Restaurant(
      id: 1,
      nom: "Maquis Chez Tanti",
      adresse: "Rue 820, Haie-Vive, Cotonou",
      quartier: "Haie-Vive",
      categorie: "Maquis",
      typeCuisine: "Africain",
      logoUrl: null,
      latitude: 6.35712, // Coordonnées mockées
      longitude: 2.40892,
      qrCode: "trueats_restaurant_1",
      dateCreation: DateTime(2025, 6, 1),
      menu: menuTanti,
      rayonMetres: 150,
    ),
    Restaurant(
      id: 2,
      nom: "Le Petit Bissap",
      adresse: "Avenue Jean-Paul II, Cotonou",
      quartier: "Cadjehoun",
      categorie: "Café",
      typeCuisine: "Brunch",
      logoUrl: null,
      latitude: 6.35245,
      longitude: 2.39956,
      qrCode: "trueats_restaurant_2",
      dateCreation: DateTime(2025, 8, 12),
      menu: menuBissap,
      rayonMetres: 100,
    ),
    Restaurant(
      id: 3,
      nom: "Chez Marcel",
      adresse: "Zone Résidentielle, Cotonou",
      quartier: "Patte d'Oie",
      categorie: "Restaurant",
      typeCuisine: "Fusion",
      logoUrl: null,
      latitude: 6.36100,
      longitude: 2.42150,
      qrCode: "trueats_restaurant_3",
      dateCreation: DateTime(2024, 12, 5),
      menu: menuMarcel,
      rayonMetres: 200,
      gerantId: 2,
    ),
  ];

  // Liste initiale des avis
  static final List<Avis> initialAvis = [
    Avis(
      id: 101,
      nomAuteur: "Sophie Client",
      note: 4,
      commentaire:
          "Le poulet braisé était parfaitement assaisonné, l'attiéké fondant. Service rapide, ambiance conviviale...",
      dateVisite: DateTime.now().subtract(const Duration(days: 2)),
      latClient: 6.35710,
      longClient: 2.40890,
      estPublie: true,
      isVerified: true,
      restaurantId: 1,
      restaurantNom: "Maquis Chez Tanti",
      userId: 1,
    ),
    Avis(
      id: 102,
      nomAuteur: "Marc Client",
      note: 5,
      commentaire:
          "Cuisine généreuse, service impeccable. On s'y sent comme à la maison. L'attiéké est incroyable !",
      dateVisite: DateTime.now().subtract(const Duration(days: 5)),
      latClient: 6.35712,
      longClient: 2.40892,
      estPublie: true,
      isVerified: true,
      restaurantId: 1,
      restaurantNom: "Maquis Chez Tanti",
      userId: 2,
    ),
    Avis(
      id: 103,
      nomAuteur: "Afi Client",
      note: 4,
      commentaire:
          "Très bon rapport qualité-prix. Les jus de bissap sont délicieux. Le service peut être un peu lent aux heures de pointe.",
      dateVisite: DateTime.now().subtract(const Duration(days: 8)),
      latClient: 6.35240,
      longClient: 2.39950,
      estPublie: true,
      isVerified: true,
      restaurantId: 2,
      restaurantNom: "Le Petit Bissap",
      userId: 3,
    ),
    Avis(
      id: 104,
      nomAuteur: "Anonyme",
      note: 2,
      commentaire:
          "Service un peu long ce soir-là. La viande était froide et le piment beaucoup trop fort pour ce qui était annoncé.",
      dateVisite: DateTime.now().subtract(const Duration(days: 12)),
      latClient: 6.36100,
      longClient: 2.42150,
      estPublie: true,
      isVerified: true,
      restaurantId: 3,
      restaurantNom: "Chez Marcel",
      userId: null,
    ),
  ];

  // Liste d'explorations pour Marie L.
  static final List<ExplorationList> initialExplorations = [
    ExplorationList(
      id: 1,
      nom: "Brunchs dominicaux",
      adresses: [restaurants[1]], // Le Petit Bissap
      isShared: true,
      iconTypes: ["🥐", "🍩", "🍹"],
    ),
    ExplorationList(
      id: 2,
      nom: "Tables d'hiver",
      adresses: [restaurants[0], restaurants[2]], // Chez Tanti & Chez Marcel
      isShared: false,
      iconTypes: ["🍲", "🍷"],
    ),
    ExplorationList(
      id: 3,
      nom: "Cafés pour télétravailler",
      adresses: [restaurants[1]],
      isShared: true,
      iconTypes: ["☕", "💻"],
    ),
  ];

  // Liste initiale des signalements
  static final List<Signalement> initialSignalements = [
    Signalement(
      id: 1,
      avisId: 104,
      avis: initialAvis[3], // L'avis d'Anonyme sur Chez Marcel
      auteurSignalement: "Gérant Chez Marcel",
      raison:
          "Propos diffamatoires : l'avis mentionne de la viande froide alors que le plat commandé était un filet de poisson.",
      dateSignalement: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Signalement(
      id: 2,
      avisId: 103,
      avis: initialAvis[2], // L'avis de Thomas R. sur Le Petit Bissap
      auteurSignalement: "Anonyme",
      raison: "Photo non pertinente (signalement démo).",
      dateSignalement: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];
}
