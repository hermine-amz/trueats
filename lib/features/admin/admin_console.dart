import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/services/http_services.dart';
import '../../core/theme.dart';
import '../../core/widgets/document_preview_dialog.dart';
import '../../core/widgets/app_feedback.dart';
import '../auth/login_screen.dart';
import '../restaurant/restaurant_details_screen.dart';

class AdminConsole extends StatefulWidget {
  const AdminConsole({super.key});

  @override
  State<AdminConsole> createState() => _AdminConsoleState();
}

class _AdminConsoleState extends State<AdminConsole> {
  List<Signalement> _signalements = [];
  List<User> _users = [];
  List<DemandeRestaurant> _demandes = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSessionExpired = false;
  String _errorMessage = 'Vérifiez votre connexion et réessayez.';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Chargement parallèle des 3 sources — 3x plus rapide que séquentiel
      final results = await Future.wait([
        ServiceLocator.reviewService.getSignalements(),
        ServiceLocator.authService.getAllUsers(),
        ServiceLocator.adminService.getDemandes(),
      ]);

      if (!mounted) return;

      setState(() {
        _signalements = results[0] as List<Signalement>;
        _users        = results[1] as List<User>;
        _demandes     = results[2] as List<DemandeRestaurant>;
        _isLoading    = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final isExpired = msg.contains('Session expiree') ||
          msg.contains('Session expirée') ||
          msg.contains('401') ||
          msg.contains('Unauthenticated');
      debugPrint('[AdminConsole] Erreur chargement: $msg');
      setState(() {
        _isLoading        = false;
        _hasError         = true;
        _isSessionExpired = isExpired;
        _errorMessage     = isExpired
            ? 'Session expirée. Veuillez vous reconnecter.'
            : 'Erreur: $msg';
      });
    }
  }

  Future<void> _resolveSignalement(int signalementId, bool keepReview) async {
    setState(() {
      _isLoading = true;
    });

    await ServiceLocator.reviewService.handleSignalement(
      signalementId,
      keepReview,
    );
    await _loadAdminData();

    if (mounted) {
      showAppNotification(
        context,
        title: keepReview ? 'Signalement classe' : 'Avis retire',
        message: keepReview
            ? "Le signalement a ete rejete. L'avis est conserve."
            : "L'avis signale a ete retire de la plateforme.",
        type: keepReview ? AppFeedbackType.success : AppFeedbackType.warning,
      );
    }
  }

