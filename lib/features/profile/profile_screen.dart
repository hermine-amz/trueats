import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';
import '../gerant/gerant_dashboard.dart';
import '../gerant/register_restaurant_screen.dart';
import '../admin/admin_console.dart';
import '../../core/widgets/app_feedback.dart';
import 'edit_profile_screen.dart';
import 'explorations_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  int _exploreCount = 0;
  int _publishedReviewsCount = 0;
  List<Restaurant> _pendingRestaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // On rafraichit d'abord le user depuis l'API pour avoir le role a jour
    try {
      await ServiceLocator.authService.refreshCurrentUser();
    } catch (_) {}

    final user = ServiceLocator.authService.currentUser;
    final lists = await ServiceLocator.restaurantService.getExplorationLists();
    final reviews = await ServiceLocator.reviewService.getAllReviews();
    final managedRestaurants = user == null || user.role == 'visiteur'
        ? <Restaurant>[]
        : await ServiceLocator.restaurantService.getRestaurantsByManager(
            user.id,
          );
    final exploreLists = lists.where(_isExploreList).toList();
    final pendingRestaurants = managedRestaurants
        .where((restaurant) => !restaurant.estValide)
        .toList();

    if (!mounted) return;

    setState(() {
      _currentUser = user;
      _pendingRestaurants = pendingRestaurants;
      _exploreCount = exploreLists.fold<int>(
        0,
        (total, list) => total + list.adresses.length,
      );
      _publishedReviewsCount = user == null
          ? 0
          : reviews
                .where(
                  (review) => review.nomAuteur == user.name && review.estPublie,
                )
                .length;
      _isLoading = false;
    });
  }

  bool _isExploreList(ExplorationList list) {
    final normalized = list.nom.toLowerCase().trim();
    return normalized == 'a explorer' || normalized == 'à explorer';
  }

  Future<void> _onExplorationsTap() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ExplorationsScreen()));
    _loadProfile();
  }

  Future<void> _onGestionRestaurantsTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GerantDashboard()),
    );
    _loadProfile();
  }

  Future<void> _onInscriptionRestaurantTap() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const RegisterRestaurantScreen()),
    );
    // Qu'il y ait eu soumission ou non, on recharge le profil
    // pour mettre a jour le role si l'admin a entre-temps valide un restaurant
    _loadProfile();
  }

  Future<void> _logout() async {
    await ServiceLocator.authService.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSettingsSheet() {
    final user = _currentUser;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.creme,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Parametres",
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                _buildSettingsTile(
                  context,
                  icon: Icons.edit_outlined,
                  title: "Editer profil",
                  subtitle: "Nom, prenom, email et sexe",
                  onTap: user == null
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfileScreen(user: user),
                                ),
                              );
                          if (updated == true) {
                            _loadProfile();
                          }
                        },
                ),

                if (user != null)
                  _buildSettingsTile(
                    context,
                    icon: Icons.delete_forever_outlined,
                    title: "Supprimer mon compte",
                    subtitle: "Suppression définitive et immédiate",
                    onTap: () async {
                      Navigator.of(context).pop();
                      final confirmed = await showAppConfirmDialog(
                        context,
                        title: "Supprimer mon compte ?",
                        message: "Cette action est irréversible. Toutes vos données seront définitivement supprimées.",
                        confirmLabel: "Supprimer",
                        cancelLabel: "Annuler",
                        icon: Icons.delete_forever_outlined,
                        type: AppFeedbackType.error,
                      );
                      if (confirmed == true) {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          await ServiceLocator.authService.deleteAccount();
                          if (!mounted) return;
                          showAppNotification(
                            context,
                            title: "Compte supprimé",
                            message: "Votre compte a été définitivement supprimé.",
                            type: AppFeedbackType.success,
                          );
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setState(() {
                            _isLoading = false;
                          });
                          showAppNotification(
                            context,
                            title: "Erreur",
                            message: "Impossible de supprimer le compte : $e",
                            type: AppFeedbackType.error,
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = _currentUser;
    final isVisitor = user == null || user.role == 'visiteur';

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _isLoading
                  ? const SizedBox(
                      height: 420,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: AppColors.marronFonce,
                            ),
                            onPressed: _showSettingsSheet,
                          ),
                        ),
                        Text(
                          "PROFIL",
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.terracotta,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.name ?? "Visiteur",
                          style: textTheme.displayLarge?.copyWith(fontSize: 30),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isVisitor ? "Session invitee" : user.email,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.grisTexte,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            _buildStatCard(
                              context,
                              _publishedReviewsCount.toString(),
                              "AVIS",
                            ),
                            const SizedBox(width: 10),
                            _buildStatCard(
                              context,
                              _exploreCount.toString(),
                              "A EXPLORER",
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          "MON ESPACE",
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.grisTexte,
                            fontSize: 11,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildActivityRow(
                          context,
                          Icons.bookmark_border_rounded,
                          "A explorer",
                          _exploreCount == 0
                              ? "Aucun restaurant ajoute"
                              : "$_exploreCount restaurant${_exploreCount > 1 ? 's' : ''} ajoute${_exploreCount > 1 ? 's' : ''}",
                          _onExplorationsTap,
                        ),
                        const SizedBox(height: 18),
                        if (_currentUser?.role == 'admin') ...[
                          _buildActivityRow(
                            context,
                            Icons.admin_panel_settings_outlined,
                            "Console Administration",
                            "Accéder aux outils de supervision",
                            () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const AdminConsole(),
                                ),
                              );
                              _loadProfile();
                            },
                          ),
                          const SizedBox(height: 36),
                        ] else if (_currentUser?.role == 'gerant') ...[
                          _buildActivityRow(
                            context,
                            Icons.storefront_outlined,
                            "Gestion restaurants",
                            "Voir mes etablissements",
                            _onGestionRestaurantsTap,
                          ),
                          const SizedBox(height: 14),
                          _buildActivityRow(
                            context,
                            Icons.add_business_outlined,
                            "Inscription restaurant",
                            "Ajouter un nouveau restaurant",
                            _onInscriptionRestaurantTap,
                          ),
                          const SizedBox(height: 36),
                        ] else if (_currentUser?.role == 'utilisateur') ...[
                          if (_pendingRestaurants.isEmpty)
                            _buildBecomeGerantBanner(context)
                          else
                            _buildPendingRestaurantBanner(context),
                          const SizedBox(height: 36),
                        ] else
                          const SizedBox(height: 36),
                        if (!isVisitor)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _logout,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.rougeSignalement,
                                side: const BorderSide(
                                  color: AppColors.grisBordure,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text("Se deconnecter"),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: onTap != null,
      leading: CircleAvatar(
        backgroundColor: AppColors.orangeClair,
        child: Icon(icon, color: AppColors.terracotta),
      ),
      title: Text(title, style: textTheme.titleLarge?.copyWith(fontSize: 15)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grisTexte),
      onTap: onTap,
    );
  }



  Widget _buildStatCard(BuildContext context, String value, String label) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.displayMedium?.copyWith(
                color: AppColors.terracotta,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.grisTexte,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: _cardDecoration(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.orangeClair,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.terracotta, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.grisTexte,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFDFBF7),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.grisBordure),
    );
  }

  // Banniere "Devenir gerant" visible pour les simples clients inscrits.
  Widget _buildBecomeGerantBanner(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: _onInscriptionRestaurantTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF9EFE7), Color(0xFFFDFBF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.orangeClair,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: AppColors.terracotta,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Proposer mon restaurant",
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.marronFonce,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Soumettez votre etablissement pour validation. Votre compte passera gerant apres accord admin.",
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppColors.grisTexte,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.terracotta,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRestaurantBanner(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = _pendingRestaurants.length;
    final firstRestaurant = _pendingRestaurants.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grisBordure),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.cremeFonce,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_outlined,
              color: AppColors.terracotta,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1
                      ? "Demande en attente"
                      : "$count demandes en attente",
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.marronFonce,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count == 1
                      ? "${firstRestaurant.nom} est en cours de validation par l admin."
                      : "Vos restaurants soumis sont en cours de validation par l admin.",
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: AppColors.grisTexte,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
