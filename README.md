# TruEats - Plateforme d'Avis Fiables pour Restaurants

TruEats est une application mobile moderne et sécurisée conçue pour faciliter l'interaction entre les clients et les restaurants. L'application permet aux clients de scanner le code QR d'une table pour accéder instantanément au menu et soumettre des avis certifiés grâce à une double-validation géographique par GPS. Elle intègre également une recherche de restaurant par budget, un espace gérant complet pour l'administration des établissements et une console d'administration pour la modération globale.

---

## 🚀 Fonctionnalités Clés

* **Scannage de Code QR :** Accès instantané à la carte du restaurant et de la table correspondante.
* **Avis Clients Certifiés par GPS :** Limitation géographique (distance max. configurable grâce à la formule d'Haversine) pour s'assurer que seuls les clients physiquement présents dans l'établissement peuvent soumettre une note et un commentaire.
* **Recherche de restaurant par budget :** Recherche facile pour trouver des restaurants selon le budget ainsi que la ville.
* **Espace Gérant Dynamique :** Inscription de restaurant par demande, édition rapide des informations, horaires d'ouverture hebdomadaires détaillés.
* **Console d'Administration Globale :** Validation/rejet des inscriptions de restaurants (avec motif en cas de rejet), modération des avis signalés, et activation/suspension des comptes gérants/clients.
* **Base de Localisation du Bénin :** Intégration complète de la base de données administrative officielle du Bénin (77 communes et plus de 5 300 quartiers et arrondissements).

---

## 🛠️ Technologies et Langages Utilisés

L'application est construite sur une architecture découplée (API First) :

### 📱 Frontend (Mobile & Web)
* **Langage :** Dart
* **Framework :** Flutter (Material 3)
* **Bibliothèques principales :**
  - `mobile_scanner` pour la lecture native des QR codes.
  - `geolocator` et `permission_handler` pour la récupération et la gestion des droits GPS.
  - `share_plus` pour le téléchargement et le partage natif des QR codes générés.

### 🖥️ Backend (API REST)
* **Langage :** PHP
* **Framework :** Laravel 10/11
* **Base de données :** MySQL 

---

## 🔒 Sécurisation et Protection des Données

La sécurité est au cœur de l'architecture de TruEats. Plusieurs mécanismes protègent l'application et sa base de données :

### 1. Protection contre les Injections SQL
Toutes les interactions avec la base de données sont blindées contre les injections SQL :
* **ORM Eloquent & Query Builder :** TruEats utilise l'ORM Eloquent de Laravel pour toutes les requêtes de données. Eloquent utilise en arrière-plan **PDO (PHP Data Objects)** pour toutes les opérations de lecture et d'écriture. PDO recourt systématiquement aux **requêtes préparées (Prepared Statements)** avec liaison de paramètres (parameter binding). 
* **Parameter Binding automatique :** Lorsque des requêtes complexes sont construites (ex: `Restaurant::where('uuid', $uuid)->first()`), la valeur de la variable `$uuid` est automatiquement échappée et traitée comme un paramètre de donnée pure, et non comme du code SQL exécutable.
* **Interdiction des requêtes brutes non sécurisées :** Aucun appel de type `DB::raw()` exposant des variables brutes non échappées n'est utilisé.

### 2. Validation et Assainissement des Entrées (Sanitization)
* **Form Validation :** Toutes les requêtes HTTP entrantes (connexion, inscription, avis, modification de restaurant) font l'objet d'une validation stricte au niveau du contrôleur (ex: `RestaurantController` et `AuthController`). Les données sont typées, limitées en longueur, et validées par rapport à des expressions régulières ou des listes d'exclusion avant tout traitement.
* **Échappement XSS :** Les données textuelles affichées ou enregistrées sont nettoyées pour empêcher l'exécution de scripts malveillants injectés par les utilisateurs (XSS).

### 3. Authentification et Autorisation (Contrôle d'Accès)
* **Middleswares de Sécurité :** L'accès aux routes API d'administration et de gestion est protégé par le middleware d'authentification Laravel (via jetons JWT sécurisés).
* **Vérification de Propriété :** Un gérant ne peut modifier ou supprimer *que* les restaurants qui lui appartiennent. Cette vérification est effectuée côté serveur à chaque appel d'API pour empêcher toute usurpation d'identifiant (ID-spoofing).

### 4. Anti-Triche GPS (Double-Vérification)
Pour garantir la véracité des avis déposés :
* Une première vérification est faite côté client (Flutter) pour adapter l'interface utilisateur.
* Une **seconde vérification obligatoire** est exécutée côté serveur (Laravel) en recalculant la distance réelle (formule de Haversine) entre les coordonnées GPS envoyées par l'appareil et celles enregistrées du restaurant. Cela empêche les utilisateurs malveillants de contourner la sécurité en effectuant des requêtes directes vers l'API.

---

## 📦 Lancement et Déploiement

### Backend (Laravel)
1. Installez les dépendances : `composer install`
2. Configurez le fichier `.env` (connexion base de données)
3. Exécutez les migrations et alimentez la base de données : `php artisan migrate:fresh --seed`
4. Lancez le serveur local : `php artisan serve`

### Frontend (Flutter)
1. Récupérez les dépendances : `flutter pub get`
2. Lancez l'application en mode développement : `flutter run`
3. Générez l'APK de production : `flutter build apk --release`