  Future<void> _confirmResolveSignalement(
    Signalement signalement,
    bool keepReview,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: keepReview ? 'Conserver cet avis ?' : 'Retirer cet avis ?',
      message: keepReview
          ? "Le signalement sera marque comme traite et l'avis restera visible."
          : "L'avis de ${signalement.avis.nomAuteur} ne sera plus visible sur la plateforme.",
      confirmLabel: keepReview ? 'Conserver' : 'Retirer',
      icon: keepReview
          ? Icons.verified_outlined
          : Icons.delete_outline_rounded,
      type: keepReview ? AppFeedbackType.success : AppFeedbackType.error,
    );
    if (confirmed) {
      await _resolveSignalement(signalement.id, keepReview);
    }
  }

  Future<void> _toggleUser(
    User user,
    bool isActive, {
    int? dureeJours,
    String? motif,
    bool? restrictionAvis,
    bool? restrictionGerant,
  }) async {
    await ServiceLocator.authService.setAccountActive(
      user.id,
      isActive,
      dureeJours: dureeJours,
      motif: motif,
      restrictionAvis: restrictionAvis,
      restrictionGerant: restrictionGerant,
    );
    await _loadAdminData();

    if (mounted) {
      final isRestricted = restrictionAvis == true || restrictionGerant == true;
      showAppNotification(
        context,
        title: isActive 
            ? 'Compte réactivé' 
            : (dureeJours == null 
                ? 'Compte banni' 
                : isRestricted 
                    ? 'Compte restreint' 
                    : 'Compte suspendu'),
        message: isActive
            ? "Compte de ${user.name} réactivé."
            : (dureeJours == null 
                ? "Compte de ${user.name} banni définitivement." 
                : isRestricted 
                    ? "Compte de ${user.name} restreint." 
                    : "Compte de ${user.name} suspendu."),
        type: isActive ? AppFeedbackType.success : AppFeedbackType.warning,
      );
    }
  }


  void _viewDocument(String? url, String title) {
    if (url == null || url.isEmpty) return;
    final isPdf = url.toLowerCase().endsWith('.pdf');

    showDialog(
      context: context,
      builder: (context) => DocumentPreviewDialog(
        title: title,
        url: url,
        isPdf: isPdf,
      ),
    );
  }

  Future<void> _validerDemande(int restaurantId, {required bool accepte, String? motifRejet, VoidCallback? onComplete}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ServiceLocator.adminService.validerDemande(
        restaurantId,
        accepte: accepte,
        motifRejet: motifRejet,
      );
      await _loadAdminData();

      if (mounted) {
        showAppNotification(
          context,
          title: accepte ? 'Restaurant valide' : 'Restaurant rejete',
          message: accepte
              ? "Le restaurant a ete valide avec succes."
              : "Le restaurant a ete rejete.",
          type: accepte ? AppFeedbackType.success : AppFeedbackType.error,
        );
      }
      if (onComplete != null) {
        onComplete();
      }
    } catch (e) {
      if (mounted) {
        showAppNotification(
          context,
          title: 'Erreur',
          message: "Erreur : $e",
          type: AppFeedbackType.error,
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _promptRejet(int restaurantId, {VoidCallback? onComplete}) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.creme,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.rougeSignalement.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.rougeSignalement,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Rejeter la demande",
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontSize: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Veuillez saisir le motif du rejet de cette inscription.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "Motif du rejet",
                  hintText: "Documents invalides, coordonnees incorrectes...",
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Annuler"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final motif = controller.text.trim();
                        if (motif.isEmpty) {
                          showAppNotification(
                            context,
                            title: 'Motif requis',
                            message: "Le motif est obligatoire pour rejeter.",
                            type: AppFeedbackType.warning,
                          );
                          return;
                        }
                        Navigator.of(context).pop();
                        _validerDemande(
                          restaurantId,
                          accepte: false,
                          motifRejet: motif,
                          onComplete: onComplete,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rougeSignalement,
                      ),
                      child: const Text("Rejeter"),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        );
      },
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
      margin: const EdgeInsets.only(bottom: 14),
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
                        fontSize: 15,
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      // AppBar toujours visible — l'utilisateur peut toujours revenir en arrière
      appBar: AppBar(
        backgroundColor: AppColors.creme,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.marronFonce),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CONSOLE ADMIN",
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.grisTexte,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Supervision",
              style: textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.terracotta),
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadAdminData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
            : _hasError
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isSessionExpired
                                ? Icons.lock_outline_rounded
                                : Icons.wifi_off_rounded,
                            size: 64,
                            color: AppColors.grisTexte,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSessionExpired
                                ? 'Session expirée'
                                : 'Impossible de charger les données',
                            style: textTheme.titleLarge?.copyWith(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage,
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.grisTexte),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (_isSessionExpired)
                            ElevatedButton.icon(
                              onPressed: () {
                                // Déconnexion propre puis retour à l'écran de connexion
                                ApiClient.setToken(null);
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Se reconnecter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracotta,
                                foregroundColor: Colors.white,
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _loadAdminData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Réessayer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.terracotta,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAdminData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildAdminKpiCard(
                            context,
                            _signalements.where((s) => !s.estTraite).length.toString(),
                            "A TRAITER",
                            AppColors.rougeSignalement,
                          ),
                          _buildAdminKpiCard(
                            context,
                            _demandes.where((d) => !d.estValide && d.motifRejet == null).length.toString(),
                            "DEMANDES",
                            AppColors.terracotta,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildAdminKpiCard(
                            context,
                            _users.where((u) => u.role == 'gerant' && !u.isGuest).length.toString(),
                            "GÉRANTS",
                            AppColors.marronFonce,
                          ),
                          _buildAdminKpiCard(
                            context,
                            _users.where((u) => u.role == 'utilisateur' && !u.isGuest).length.toString(),
                            "CLIENTS",
                            AppColors.terracotta,
                          ),
                          _buildAdminKpiCard(
                            context,
                            _users.where((u) => u.isGuest).length.toString(),
                            "VISITEURS",
                            AppColors.marronFonce,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      _buildSectionTitle(context, "ACTIONS DE SUPERVISION"),
                      const SizedBox(height: 14),
                      
                      _buildActivityRow(
                        context,
                        Icons.playlist_add_check_rounded,
                        "Demandes d'inscriptions",
                        _demandes.where((d) => !d.estValide && d.motifRejet == null).isEmpty
                            ? "Aucune demande en attente"
                            : "${_demandes.where((d) => !d.estValide && d.motifRejet == null).length} demande(s) en attente",
                        () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => _DemandesValidationPage(
                                initialDemandes: _demandes,
                                onRefresh: _loadAdminData,
                                cardBuilder: _buildDemandeCard,
                              ),
                            ),
                          );
                          _loadAdminData();
                        },
                      ),
                      
                      _buildActivityRow(
                        context,
                        Icons.gavel_rounded,
                        "Modération des avis",
                        _signalements.where((s) => !s.estTraite).isEmpty
                            ? "Aucun signalement en attente"
                            : "${_signalements.where((s) => !s.estTraite).length} signalement(s) à traiter",
                        () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => _ModerationAvisPage(
                                initialSignalements: _signalements,
                                onResolve: _confirmResolveSignalement,
                                onRefresh: _loadAdminData,
                              ),
                            ),
                          );
                          _loadAdminData();
                        },
                      ),
 
                      _buildActivityRow(
                        context,
                        Icons.business_center_outlined,
                        "Comptes gérants",
                        "Activer, suspendre ou supprimer les gérants",
                        () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => _ComptesPage(
                                roleFilter: 'gerant',
                                initialUsers: _users,
                                onRefresh: _loadAdminData,
                                onToggleActive: (user, active, {dureeJours, motif, restrictionAvis, restrictionGerant}) async {
                                  await _toggleUser(user, active, dureeJours: dureeJours, motif: motif, restrictionAvis: restrictionAvis, restrictionGerant: restrictionGerant);
                                },
                              ),
                            ),
                          );
                          _loadAdminData();
                        },
                      ),
 
                      _buildActivityRow(
                        context,
                        Icons.people_outline,
                        "Comptes clients",
                        "Activer, suspendre ou supprimer les clients",
                        () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => _ComptesPage(
                                roleFilter: 'utilisateur',
                                initialUsers: _users,
                                onRefresh: _loadAdminData,
                                onToggleActive: (user, active, {dureeJours, motif, restrictionAvis, restrictionGerant}) async {
                                  await _toggleUser(user, active, dureeJours: dureeJours, motif: motif, restrictionAvis: restrictionAvis, restrictionGerant: restrictionGerant);
                                },
                              ),
                            ),
                          );
                          _loadAdminData();
                        },
                      ),

                      _buildActivityRow(
                        context,
                        Icons.person_pin_outlined,
                        "Comptes visiteurs",
                        "Consulter ou supprimer les visiteurs (comptes temporaires)",
                        () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => _ComptesPage(
                                roleFilter: 'visiteur',
                                initialUsers: _users,
                                onRefresh: _loadAdminData,
                                onToggleActive: (user, active, {dureeJours, motif, restrictionAvis, restrictionGerant}) async {
                                  await _toggleUser(user, active, dureeJours: dureeJours, motif: motif, restrictionAvis: restrictionAvis, restrictionGerant: restrictionGerant);
                                },
                              ),
                            ),
                          );
                          _loadAdminData();
                        },
                      ),

                      _buildActivityRow(
                        context,
                        Icons.bar_chart_rounded,
                        "Statistiques de l'application",
                        "Consulter l'activité et les chiffres clés",
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const _StatsPage(),
                            ),
                          );
                        },
                      ),
                      
                      _buildActivityRow(
                        context,
                        Icons.balance_rounded,
                        "Recours & Appels",
                        "Traiter les demandes de recours des utilisateurs sanctionnés",
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const _AppealsManagementPage(),
                            ),
                          );
                        },
                      ),

                      _buildActivityRow(
                        context,
                        Icons.history_rounded,
                        "Historique des actions",
                        "Consigner et suivre les actions des admins",
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const _AdminLogsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.grisTexte,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildAdminKpiCard(
    BuildContext context,
    String value,
    String label,
    Color valueColor,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.displayMedium?.copyWith(
                color: valueColor,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.grisTexte,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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


  Widget _buildDemandeStatusBadge(DemandeRestaurant demande) {
    Color color;
    String label;
    if (demande.estValide) {
      color = AppColors.sauge;
      label = "Valide";
    } else if (demande.motifRejet != null) {
      color = AppColors.rougeSignalement;
      label = "Rejete";
    } else {
      color = AppColors.terracotta;
      label = "En attente";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDemandeCard(BuildContext context, DemandeRestaurant demande, {VoidCallback? onActionCompleted}) {
    final textTheme = Theme.of(context).textTheme;
    final gerantNom = demande.gerant != null
        ? "${demande.gerant!['prenom'] ?? ''} ${demande.gerant!['nom'] ?? ''}".trim()
        : "Inconnu";
    final gerantEmail = demande.gerant != null ? (demande.gerant!['email'] ?? '') : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.orangeClair,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.terracotta,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demande.nom,
                      style: textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${demande.categorie ?? 'Restaurant'} - ${demande.typeCuisine ?? 'Cuisine'}",
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.terracotta,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cremeFonce,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grisBordure),
                    ),
                    child: Text(
                      "${demande.superficie ?? 0} m²",
                      style: textTheme.labelLarge?.copyWith(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDemandeStatusBadge(demande),
                ],
              ),
            ],
          ),
          if (demande.motifRejet != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.rougeSignalement.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.rougeSignalement.withValues(alpha: 0.2)),
              ),
              child: Text(
                "Motif de rejet : ${demande.motifRejet}",
                style: const TextStyle(color: AppColors.rougeSignalement, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.grisBordure, height: 1),
          const SizedBox(height: 12),
          
          _buildInfoRow(Icons.location_on_outlined, "Itinéraire", "${demande.adresse} (${demande.quartier ?? ''})"),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.gps_fixed_outlined, "Coordonnees GPS", "${demande.latitude.toStringAsFixed(5)}, ${demande.longitude.toStringAsFixed(5)}"),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.person_outline_rounded, "Gerant", "$gerantNom ($gerantEmail)"),
          
          const SizedBox(height: 16),
          Text(
            "PIECES JUSTIFICATIVES",
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.grisTexte,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (demande.cipUrl != null)
                _buildDocBadge("CIP Gerant", () => _viewDocument(demande.cipUrl, "CIP Gerant")),
              if (demande.ifuNumero != null)
                _buildDocBadge("IFU: ${demande.ifuNumero}", () => _viewDocument(demande.ifuAttestationUrl, "Attestation IFU"), copyText: demande.ifuNumero),
            ],
          ),
          
          const SizedBox(height: 18),
          Row(
            children: [
              if (demande.estValide || (!demande.estValide && demande.motifRejet == null))
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _promptRejet(demande.id, onComplete: onActionCompleted),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("Rejeter"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rougeSignalement,
                      side: const BorderSide(color: AppColors.rougeSignalement),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (demande.estValide || (!demande.estValide && demande.motifRejet == null))
                const SizedBox(width: 10),
              if (!demande.estValide)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showAppConfirmDialog(
                        context,
                        title: 'Valider ce restaurant ?',
                        message:
                            "${demande.nom} sera publie et le compte client deviendra gerant.",
                        confirmLabel: 'Valider',
                        icon: Icons.verified_rounded,
                        type: AppFeedbackType.success,
                      );
                      if (confirmed) {
                        _validerDemande(demande.id, accepte: true, onComplete: onActionCompleted);
                      }
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Valider"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sauge,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.grisTexte),
        const SizedBox(width: 6),
        Text(
          "$title : ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.marronFonce),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.grisTexte),
          ),
        ),
      ],
    );
  }

  Widget _buildDocBadge(String label, VoidCallback onTap, {String? copyText}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.orangeClair,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 16,
              color: AppColors.terracotta,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.terracotta,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (copyText != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: copyText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copié dans le presse-papier'), duration: Duration(seconds: 2)),
                  );
                },
                child: const Icon(Icons.copy, size: 14, color: AppColors.marronFonce),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Sub-Pages for Admin Console
