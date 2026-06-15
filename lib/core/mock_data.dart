class Plat {
  final int id;
  final String nom;
  final String description;
  final double prix;
  final bool disponible;
  final String categorie; // ex: Entrée, Plat Principal, Dessert, Boisson

  const Plat({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.disponible,
    required this.categorie,
  });

  Plat copyWith({
    int? id,
    String? nom,
    String? description,
    double? prix,
    bool? disponible,
    String? categorie,
  }) {
    return Plat(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      disponible: disponible ?? this.disponible,
      categorie: categorie ?? this.categorie,
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
  });

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
    );
  }
}

class Restaurant {
  final int id;
  final String nom;
  final String adresse;
  final String quartier;
  final String categorie; // ex: Maquis, Café, Resto
  final String typeCuisine; // ex: Africain, Brunch, Européen
  final String? logoUrl;
  final double latitude;
  final double longitude;
  final String qrCode;
  final DateTime dateCreation;
  final List<Plat> menu;
  final double rayonMetres; // Périmètre GPS de tolérance (100 - 200m)
  final int? gerantId;

  const Restaurant({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.quartier,
    required this.categorie,
    required this.typeCuisine,
    this.logoUrl,
    required this.latitude,
    required this.longitude,
    required this.qrCode,
    required this.dateCreation,
    required this.menu,
    this.rayonMetres = 150.0,
    this.gerantId,
  });

  Restaurant copyWith({
    int? id,
    String? nom,
    String? adresse,
    String? quartier,
    String? categorie,
    String? typeCuisine,
    String? logoUrl,
    double? latitude,
    double? longitude,
    String? qrCode,
    DateTime? dateCreation,
    List<Plat>? menu,
    double? rayonMetres,
    int? gerantId,
  }) {
    return Restaurant(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      quartier: quartier ?? this.quartier,
      categorie: categorie ?? this.categorie,
      typeCuisine: typeCuisine ?? this.typeCuisine,
      logoUrl: logoUrl ?? this.logoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      qrCode: qrCode ?? this.qrCode,
      dateCreation: dateCreation ?? this.dateCreation,
      menu: menu ?? this.menu,
      rayonMetres: rayonMetres ?? this.rayonMetres,
      gerantId: gerantId ?? this.gerantId,
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
}

class Signalement {
  final int id;
  final int avisId;
  final Avis avis;
  final String auteurSignalement;
  final String raison;
  final DateTime dateSignalement;

  const Signalement({
    required this.id,
    required this.avisId,
    required this.avis,
    required this.auteurSignalement,
    required this.raison,
    required this.dateSignalement,
  });
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
      nomAuteur: "Marie L.",
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
    ),
    Avis(
      id: 102,
      nomAuteur: "Léa M.",
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
    ),
    Avis(
      id: 103,
      nomAuteur: "Thomas R.",
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
