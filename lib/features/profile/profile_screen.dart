import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';
import '../gerant/managed_restaurants_screen.dart';
import '../gerant/register_restaurant_screen.dart';
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = ServiceLocator.authService.currentUser;
    final lists = await ServiceLocator.restaurantService.getExplorationLists();
    final reviews = await ServiceLocator.reviewService.getAllReviews();
    final exploreLists = lists.where(_isExploreList).toList();

    if (!mounted) return;

    setState(() {
      _currentUser = user;
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
      MaterialPageRoute(builder: (context) => const ManagedRestaurantsScreen()),
    );
    _loadProfile();
  }

  Future<void> _onInscriptionRestaurantTap() async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const RegisterRestaurantScreen()),
    );
    if (registered == true) {
      _loadProfile();
    }
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
                _buildSettingsTile(
                  context,
                  icon: Icons.location_on_outlined,
                  title: "Verification GPS",
                  subtitle: "Utilisee uniquement pour certifier les avis",
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "La verification GPS est declenchee au moment de publier un avis.",
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  icon: Icons.security_outlined,
                  title: "Securite du compte",
                  subtitle: "Compte actif et acces utilisateur",
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Options de securite en preparation."),
                      ),
                    );
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
                        _buildAccountCard(context, user, isVisitor),
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
                        if (_currentUser?.role == 'gerant') ...[
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

  Widget _buildAccountCard(BuildContext context, User? user, bool isVisitor) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Informations du compte",
            style: textTheme.titleLarge?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 14),
          _buildInfoLine(
            context,
            Icons.person_outline,
            "Statut",
            isVisitor ? "Invite" : _roleLabel(user?.role ?? "utilisateur"),
          ),
          const SizedBox(height: 12),
          _buildInfoLine(
            context,
            Icons.badge_outlined,
            "Nom",
            user == null ? "Non connecte" : user.nom,
          ),
          const SizedBox(height: 12),
          _buildInfoLine(
            context,
            Icons.account_circle_outlined,
            "Prenom",
            user == null ? "Non connecte" : user.prenom,
          ),
          const SizedBox(height: 12),
          _buildInfoLine(
            context,
            Icons.wc_outlined,
            "Sexe",
            user?.sexe ?? "Non connecte",
          ),
          const SizedBox(height: 12),
          _buildInfoLine(
            context,
            Icons.mail_outline,
            "Email",
            user?.email ?? "Non connecte",
          ),
          if (user != null) ...[
            const SizedBox(height: 12),
            _buildInfoLine(
              context,
              Icons.event_available_outlined,
              "Inscription",
              _formatDate(user.dateInscription),
            ),
            const SizedBox(height: 12),
            _buildInfoLine(
              context,
              Icons.update_outlined,
              "Mise a jour",
              _formatDate(user.dateMaj),
            ),
          ],
        ],
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

  Widget _buildInfoLine(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.terracotta),
        const SizedBox(width: 10),
        Text(
          "$label : ",
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.grisTexte,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(fontSize: 14),
          ),
        ),
      ],
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

  String _formatDate(DateTime date) {
    const months = [
      "janvier",
      "fevrier",
      "mars",
      "avril",
      "mai",
      "juin",
      "juillet",
      "aout",
      "septembre",
      "octobre",
      "novembre",
      "decembre",
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  String _roleLabel(String role) {
    if (role == "admin") {
      return "Administrateur";
    }
    if (role == "gerant") {
      return "Gerant de restaurant";
    }
    return "Utilisateur inscrit";
  }
}