// -------------------------------------------------------------

class _StatsPage extends StatefulWidget {
  const _StatsPage();

  @override
  State<_StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<_StatsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await ServiceLocator.adminService.getStats();
      if (mounted) {
        setState(() {
          _stats = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text("Statistiques"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadStats();
            },
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _stats == null || _stats!.isEmpty
                ? const Center(child: Text("Impossible de charger les statistiques."))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CHIFFRES CLÉS",
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.terracotta,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Activité générale",
                          style: textTheme.displayLarge?.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 24),
                        _buildSection("UTILISATEURS", [
                          _buildStatRow(Icons.people_outline, "Total inscrits", _stats!['users']?['total']?.toString() ?? '0'),
                          _buildStatRow(Icons.person_outline, "Clients inscrits", _stats!['users']?['clients']?.toString() ?? '0'),
                          _buildStatRow(Icons.person_pin_outlined, "Visiteurs (sans compte)", _stats!['users']?['visiteurs']?.toString() ?? '0'),
                          _buildStatRow(Icons.business_center_outlined, "Gérants de restaurants", _stats!['users']?['gerants']?.toString() ?? '0'),
                          _buildStatRow(Icons.admin_panel_settings_outlined, "Administrateurs", _stats!['users']?['admins']?.toString() ?? '0'),
                        ]),
                        const SizedBox(height: 20),
                        _buildSection("ÉTABLISSEMENTS", [
                          _buildStatRow(Icons.storefront_outlined, "Total restaurants", _stats!['restaurants']?['total']?.toString() ?? '0'),
                          _buildStatRow(Icons.verified_outlined, "Validés & Actifs", _stats!['restaurants']?['valides']?.toString() ?? '0'),
                          _buildStatRow(Icons.hourglass_top_outlined, "En attente de validation", _stats!['restaurants']?['en_attente']?.toString() ?? '0'),
                          _buildStatRow(Icons.block_outlined, "Bloqués / Suspendus", _stats!['restaurants']?['bloques']?.toString() ?? '0'),
                        ]),
                        const SizedBox(height: 20),
                        _buildSection("AVIS ET RETOURS", [
                          _buildStatRow(Icons.rate_review_outlined, "Total avis publiés", _stats!['avis']?['total']?.toString() ?? '0'),
                          _buildStatRow(Icons.warning_amber_rounded, "Avis signalés", _stats!['avis']?['signales']?.toString() ?? '0'),
                          _buildStatRow(Icons.star_outline_rounded, "Note moyenne", "${_stats!['avis']?['note_moyenne'] ?? '0.0'} / 5"),
                        ]),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grisBordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.terracotta,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.marronFonce),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: AppColors.grisTexte, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.marronFonce),
          ),
        ],
      ),
    );
  }
}

