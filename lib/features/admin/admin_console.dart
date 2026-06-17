import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/utils/image_url_helper.dart';
import '../../core/widgets/app_feedback.dart';

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
      setState(() {
        _isLoading = false;
        _hasError  = true;
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

  Future<void> _toggleUser(User user, bool isActive, {int? dureeJours}) async {
    await ServiceLocator.authService.setAccountActive(user.id, isActive, dureeJours: dureeJours);
    await _loadAdminData();

    if (mounted) {
      showAppNotification(
        context,
        title: isActive ? 'Compte reactive' : 'Compte suspendu',
        message: isActive
            ? "Compte de ${user.name} reactive."
            : "Compte de ${user.name} suspendu.",
        type: isActive ? AppFeedbackType.success : AppFeedbackType.warning,
      );
    }
  }


  String _getFullUrl(String? path) {
    return ImageUrlHelper.resolve(path);
  }

  void _viewDocument(String? url, String title) {
    if (url == null || url.isEmpty) return;
    final fullUrl = _getFullUrl(url);
    final isImage = url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.webp');

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: Theme.of(context).textTheme.titleLarge),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
            child: isImage
                ? Image.network(
                    fullUrl,
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          "Erreur lors du chargement de l'image.\nAdresse : $fullUrl",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.rougeSignalement),
                        ),
                      );
                    },
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 80,
                        color: AppColors.terracotta,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Document PDF",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        fullUrl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.grisTexte, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: fullUrl));
                          showAppNotification(
                            context,
                            title: 'Lien copie',
                            message: 'Lien copie dans le presse-papiers.',
                            type: AppFeedbackType.success,
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copier le lien'),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
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
                          const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.grisTexte),
                          const SizedBox(height: 16),
                          Text(
                            'Impossible de charger les données',
                            style: textTheme.titleLarge?.copyWith(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vérifiez votre connexion et réessayez.',
                            style: textTheme.bodyMedium?.copyWith(color: AppColors.grisTexte),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
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
                          _buildAdminKpiCard(
                            context,
                            _users.length.toString(),
                            "COMPTES",
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
                                onToggleActive: (user, active, {dureeJours}) async {
                                  await _toggleUser(user, active, dureeJours: dureeJours);
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
                                onToggleActive: (user, active, {dureeJours}) async {
                                  await _toggleUser(user, active, dureeJours: dureeJours);
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
                _buildDocBadge("IFU: ${demande.ifuNumero}", () => _viewDocument(demande.ifuAttestationUrl, "Attestation IFU")),
              if (demande.rccmNumero != null)
                _buildDocBadge("RCCM: ${demande.rccmNumero}", () => _viewDocument(demande.rccmExtraitUrl, "Extrait RCCM")),
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

  Widget _buildDocBadge(String label, VoidCallback onTap) {
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
                          _buildStatRow(Icons.person_outline, "Clients / Visiteurs", _stats!['users']?['clients']?.toString() ?? '0'),
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
  final Future<void> Function(User, bool, {int? dureeJours}) onToggleActive;

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
      final matchesRole = u.role == widget.roleFilter;
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
      message: "Cette action est irréversible. Le compte de ${user.name} sera supprimé de la plateforme.",
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

    final title = widget.roleFilter == 'gerant' ? "Comptes gérants" : "Comptes clients";

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
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDFBF7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.grisBordure),
                                ),
                                child: Row(
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
                                                  color: user.isActive ? AppColors.vertClair : AppColors.rougeClair,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  user.isActive ? "Actif" : "Suspendu",
                                                  style: TextStyle(
                                                    color: user.isActive ? AppColors.sauge : AppColors.rougeSignalement,
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
                                        IconButton(
                                          icon: Icon(
                                            user.isActive ? Icons.lock_outline : Icons.lock_open,
                                            color: AppColors.marronFonce,
                                            size: 22,
                                          ),
                                          onPressed: () async {
                                            if (user.isActive) {
                                              final duree = await _showBlockDurationDialog(context, user);
                                              if (duree != null) {
                                                final int? days = duree == -1 ? null : duree;
                                                await widget.onToggleActive(user, false, dureeJours: days);
                                                _refresh();
                                              }
                                            } else {
                                              final confirmed = await showAppConfirmDialog(
                                                context,
                                                title: 'Reactiver ce compte ?',
                                                message: "Le compte de ${user.name} sera reactive.",
                                                confirmLabel: 'Reactiver',
                                                icon: Icons.lock_open_rounded,
                                                type: AppFeedbackType.success,
                                              );
                                              if (confirmed) {
                                                await widget.onToggleActive(user, true);
                                                _refresh();
                                              }
                                            }
                                          },
                                          tooltip: user.isActive ? "Bloquer" : "Activer",
                                        ),
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

  Future<int?> _showBlockDurationDialog(BuildContext context, User user) {
    return showDialog<int?>(
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
                        Icons.block_rounded,
                        color: AppColors.rougeSignalement,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Bloquer le compte",
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
                  "Choisissez la duree du blocage pour le compte de ${user.name} (${user.email}) :",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text("3 jours"),
                  leading: const Icon(Icons.timer_outlined, color: AppColors.marronFonce),
                  onTap: () => Navigator.of(context).pop(3),
                ),
                ListTile(
                  title: const Text("7 jours"),
                  leading: const Icon(Icons.date_range_outlined, color: AppColors.marronFonce),
                  onTap: () => Navigator.of(context).pop(7),
                ),
                ListTile(
                  title: const Text("30 jours"),
                  leading: const Icon(Icons.calendar_month_outlined, color: AppColors.marronFonce),
                  onTap: () => Navigator.of(context).pop(30),
                ),
                ListTile(
                  title: const Text("Definitif (Permanent)"),
                  leading: const Icon(Icons.block_rounded, color: AppColors.rougeSignalement),
                  onTap: () => Navigator.of(context).pop(-1),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text("Annuler"),
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
