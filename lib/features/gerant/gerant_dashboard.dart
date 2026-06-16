import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/utils/image_url_helper.dart';
import '../../core/utils/qr_download_helper.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/restaurant_logo.dart';
import 'register_restaurant_screen.dart';
import 'restaurant_management_screen.dart';

// Note de soutenance : Ce dashboard utilise getRestaurantsByManager() pour
// charger dynamiquement les restaurants du gérant connecté. Un ID hardcodé
// aurait empêché de gérer plusieurs établissements.

class GerantDashboard extends StatefulWidget {
  const GerantDashboard({super.key});

  @override
  State<GerantDashboard> createState() => _GerantDashboardState();
}

class _GerantDashboardState extends State<GerantDashboard> {
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final currentUser = ServiceLocator.authService.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Utilisateur non connecté.';
      });
      return;
    }

    try {
      final list = await ServiceLocator.restaurantService
          .getRestaurantsByManager(currentUser.id);
      if (!mounted) return;
      setState(() {
        _restaurants = list;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger vos restaurants : $e';
      });
    }
  }

  void _openRestaurantManagement(Restaurant restaurant) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                RestaurantManagementScreen(restaurant: restaurant),
          ),
        )
        .then((_) => _loadRestaurants());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final currentUser = ServiceLocator.authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRestaurants,
          color: AppColors.terracotta,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
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
                                  'ESPACE GÉRANT',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: AppColors.grisTexte,
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUser != null
                                      ? '${currentUser.prenom} ${currentUser.nom}'
                                      : 'Mes restaurants',
                                  style: textTheme.displayLarge?.copyWith(fontSize: 26),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gerez vos etablissements et suivez leur statut.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.grisTexte,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Contenu principal
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.rougeSignalement, size: 48),
                          const SizedBox(height: 12),
                          Text(_errorMessage!,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_restaurants.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppColors.orangeClair,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              color: AppColors.terracotta,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Aucun restaurant pour l\'instant',
                            style: textTheme.titleLarge
                                ?.copyWith(fontSize: 19),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Appuyez sur « Nouveau restaurant » pour soumettre votre établissement à validation.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.grisTexte,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildRestaurantCard(
                          context, _restaurants[index]),
                      childCount: _restaurants.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, Restaurant restaurant) {
    final textTheme = Theme.of(context).textTheme;

    final isValidated = restaurant.estValide;
    final isRejected = !restaurant.estValide &&
        restaurant.motifRejet != null &&
        restaurant.motifRejet!.isNotEmpty;
    final isPending = !restaurant.estValide && !isRejected;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (restaurant.estArchive) {
      statusColor = AppColors.grisTexte;
      statusIcon = Icons.visibility_off_outlined;
      statusLabel = 'Masqué';
    } else if (isValidated) {
      statusColor = AppColors.sauge;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Validé';
    } else if (isRejected) {
      statusColor = AppColors.rougeSignalement;
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'Rejeté';
    } else {
      statusColor = AppColors.terracotta;
      statusIcon = Icons.hourglass_top_rounded;
      statusLabel = 'En attente';
    }

    return GestureDetector(
      onTap: () => _openRestaurantManagement(restaurant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFBF7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isValidated
                ? AppColors.grisBordure
                : statusColor.withValues(alpha: 0.35),
            width: isValidated ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Photo de couverture (si validé et photo dispo)
            if (isValidated && restaurant.photoUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: ImageUrlHelper.buildImage(
                    restaurant.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(color: AppColors.cremeFonce),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne logo + infos + badge statut
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RestaurantLogo(
                        logoUrl: restaurant.logoUrl,
                        restaurantName: restaurant.nom,
                        size: 58,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.nom,
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${restaurant.typeCuisine} · ${restaurant.quartier}',
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: AppColors.grisTexte,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 13, color: AppColors.grisTexte),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    restaurant.adresse,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      color: AppColors.grisTexte,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge statut
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Message contextuel selon le statut
                  if (restaurant.estArchive) ...[
                    _buildStatusBanner(
                      icon: Icons.visibility_off_outlined,
                      color: AppColors.grisTexte,
                      message:
                          'Ce restaurant est actuellement masqué (archivé). Les clients ne peuvent plus le voir ni passer commande.',
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isPending)
                    _buildStatusBanner(
                      icon: Icons.hourglass_empty_rounded,
                      color: AppColors.terracotta,
                      message:
                          'Votre demande est en cours d\'examen par l\'administrateur. Vous recevrez une notification dès que votre restaurant sera validé.',
                    )
                  else if (isRejected) ...[
                    _buildStatusBanner(
                      icon: Icons.info_outline_rounded,
                      color: AppColors.rougeSignalement,
                      message:
                          'Motif de rejet : ${restaurant.motifRejet}\n\nVeuillez corriger votre dossier et soumettre une nouvelle demande.',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => RegisterRestaurantScreen(
                                restaurantToEdit: restaurant,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadRestaurants();
                          }
                        },
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Corriger et resoumettre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.terracotta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ]
                  else ...[
                    // Restaurant validé — stats rapides + bouton ouvrir
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatChip(
                            icon: Icons.restaurant_menu_rounded,
                            label: '${restaurant.menu.length} plats',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _openRestaurantManagement(restaurant),
                            icon: const Icon(Icons.settings_rounded, size: 16),
                            label: const Text('Gérer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.terracotta,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Bouton QR code
                        _QrDownloadButton(restaurant: restaurant),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cremeFonce.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: AppColors.marronFonce),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.marronFonce,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget séparé pour le bouton QR avec RepaintBoundary — compatible Web
class _QrDownloadButton extends StatefulWidget {
  final Restaurant restaurant;
  const _QrDownloadButton({required this.restaurant});

  @override
  State<_QrDownloadButton> createState() => _QrDownloadButtonState();
}

class _QrDownloadButtonState extends State<_QrDownloadButton> {
  bool _isGenerating = false;

  Future<void> _downloadQr() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      // Afficher d'abord le dialog avec le QR pour permettre la capture
      await _showQrDialog();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _showQrDialog() async {
    final rest = widget.restaurant;

    await showDialog<void>(
      context: context,
      builder: (ctx) => QrDialog(restaurant: rest),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _isGenerating ? null : _downloadQr,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: const BorderSide(color: AppColors.terracotta),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isGenerating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.terracotta),
            )
          : const Icon(Icons.qr_code_2, color: AppColors.terracotta, size: 20),
    );
  }
}

// Dialog QR code qui utilise RepaintBoundary pour capturer l'image
class QrDialog extends StatefulWidget {
  final Restaurant restaurant;
  const QrDialog({required this.restaurant, super.key});

  @override
  State<QrDialog> createState() => QrDialogState();
}

class QrDialogState extends State<QrDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _captureAndDownload() async {
    setState(() => _isDownloading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // laisser le widget se rendre

      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('QR non rendu');

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Erreur export PNG');

      final bytes = byteData.buffer.asUint8List();
      final cleanName = widget.restaurant.nom
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .replaceAll(' ', '_');
      final fileName = 'QR_${cleanName}_TrueAts.png';

      if (kIsWeb) {
        await saveFile(bytes, fileName);
      } else {
        // Mobile / Desktop — fallback non-web (non utilisé sur Chrome)
        await saveFile(bytes, fileName);
      }

      if (mounted) {
        Navigator.of(context).pop();
        showAppNotification(
          context,
          title: 'QR code téléchargé',
          message: 'Le QR code de ${widget.restaurant.nom} a été téléchargé.',
          type: AppFeedbackType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppNotification(
          context,
          title: 'Erreur',
          message: 'Impossible de télécharger le QR code : $e',
          type: AppFeedbackType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Import conditionnel de qr_flutter
    return Dialog(
      backgroundColor: AppColors.creme,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR Code',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              widget.restaurant.nom,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.terracotta,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // RepaintBoundary — capture le QR pour export PNG
            RepaintBoundary(
              key: _repaintKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: QrImageWidget(data: widget.restaurant.qrCode),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.restaurant.qrCode,
              style: const TextStyle(fontSize: 10, color: AppColors.grisTexte),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _captureAndDownload,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_isDownloading ? 'Téléchargement...' : 'Télécharger'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.terracotta,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget QR réel via qr_flutter — fonctionne sur web et mobile
class QrImageWidget extends StatelessWidget {
  final String data;
  const QrImageWidget({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data.isEmpty ? 'trueats_placeholder' : data,
      version: QrVersions.auto,
      size: 200.0,
      backgroundColor: Colors.white,
      errorStateBuilder: (ctx, err) => const Center(
        child: Text('Erreur QR', style: TextStyle(color: Colors.red)),
      ),
    );
  }
}