class _ModerationAvisPage extends StatefulWidget {
  final List<Signalement> initialSignalements;
  final Function(Signalement, bool) onResolve;
  final Future<void> Function() onRefresh;

  const _ModerationAvisPage({
    required this.initialSignalements,
    required this.onResolve,
    required this.onRefresh,
  });

  @override
  State<_ModerationAvisPage> createState() => _ModerationAvisPageState();
}

class _ModerationAvisPageState extends State<_ModerationAvisPage> {
  late List<Signalement> _signalements;
  bool _isLoading = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _signalements = widget.initialSignalements;
  }

  @override
  void didUpdateWidget(covariant _ModerationAvisPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSignalements != oldWidget.initialSignalements) {
      setState(() {
        _signalements = widget.initialSignalements;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    // On met a jour l'etat parent ET on recupere les nouvelles donnees
    // pour pallier l'absence de reconstruction automatique de la route par le Navigator.
    await widget.onRefresh();
    final freshSignalements = await ServiceLocator.reviewService.getSignalements();
    if (mounted) {
      setState(() {
        _signalements = freshSignalements;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_signalements.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < _signalements.length)
        ? startIndex + _itemsPerPage
        : _signalements.length;
    final displayedSignals = _signalements.isEmpty
        ? <Signalement>[]
        : _signalements.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text("Modération avis"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _signalements.isEmpty
                ? const Center(child: Text("Aucun signalement en attente."))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: displayedSignals.length,
                          itemBuilder: (context, index) {
                            final signalement = displayedSignals[index];
                            return _buildModerationCard(context, signalement);
                          },
                        ),
                      ),
                      if (totalPages > 1)
                        _buildPaginationControls(totalPages),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        border: Border(top: BorderSide(color: AppColors.grisBordure)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          Text(
            "Page ${_currentPage + 1} sur $totalPages",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSignalementStatusBadge(Signalement signalement) {
    Color color;
    String label;
    if (signalement.estTraite) {
      if (signalement.decision == 'conserve') {
        color = AppColors.sauge;
        label = "Conserve";
      } else {
        color = AppColors.rougeSignalement;
        label = "Retire";
      }
    } else {
      color = AppColors.terracotta;
      label = "A traiter";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildModerationCard(BuildContext context, Signalement signalement) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grisBordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.rougeSignalement, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Signalement par : ${signalement.raison}",
                  style: textTheme.titleLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              _buildSignalementStatusBadge(signalement),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.grisBordure, height: 1),
          const SizedBox(height: 12),
          Text(
            "Avis de ${signalement.avis.nomAuteur} sur ${signalement.avis.restaurantNom} :",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.marronFonce),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (starIndex) {
              return Icon(
                starIndex < signalement.avis.note
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: Colors.amber,
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            "\"${signalement.avis.commentaire}\"",
            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.grisTexte),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!signalement.estTraite || (signalement.estTraite && signalement.decision == 'conserve'))
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await widget.onResolve(signalement, false);
                      _refresh();
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text("Retirer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rougeSignalement,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (!signalement.estTraite)
                const SizedBox(width: 10),
              if (!signalement.estTraite || (signalement.estTraite && signalement.decision == 'retire'))
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await widget.onResolve(signalement, true);
                      _refresh();
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Conserver"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sauge,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComptesPage extends StatefulWidget {
  final String roleFilter;
  final List<User> initialUsers;
  final Future<void> Function() onRefresh;
  final Future<void> Function(
    User,
    bool, {
    int? dureeJours,
    String? motif,
    bool? restrictionAvis,
    bool? restrictionGerant,
  }) onToggleActive;

  const _ComptesPage({
    required this.roleFilter,
    required this.initialUsers,
    required this.onRefresh,
    required this.onToggleActive,
  });

  @override
  State<_ComptesPage> createState() => _ComptesPageState();
}

class _ComptesPageState extends State<_ComptesPage> {
  late List<User> _allUsers;
  late List<User> _filteredUsers;
  bool _isLoading = false;
  String _searchQuery = "";
  int _currentPage = 0;
  static const int _itemsPerPage = 8;
  final Set<int> _expandedUserIds = {};

  Future<void> _navigateToRestaurant(int restaurantId) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        );
      },
    );

    try {
      final restaurant = await ServiceLocator.restaurantService.getRestaurantById(restaurantId);
      if (!mounted) return;
      Navigator.of(context).pop();

      if (restaurant != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(restaurant: restaurant),
          ),
        );
      } else {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.creme,
            title: const Text(
              "Restaurant introuvable",
              style: TextStyle(color: AppColors.marronFonce, fontWeight: FontWeight.bold),
            ),
            content: const Text("Ce restaurant n'existe plus ou n'est plus disponible."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK", style: TextStyle(color: AppColors.terracotta)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.creme,
            title: const Text(
              "Erreur",
              style: TextStyle(color: AppColors.marronFonce, fontWeight: FontWeight.bold),
            ),
            content: Text("Une erreur est survenue lors de la récupération des détails : $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK", style: TextStyle(color: AppColors.terracotta)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _allUsers = widget.initialUsers;
    _applyFilterAndSearch();
  }

  @override
  void didUpdateWidget(covariant _ComptesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUsers != oldWidget.initialUsers) {
      setState(() {
        _allUsers = widget.initialUsers;
        _applyFilterAndSearch();
      });
    }
  }

  void _applyFilterAndSearch() {
    _filteredUsers = _allUsers.where((u) {
      bool matchesRole = false;
      if (widget.roleFilter == 'gerant') {
        matchesRole = u.role == 'gerant' && !u.isGuest;
      } else if (widget.roleFilter == 'utilisateur') {
        matchesRole = u.role == 'utilisateur' && !u.isGuest;
      } else if (widget.roleFilter == 'visiteur') {
        matchesRole = u.isGuest;
      } else {
        matchesRole = u.role == widget.roleFilter;
      }
      final matchesSearch = u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    await widget.onRefresh();
    final freshUsers = await ServiceLocator.authService.getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = freshUsers;
        _applyFilterAndSearch();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount(User user) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: "Supprimer définitivement ?",
      message: "Attention : supprimer ce compte libérera l'adresse e-mail (${user.email}), ce qui lui permettra de s'inscrire à nouveau. Si vous souhaitez bloquer définitivement cet utilisateur, utilisez plutôt l'action 'Bannir'.\n\nCette action est irréversible. Le compte de ${user.name} sera supprimé de la plateforme.",
      confirmLabel: "Supprimer",
      icon: Icons.delete_forever_outlined,
      type: AppFeedbackType.error,
    );
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });
    try {
      await ServiceLocator.adminService.deleteUser(user.id);
      await widget.onRefresh();
      final freshUsers = await ServiceLocator.authService.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = freshUsers;
        });
        showAppNotification(
          context,
          title: "Compte supprimé",
          message: "Le compte de ${user.name} a été supprimé.",
          type: AppFeedbackType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppNotification(
          context,
          title: "Erreur",
          message: "Erreur lors de la suppression : $e",
          type: AppFeedbackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _applyFilterAndSearch();
          _isLoading = false;
        });
      }
    }
  }

  void _showUserDetails(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Détails du compte"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow("Nom complet", user.name),
                _detailRow("Email", user.email),
                if (user.telephone != null && user.telephone!.isNotEmpty)
                  _detailRow("Téléphone", user.telephone!),
                _detailRow("Rôle", user.role.toUpperCase()),
                if (user.sexe.isNotEmpty)
                  _detailRow("Sexe", user.sexe),
                _detailRow(
                    "Statut",
                    !user.isActive
                        ? (user.bloqueJusqua == null ? "Banni définitivement" : "Suspendu")
                        : (user.restrictionAvis || user.restrictionGerant)
                            ? "Restreint"
                            : "Actif"),
                if (!user.isActive && user.bloqueJusqua != null)
                  _detailRow("Bloqué jusqu'au", _formatDate(user.bloqueJusqua!)),
                _detailRow("Inscription", _formatDate(user.dateInscription)),
                _detailRow("Dernière mise à jour", _formatDate(user.dateMaj)),
                if (user.role == 'gerant' && user.restaurants.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text("Restaurants gérés", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.marronFonce)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: user.restaurants.map((rest) {
                      return Chip(
                        label: Text(rest.nom, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.orangeClair,
                        side: BorderSide(color: AppColors.terracotta.withValues(alpha: 0.3)),
                      );
                    }).toList(),
                  ),
                ],
                if (user.avis.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text("Avis donnés (${user.avis.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.marronFonce)),
                  const SizedBox(height: 8),
                  ...user.avis.map((av) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(av.restaurantNom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              Row(
                                children: List.generate(5, (index) => Icon(
                                  index < av.note ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: Colors.amber,
                                  size: 14,
                                )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(av.commentaire, style: const TextStyle(fontSize: 12, color: AppColors.grisTexte)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.grisTexte)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, color: AppColors.marronFonce)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    _applyFilterAndSearch();
    final totalPages = (_filteredUsers.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < _filteredUsers.length)
        ? startIndex + _itemsPerPage
        : _filteredUsers.length;
    final displayedUsers = _filteredUsers.isEmpty
        ? <User>[]
        : _filteredUsers.sublist(startIndex, endIndex);

    final String title;
    if (widget.roleFilter == 'gerant') {
      title = "Comptes gérants";
    } else if (widget.roleFilter == 'visiteur') {
      title = "Comptes visiteurs";
    } else {
      title = "Comptes clients";
    }

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: "Rechercher par nom ou email...",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _currentPage = 0;
                          _applyFilterAndSearch();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: _filteredUsers.isEmpty
                        ? const Center(child: Text("Aucun compte trouvé."))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            itemCount: displayedUsers.length,
                            itemBuilder: (context, index) {
                              final user = displayedUsers[index];
                              return GestureDetector(
                                onTap: () => _showUserDetails(context, user),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDFBF7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.grisBordure),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.orangeClair,
                                          child: Text(
                                            user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
                                            style: const TextStyle(
                                              color: AppColors.terracotta,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      user.name,
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.marronFonce,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: !user.isActive
                                                          ? AppColors.rougeClair
                                                          : (user.restrictionAvis || user.restrictionGerant)
                                                              ? const Color(0xFFFFF3E0)
                                                              : AppColors.vertClair,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      !user.isActive
                                                          ? (user.bloqueJusqua == null ? "Banni" : "Suspendu")
                                                          : (user.restrictionAvis || user.restrictionGerant)
                                                              ? "Restreint"
                                                              : "Actif",
                                                      style: TextStyle(
                                                        color: !user.isActive
                                                            ? AppColors.rougeSignalement
                                                            : (user.restrictionAvis || user.restrictionGerant)
                                                                ? const Color(0xFFE65100)
                                                                : AppColors.sauge,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                user.email,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.grisTexte,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!user.isActive || user.restrictionAvis || user.restrictionGerant) ...[
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.lock_open_rounded,
                                                  color: AppColors.sauge,
                                                  size: 22,
                                                ),
                                                onPressed: () async {
                                                  final confirmed = await showAppConfirmDialog(
                                                    context,
                                                    title: 'Réactiver ce compte ?',
                                                    message: "Le compte de ${user.name} sera réactivé.",
                                                    confirmLabel: 'Réactiver',
                                                    icon: Icons.lock_open_rounded,
                                                    type: AppFeedbackType.success,
                                                  );
                                                  if (confirmed) {
                                                    await widget.onToggleActive(user, true);
                                                    _refresh();
                                                  }
                                                },
                                                tooltip: "Réactiver",
                                              ),
                                            ] else ...[
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.timer_outlined,
                                                  color: AppColors.marronFonce,
                                                  size: 22,
                                                ),
                                                onPressed: () async {
                                                  final result = await _showSuspensionDialog(context, user, widget.roleFilter);
                                                  if (!context.mounted || result == null) return;
                                                  await widget.onToggleActive(
                                                    user,
                                                    false,
                                                    dureeJours: result['dureeJours'] as int,
                                                    motif: result['motif'] as String?,
                                                    restrictionAvis: result['restrictionAvis'] as bool,
                                                    restrictionGerant: result['restrictionGerant'] as bool,
                                                  );
                                                  _refresh();
                                                },
                                                tooltip: "Suspendre ou restreindre",
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.gavel_rounded,
                                                  color: AppColors.rougeSignalement,
                                                  size: 22,
                                                ),
                                                onPressed: () async {
                                                  final motif = await _showReasonDialog(
                                                    context,
                                                    "Bannir l'utilisateur",
                                                    "Veuillez saisir le motif du bannissement définitif de ${user.name} (son e-mail restera enregistré pour empêcher toute nouvelle inscription) :",
                                                  );
                                                  if (!context.mounted) return;
                                                  if (motif != null) {
                                                    await widget.onToggleActive(user, false, dureeJours: null, motif: motif);
                                                    _refresh();
                                                  }
                                                },
                                                tooltip: "Bannir définitivement",
                                              ),
                                            ],
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.rougeSignalement,
                                                size: 22,
                                              ),
                                              onPressed: () => _deleteAccount(user),
                                              tooltip: "Supprimer",
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (user.role == 'gerant' && user.restaurants.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Divider(color: AppColors.grisBordure, height: 1),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Restaurants gérés :",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.marronFonce,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: user.restaurants.map((rest) {
                                          return ActionChip(
                                            backgroundColor: AppColors.orangeClair,
                                            side: BorderSide(color: AppColors.terracotta.withValues(alpha: 0.3)),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            label: Text(
                                              rest.nom,
                                              style: const TextStyle(
                                                color: AppColors.terracotta,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => RestaurantDetailsScreen(restaurant: rest),
                                                ),
                                              );
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    if (user.avis.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Divider(color: AppColors.grisBordure, height: 1),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            if (_expandedUserIds.contains(user.id)) {
                                              _expandedUserIds.remove(user.id);
                                            } else {
                                              _expandedUserIds.add(user.id);
                                            }
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.rate_review_outlined, size: 16, color: AppColors.terracotta),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "Avis donnés (${user.avis.length})",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.terracotta,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Icon(
                                                _expandedUserIds.contains(user.id)
                                                    ? Icons.expand_less_rounded
                                                    : Icons.expand_more_rounded,
                                                size: 18,
                                                color: AppColors.terracotta,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_expandedUserIds.contains(user.id)) ...[
                                        const SizedBox(height: 8),
                                        ...user.avis.map((av) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.creme,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppColors.grisBordure),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: InkWell(
                                                        onTap: () => _navigateToRestaurant(av.restaurantId),
                                                        child: Text(
                                                          av.restaurantNom,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.terracotta,
                                                            decoration: TextDecoration.underline,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Row(
                                                      children: List.generate(5, (starIndex) {
                                                        return Icon(
                                                          starIndex < av.note
                                                              ? Icons.star_rounded
                                                              : Icons.star_border_rounded,
                                                          color: Colors.amber,
                                                          size: 14,
                                                        );
                                                      }),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  av.commentaire,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.grisTexte,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                  if (totalPages > 1)
                    _buildPaginationControls(totalPages),
                ],
              ),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        border: Border(top: BorderSide(color: AppColors.grisBordure)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          Text(
            "Page ${_currentPage + 1} sur $totalPages",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  /// Dialogue unifié de suspension/restriction en 2 étapes :
  /// Étape 1 — Durée de la sanction
  /// Étape 2 — Type de restriction (blocage connexion ou restriction d'actions)
  Future<Map<String, dynamic>?> _showSuspensionDialog(
    BuildContext context,
    User user,
    String roleFilter,
  ) async {
    final isGerant = roleFilter == 'gerant';

    // ── ÉTAPE 1 : Durée ────────────────────────────────────────────────────
    final int? dureeJours = await showDialog<int?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.creme,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timer_outlined, color: AppColors.terracotta),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suspendre / Restreindre',
                            style: Theme.of(ctx).textTheme.displaySmall?.copyWith(fontSize: 18),
                          ),
                          Text(
                            user.name,
                            style: const TextStyle(fontSize: 13, color: AppColors.grisTexte),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.orangeClair,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppColors.terracotta),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Étape 1 sur 2 — Durée de la sanction',
                          style: TextStyle(fontSize: 12, color: AppColors.terracotta, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Options de durée
                _buildDurationTile(ctx, Icons.timer_outlined, '3 jours', 3),
                _buildDurationTile(ctx, Icons.date_range_outlined, '7 jours', 7),
                _buildDurationTile(ctx, Icons.calendar_month_outlined, '30 jours', 30),
                _buildDurationTile(ctx, Icons.calendar_today_outlined, '90 jours', 90),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (dureeJours == null || !context.mounted) return null;

    // ── ÉTAPE 2 : Type de restriction ──────────────────────────────────────
    // Variables locales pour la sélection
    // 'block'       = blocage connexion (restrictionAvis=false, restrictionGerant=false)
    // 'restriction' = restriction d'actions (au moins une case cochée)
    String typeSelection = 'block'; // défaut : blocage connexion
    bool restrictionAvis = false;
    bool restrictionGerant = false;
    final motifController = TextEditingController();

    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          backgroundColor: AppColors.creme,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.rougeSignalement.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.rougeSignalement),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type de sanction',
                              style: Theme.of(ctx).textTheme.displaySmall?.copyWith(fontSize: 18),
                            ),
                            Text(
                              '$dureeJours jour${dureeJours > 1 ? 's' : ''} · ${user.name}',
                              style: const TextStyle(fontSize: 13, color: AppColors.grisTexte),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.orangeClair,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.terracotta),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Étape 2 sur 2 — Choisissez la nature de la sanction',
                            style: TextStyle(fontSize: 12, color: AppColors.terracotta, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option A : Blocage connexion
                  GestureDetector(
                    onTap: () => setD(() => typeSelection = 'block'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: typeSelection == 'block'
                            ? AppColors.rougeSignalement.withValues(alpha: 0.08)
                            : const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: typeSelection == 'block'
                              ? AppColors.rougeSignalement
                              : AppColors.grisBordure,
                          width: typeSelection == 'block' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            typeSelection == 'block'
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: typeSelection == 'block'
                                ? AppColors.rougeSignalement
                                : AppColors.grisTexte,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🚫  Blocage de connexion',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.marronFonce),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "L'utilisateur ne peut plus se connecter pendant la période.",
                                  style: TextStyle(fontSize: 12, color: AppColors.grisTexte),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Option B : Restriction d'actions
                  GestureDetector(
                    onTap: () => setD(() {
                      typeSelection = 'restriction';
                      // Pré-cocher au moins une option par défaut
                      if (!restrictionAvis && !restrictionGerant) {
                        restrictionAvis = true;
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: typeSelection == 'restriction'
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: typeSelection == 'restriction'
                              ? const Color(0xFFE65100)
                              : AppColors.grisBordure,
                          width: typeSelection == 'restriction' ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                typeSelection == 'restriction'
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: typeSelection == 'restriction'
                                    ? const Color(0xFFE65100)
                                    : AppColors.grisTexte,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '✍️  Restriction d\'actions',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.marronFonce),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "L'utilisateur peut se connecter mais certaines actions lui sont interdites.",
                                      style: TextStyle(fontSize: 12, color: AppColors.grisTexte),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Sous-options uniquement si ce type est sélectionné
                          if (typeSelection == 'restriction') ...[
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: AppColors.grisBordure),
                            const SizedBox(height: 6),
                            // Restriction avis (tous)
                            CheckboxListTile(
                              value: restrictionAvis,
                              onChanged: (v) => setD(() => restrictionAvis = v ?? false),
                              title: const Text(
                                'Interdire les avis & signalements',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.marronFonce),
                              ),
                              dense: true,
                              activeColor: const Color(0xFFE65100),
                              contentPadding: const EdgeInsets.only(left: 4),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            // Restriction restaurant (gérant seulement)
                            if (isGerant)
                              CheckboxListTile(
                                value: restrictionGerant,
                                onChanged: (v) => setD(() => restrictionGerant = v ?? false),
                                title: const Text(
                                  'Interdire la gestion du restaurant',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.marronFonce),
                                ),
                                dense: true,
                                activeColor: const Color(0xFFE65100),
                                contentPadding: const EdgeInsets.only(left: 4),
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Motif
                  TextField(
                    controller: motifController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Motif (optionnel)',
                      hintText: 'Raison de la sanction...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Validation : si restriction mais aucune case cochée
                            if (typeSelection == 'restriction' && !restrictionAvis && !restrictionGerant) {
                              showAppNotification(
                                ctx,
                                title: 'Aucune restriction choisie',
                                message: 'Veuillez cocher au moins une action à restreindre.',
                                type: AppFeedbackType.warning,
                              );
                              return;
                            }
                            Navigator.of(ctx).pop({
                              'dureeJours': dureeJours,
                              'motif': motifController.text.trim().isEmpty
                                  ? null
                                  : motifController.text.trim(),
                              'restrictionAvis': typeSelection == 'restriction' && restrictionAvis,
                              'restrictionGerant': typeSelection == 'restriction' && restrictionGerant,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeSelection == 'block'
                                ? AppColors.rougeSignalement
                                : const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            typeSelection == 'block' ? 'Suspendre' : 'Restreindre',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    motifController.dispose();
    return result;
  }

  /// Tile de durée réutilisable pour l'étape 1
  Widget _buildDurationTile(BuildContext ctx, IconData icon, String label, int jours) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(ctx).pop(jours),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grisBordure),
            color: const Color(0xFFFDFBF7),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.terracotta, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.marronFonce,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.grisTexte, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showReasonDialog(BuildContext context, String actionTitle, String message) {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.creme,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.rougeSignalement.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: AppColors.rougeSignalement,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        actionTitle,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(fontSize: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: "Motif",
                    hintText: "Saisissez la raison de la sanction...",
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text("Annuler"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final val = controller.text.trim();
                          if (val.isEmpty) {
                            showAppNotification(
                              context,
                              title: 'Motif requis',
                              message: "Le motif est obligatoire.",
                              type: AppFeedbackType.warning,
                            );
                            return;
                          }
                          Navigator.of(context).pop(val);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rougeSignalement,
                        ),
                        child: const Text("Confirmer"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DemandesValidationPage extends StatefulWidget {
  final List<DemandeRestaurant> initialDemandes;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext, DemandeRestaurant, {VoidCallback? onActionCompleted}) cardBuilder;

  const _DemandesValidationPage({
    required this.initialDemandes,
    required this.onRefresh,
    required this.cardBuilder,
  });

  @override
  State<_DemandesValidationPage> createState() => _DemandesValidationPageState();
}

class _DemandesValidationPageState extends State<_DemandesValidationPage> {
  late List<DemandeRestaurant> _demandes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _demandes = widget.initialDemandes;
  }

  @override
  void didUpdateWidget(covariant _DemandesValidationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDemandes != oldWidget.initialDemandes) {
      setState(() {
        _demandes = widget.initialDemandes;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    // Note de soutenance : On rappelle onRefresh() pour l'etat parent et
    // on recharge localement les demandes via le service admin.
    await widget.onRefresh();
    final freshDemandes = await ServiceLocator.adminService.getDemandes();
    if (mounted) {
      setState(() {
        _demandes = freshDemandes;
        _isLoading = false;
      });
    }
  }

  void _showDemandeDetailsDialog(BuildContext context, DemandeRestaurant demande) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SingleChildScrollView(
            child: widget.cardBuilder(
              dialogContext,
              demande,
              onActionCompleted: () {
                Navigator.of(dialogContext).pop();
                _refresh();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactDemandeRow(BuildContext context, DemandeRestaurant demande) {
    final textTheme = Theme.of(context).textTheme;

    Color statusColor;
    String statusLabel;
    if (demande.estValide) {
      statusColor = AppColors.sauge;
      statusLabel = "Valide";
    } else {
      statusColor = AppColors.rougeSignalement;
      statusLabel = "Rejete";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grisBordure),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.orangeClair,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.storefront_outlined,
            color: AppColors.terracotta,
            size: 20,
          ),
        ),
        title: Text(
          demande.nom,
          style: textTheme.titleLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${demande.typeCuisine ?? 'Cuisine'} · ${demande.quartier ?? 'Adresse'}",
          style: textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppColors.grisTexte),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.settings_suggest_outlined,
                color: AppColors.marronFonce,
                size: 20,
              ),
              onPressed: () => _showDemandeDetailsDialog(context, demande),
              tooltip: "Gerer la decision",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.terracotta),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.terracotta,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final demandesAttente = _demandes.where((d) => !d.estValide && d.motifRejet == null).toList();
    final demandesTraitees = _demandes.where((d) => d.estValide || d.motifRejet != null).toList();

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text("Demandes d'inscriptions"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildSectionHeader("DEMANDES EN ATTENTE", icon: Icons.hourglass_top_rounded),
                    const SizedBox(height: 12),
                    if (demandesAttente.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "Aucune demande en attente.",
                            style: TextStyle(color: AppColors.grisTexte, fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    else
                      ...demandesAttente.map((demande) {
                        return widget.cardBuilder(
                          context,
                          demande,
                          onActionCompleted: _refresh,
                        );
                      }),
                    
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.grisBordure, height: 1),
                    const SizedBox(height: 24),

                    _buildSectionHeader("HISTORIQUE DES DECISIONS", icon: Icons.history_rounded),
                    const SizedBox(height: 12),
                    if (demandesTraitees.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            "Aucun historique de decision.",
                            style: TextStyle(color: AppColors.grisTexte, fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    else
                      ...demandesTraitees.map((demande) {
                        return _buildCompactDemandeRow(context, demande);
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AdminLogsPage extends StatefulWidget {
  const _AdminLogsPage();

  @override
  State<_AdminLogsPage> createState() => _AdminLogsPageState();
}

class _AdminLogsPageState extends State<_AdminLogsPage> {
  bool _isLoading = true;
  List<AdminActionLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final data = await ServiceLocator.adminService.getAdminActionLogs();
      if (mounted) {
        setState(() {
          _logs = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showAppNotification(
          context,
          title: "Erreur",
          message: "Impossible de charger les journaux: $e",
          type: AppFeedbackType.error,
        );
      }
    }
  }

  Color _getActionColor(String action) {
    if (action.contains('valider') || action.contains('debloquer')) {
      return AppColors.sauge;
    } else if (action.contains('bloquer') || action.contains('rejeter') || action.contains('supprimer')) {
      return AppColors.rougeSignalement;
    }
    return AppColors.terracotta;
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'valider_restaurant':
        return 'Validation restaurant';
      case 'rejeter_restaurant':
        return 'Rejet restaurant';
      case 'bloquer_restaurant':
        return 'Suspension restaurant';
      case 'debloquer_restaurant':
        return 'Déblocage restaurant';
      case 'bloquer_utilisateur':
        return 'Blocage utilisateur';
      case 'debloquer_utilisateur':
        return 'Déblocage utilisateur';
      case 'supprimer_utilisateur':
        return 'Suppression utilisateur';
      case 'traiter_signalement':
        return 'Modération signalement';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text("Historique des actions"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadLogs();
            },
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
            : _logs.isEmpty
                ? const Center(child: Text("Aucune action enregistrée."))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final actionColor = _getActionColor(log.action);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grisBordure),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getActionLabel(log.action),
                                    style: TextStyle(
                                      color: actionColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${log.createdAt.day.toString().padLeft(2, '0')}/${log.createdAt.month.toString().padLeft(2, '0')} ${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.grisTexte,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              log.details ?? '',
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.marronFonce,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.grisTexte),
                                const SizedBox(width: 4),
                                Text(
                                  "Par : ${log.adminName}",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.grisTexte,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _AppealsManagementPage extends StatefulWidget {
  const _AppealsManagementPage();

  @override
  State<_AppealsManagementPage> createState() => _AppealsManagementPageState();
}

class _AppealsManagementPageState extends State<_AppealsManagementPage> {
  List<UserAppeal> _appeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppeals();
  }

  Future<void> _loadAppeals() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await ServiceLocator.authService.getAppeals();
      setState(() {
        _appeals = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showAppNotification(
          context,
          title: "Erreur",
          message: "Impossible de charger les recours : $e",
          type: AppFeedbackType.error,
        );
      }
    }
  }

  Future<void> _handleAppeal(UserAppeal appeal, bool accept) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: accept ? "Approuver le recours ?" : "Rejeter le recours ?",
      message: accept
          ? "Toutes les sanctions appliquées à ce compte seront immédiatement levées."
          : "Le recours sera rejeté et les sanctions resteront actives.",
      confirmLabel: accept ? "Approuver" : "Rejeter",
      icon: accept ? Icons.verified_user_outlined : Icons.cancel_outlined,
      type: accept ? AppFeedbackType.success : AppFeedbackType.error,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ServiceLocator.authService.processAppeal(appeal.id, accept: accept);
      if (mounted) {
        showAppNotification(
          context,
          title: accept ? "Recours approuvé" : "Recours rejeté",
          message: accept
              ? "L'utilisateur a été débloqué avec succès."
              : "Le recours a été classé comme rejeté.",
          type: accept ? AppFeedbackType.success : AppFeedbackType.warning,
        );
      }
      _loadAppeals();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showAppNotification(
          context,
          title: "Erreur",
          message: "Échec de l'action : $e",
          type: AppFeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text("Recours & Appels"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppeals,
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
            : _appeals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_outlined, size: 64, color: AppColors.sauge),
                        const SizedBox(height: 16),
                        Text(
                          "Aucun recours en attente",
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.grisTexte,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _appeals.length,
                    itemBuilder: (context, index) {
                      final appeal = _appeals[index];
                      final roleLabel = appeal.userRole == 'gerant' ? 'Gérant' : (appeal.userRole == 'admin' ? 'Admin' : 'Client');
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.grisBordure),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appeal.userName ?? 'Utilisateur inconnu',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${appeal.userEmail ?? ''} · $roleLabel",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.grisTexte,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.terracotta.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "En attente",
                                    style: TextStyle(
                                      color: AppColors.terracotta,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: AppColors.grisBordure),
                            Text(
                              "MESSAGE DE RECOURS :",
                              style: textTheme.labelLarge?.copyWith(
                                color: AppColors.grisTexte,
                                fontSize: 9,
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cremeFonce.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                appeal.message,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.marronFonce,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleAppeal(appeal, false),
                                    icon: const Icon(Icons.cancel_outlined, size: 16),
                                    label: const Text("Rejeter"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.rougeSignalement,
                                      side: const BorderSide(color: AppColors.rougeSignalement),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleAppeal(appeal, true),
                                    icon: const Icon(Icons.verified_user_outlined, size: 16),
                                    label: const Text("Approuver"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.sauge,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
