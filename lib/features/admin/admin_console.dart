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

  void _showAccountsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.creme,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.78,
              minChildSize: 0.45,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gerer les comptes",
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Activation, suspension et verification rapide des roles.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return _buildUserTile(
                              context,
                              user,
                              onChanged: (value) async {
                                final confirmed =
                                    await _confirmToggleUser(user, value);
                                if (!confirmed) return;
                                setSheetState(() {
                                  final localIndex = _users.indexWhere(
                                    (item) => item.id == user.id,
                                  );
                                  if (localIndex != -1) {
                                    _users[localIndex] = user.copyWith(
                                      isActive: value,
                                    );
                                  }
                                });
                                await _toggleUser(user, value);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
                      _buildSectionTitle(context, "DEMANDES D'INSCRIPTION"),
                      const SizedBox(height: 14),
                      if (_demandes.isEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(18),
                          decoration: _cardDecoration(),
                          child: const Text("Aucune demande d'inscription en attente."),
                        )
                      else
                        ..._demandes.map(
                          (demande) => _buildDemandeCard(context, demande),
                        ),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, "FILE DE SIGNALEMENTS"),
                      const SizedBox(height: 14),
                      if (_signalements.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: _cardDecoration(),
                          child: const Text("Aucun signalement en attente."),
                        )
                      else
                        ..._signalements.map(
                          (signalement) =>
                              _buildSignalementCard(context, signalement),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAccountsSheet,
                          icon: const Icon(Icons.people_outline),
                          label: const Text("Gerer les comptes"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cremeFonce,
                            foregroundColor: AppColors.marronFonce,
                            side: const BorderSide(
                              color: AppColors.grisBordure,
                            ),
                          ),
                        ),
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

  Widget _buildSignalementCard(BuildContext context, Signalement signalement) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.rougeClair,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.rougeSignalement,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signalement.avis.nomAuteur,
                      style: textTheme.titleLarge?.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "sur ${signalement.avis.restaurantNom} - il y a ${_getTimeAgo(signalement.dateSignalement)}",
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            signalement.raison,
            style: textTheme.bodyLarge?.copyWith(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _confirmResolveSignalement(signalement, false),
                  icon: const Icon(Icons.close, size: 16),
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
                  onPressed: () =>
                      _confirmResolveSignalement(signalement, true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text("Valider"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertClair,
                    foregroundColor: AppColors.sauge,
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

  Widget _buildUserTile(
    BuildContext context,
    User user, {
    required ValueChanged<bool> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                user.isActive ? AppColors.vertClair : AppColors.rougeClair,
            child: Icon(
              _roleIcon(user.role),
              color:
                  user.isActive ? AppColors.sauge : AppColors.rougeSignalement,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: textTheme.titleLarge?.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  "${user.email} - ${user.role}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: user.isActive,
            activeColor: AppColors.sauge,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  IconData _roleIcon(String role) {
    if (role == "admin") {
      return Icons.admin_panel_settings;
    }
    if (role == "gerant") {
      return Icons.restaurant_menu;
    }
    return Icons.person;
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cremeFonce,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grisBordure),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.file_present_outlined, size: 14, color: AppColors.terracotta),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.marronFonce,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
