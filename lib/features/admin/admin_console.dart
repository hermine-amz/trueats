import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/http_services.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final signalements = await ServiceLocator.reviewService.getSignalements();
    final users = await ServiceLocator.authService.getAllUsers();
    final demandes = await ServiceLocator.adminService.getDemandes();

    if (!mounted) {
      return;
    }

    setState(() {
      _signalements = signalements;
      _users = users;
      _demandes = demandes;
      _isLoading = false;
    });
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

  Future<void> _toggleUser(User user, bool isActive) async {
    await ServiceLocator.authService.setAccountActive(user.id, isActive);
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

  Future<bool> _confirmToggleUser(User user, bool isActive) {
    return showAppConfirmDialog(
      context,
      title: isActive ? 'Reactiver ce compte ?' : 'Suspendre ce compte ?',
      message: isActive
          ? "${user.name} pourra de nouveau utiliser son compte."
          : "${user.name} ne pourra plus acceder a son compte jusqu'a reactivation.",
      confirmLabel: isActive ? 'Reactiver' : 'Suspendre',
      icon: isActive
          ? Icons.lock_open_rounded
          : Icons.block_rounded,
      type: isActive ? AppFeedbackType.success : AppFeedbackType.warning,
    );
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

  Future<void> _validerDemande(int restaurantId, {required bool accepte, String? motifRejet}) async {
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

  void _promptRejet(int restaurantId) {
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
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.marronFonce),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "CONSOLE ADMIN",
                                  style: textTheme.labelLarge?.copyWith(
                                    color: AppColors.grisTexte,
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Supervision",
                                  style: textTheme.displayLarge?.copyWith(fontSize: 28),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _buildAdminKpiCard(
                            context,
                            _signalements.length.toString(),
                            "A TRAITER",
                            AppColors.rougeSignalement,
                          ),
                          _buildAdminKpiCard(
                            context,
                            _demandes.length.toString(),
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
                        _demandes.isEmpty
                            ? "Aucune demande en attente"
                            : "${_demandes.length} demande(s) en attente",
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
                        _signalements.isEmpty
                            ? "Aucun signalement en attente"
                            : "${_signalements.length} signalement(s) à traiter",
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
                                onToggleActive: (user, active) async {
                                  final confirmed = await _confirmToggleUser(user, active);
                                  if (confirmed) {
                                    await _toggleUser(user, active);
                                  }
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
                                onToggleActive: (user, active) async {
                                  final confirmed = await _confirmToggleUser(user, active);
                                  if (confirmed) {
                                    await _toggleUser(user, active);
                                  }
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

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 1) {
      return "${diff.inMinutes}m";
    }
    if (diff.inDays < 1) {
      return "${diff.inHours}h";
    }
    return "${diff.inDays}j";
  }

  Widget _buildDemandeCard(BuildContext context, DemandeRestaurant demande) {
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
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.grisBordure, height: 1),
          const SizedBox(height: 12),
          
          _buildInfoRow(Icons.location_on_outlined, "Adresse", "${demande.adresse} (${demande.quartier ?? ''})"),
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _promptRejet(demande.id),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text("Rejeter"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rougeSignalement,
                    side: const BorderSide(color: AppColors.rougeSignalement),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                      _validerDemande(demande.id, accepte: true);
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

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    await widget.onRefresh();
    if (mounted) {
      setState(() {
        _signalements = widget.initialSignalements;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
        color: const Color(0xFFFDFBF7),
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
              const SizedBox(width: 10),
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
  final Future<void> Function(User, bool) onToggleActive;

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
  late List<User> _filteredUsers;
  bool _isLoading = false;
  String _searchQuery = "";
  int _currentPage = 0;
  static const int _itemsPerPage = 8;

  @override
  void initState() {
    super.initState();
    _applyFilterAndSearch();
  }

  void _applyFilterAndSearch() {
    _filteredUsers = widget.initialUsers.where((u) {
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
    if (mounted) {
      setState(() {
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
      if (mounted) {
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
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              child: DataTable(
                                horizontalMargin: 12,
                                columnSpacing: 20,
                                columns: const [
                                  DataColumn(label: Text("ID")),
                                  DataColumn(label: Text("Nom")),
                                  DataColumn(label: Text("Email")),
                                  DataColumn(label: Text("Statut")),
                                  DataColumn(label: Text("Actions")),
                                ],
                                rows: displayedUsers.map((user) {
                                  return DataRow(cells: [
                                    DataCell(Text(user.id.toString())),
                                    DataCell(Text(user.name)),
                                    DataCell(Text(user.email)),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: user.isActive ? AppColors.vertClair : AppColors.rougeClair,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          user.isActive ? "Actif" : "Suspendu",
                                          style: TextStyle(
                                            color: user.isActive ? AppColors.sauge : AppColors.rougeSignalement,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              user.isActive ? Icons.lock_outline : Icons.lock_open,
                                              color: AppColors.marronFonce,
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              await widget.onToggleActive(user, !user.isActive);
                                              _refresh();
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AppColors.rougeSignalement,
                                              size: 20,
                                            ),
                                            onPressed: () => _deleteAccount(user),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              ),
                            ),
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
        color: const Color(0xFFFDFBF7),
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
}

class _DemandesValidationPage extends StatefulWidget {
  final List<DemandeRestaurant> initialDemandes;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext, DemandeRestaurant) cardBuilder;

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
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _demandes = widget.initialDemandes;
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    await widget.onRefresh();
    if (mounted) {
      setState(() {
        _demandes = widget.initialDemandes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_demandes.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < _demandes.length)
        ? startIndex + _itemsPerPage
        : _demandes.length;
    final displayedDemandes = _demandes.isEmpty
        ? <DemandeRestaurant>[]
        : _demandes.sublist(startIndex, endIndex);

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
            : _demandes.isEmpty
                ? const Center(child: Text("Aucune demande d'inscription en attente."))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: displayedDemandes.length,
                          itemBuilder: (context, index) {
                            final demande = displayedDemandes[index];
                            return widget.cardBuilder(context, demande);
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
        color: const Color(0xFFFDFBF7),
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
}
