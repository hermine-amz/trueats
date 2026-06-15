import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/review_card.dart';

class GerantDashboard extends StatefulWidget {
  const GerantDashboard({super.key});

  @override
  State<GerantDashboard> createState() => _GerantDashboardState();
}

class _GerantDashboardState extends State<GerantDashboard> {
  static const int _managedRestaurantId = 3;

  Restaurant? _restaurant;
  List<Avis> _recentAvis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final restaurant = await ServiceLocator.restaurantService.getRestaurantById(
      _managedRestaurantId,
    );
    final reviews = await ServiceLocator.reviewService.getReviewsForRestaurant(
      _managedRestaurantId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _restaurant = restaurant;
      _recentAvis = reviews;
      _isLoading = false;
    });
  }

  Future<void> _reloadRestaurant() async {
    final restaurant = await ServiceLocator.restaurantService.getRestaurantById(
      _managedRestaurantId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _restaurant = restaurant;
    });
  }

  Future<void> _downloadQrCode() async {
    final rest = _restaurant;
    if (rest == null) return;
    
    try {
      final qrValidationResult = QrValidator.validate(
        data: rest.qrCode,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );
        
        final ui.Image image = await painter.toImage(400);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytes = byteData!.buffer.asUint8List();
        
        final Directory tempDir;
        if (Platform.isAndroid || Platform.isIOS) {
          tempDir = await getApplicationDocumentsDirectory();
        } else {
          tempDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        }
        
        final cleanName = rest.nom.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
        final filePath = '${tempDir.path}/QR_code_$cleanName.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        if (mounted) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: AppColors.creme,
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.sauge),
                    SizedBox(width: 8),
                    Text('Téléchargement réussi'),
                  ],
                ),
                content: Text(
                  'Le QR code a été enregistré avec succès sous :\n\n$filePath\n\n'
                  'Vous pouvez maintenant l\'imprimer pour vos clients.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Super !'),
                  ),
                ],
              );
            },
          );
        }
      } else {
        throw Exception("QR Code invalide.");
      }
    } catch (e) {
      if (mounted) {
        showAppNotification(
          context,
          title: "Erreur de téléchargement",
          message: e.toString(),
          type: AppFeedbackType.error,
        );
      }
    }
  }

  void _showQrCodeDialog() {
    final rest = _restaurant;
    if (rest == null) return;
    
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.creme,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'QR Code Table',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  rest.nom,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.terracotta),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.grisBordure),
                    ),
                    child: QrImageView(
                      data: rest.qrCode,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Identifiant table: ${rest.qrCode}',
                  style: const TextStyle(fontSize: 12, color: AppColors.grisTexte),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _downloadQrCode();
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Télécharger l\'image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPlatSheet({Plat? plat}) async {
    final nameController = TextEditingController(text: plat?.nom ?? "");
    final descriptionController = TextEditingController(
      text: plat?.description ?? "",
    );
    final priceController = TextEditingController(
      text: plat == null ? "" : plat.prix.toInt().toString(),
    );
    final categoryController = TextEditingController(
      text: plat?.categorie ?? "Plats Principaux",
    );
    bool isAvailable = plat?.disponible ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.creme,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      plat == null ? "Ajouter un plat" : "Modifier le plat",
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Nom"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Prix",
                        suffixText: "FCFA",
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: "Categorie",
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.sauge,
                      value: isAvailable,
                      title: const Text("Disponible"),
                      onChanged: (value) {
                        setSheetState(() {
                          isAvailable = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final name = nameController.text.trim();
                        final price = double.tryParse(
                          priceController.text.trim(),
                        );

                        if (name.isEmpty || price == null) {
                          showAppNotification(
                            context,
                            title: "Champs requis",
                            message: "Renseignez le nom et le prix.",
                            type: AppFeedbackType.warning,
                          );
                          return;
                        }

                        if (plat != null) {
                          final confirmed = await showAppConfirmDialog(
                            context,
                            title: 'Enregistrer les modifications ?',
                            message: 'Les informations de ${plat.nom} seront mises a jour dans le menu.',
                            confirmLabel: 'Enregistrer',
                            icon: Icons.edit_outlined,
                            type: AppFeedbackType.info,
                          );
                          if (!confirmed) return;
                        }

                        final dish = Plat(
                          id: plat?.id ?? 0,
                          nom: name,
                          description: descriptionController.text.trim(),
                          prix: price,
                          disponible: isAvailable,
                          categorie: categoryController.text.trim().isEmpty
                              ? "Autres"
                              : categoryController.text.trim(),
                        );

                        if (plat == null) {
                          await ServiceLocator.restaurantService
                              .addPlatToRestaurant(_managedRestaurantId, dish);
                        } else {
                          await ServiceLocator.restaurantService
                              .updatePlatInRestaurant(
                            _managedRestaurantId,
                            dish,
                          );
                        }

                        if (!mounted) return;
                        navigator.pop();
                        await _reloadRestaurant();
                        if (!mounted) return;
                        showAppNotification(
                          context,
                          title: plat == null ? 'Plat ajoute' : 'Plat modifie',
                          message: plat == null
                              ? '$name a ete ajoute au menu.'
                              : '$name a ete mis a jour.',
                          type: AppFeedbackType.success,
                        );
                      },
                      child: Text(plat == null ? "Ajouter" : "Enregistrer"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    categoryController.dispose();
  }

  Future<void> _removePlat(Plat plat) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Retirer ce plat ?',
      message: '${plat.nom} sera retire du menu.',
      confirmLabel: 'Retirer',
      icon: Icons.delete_outline_rounded,
      type: AppFeedbackType.error,
    );
    if (!confirmed) return;

    await ServiceLocator.restaurantService.removePlatFromRestaurant(
      _managedRestaurantId,
      plat.id,
    );
    await _reloadRestaurant();

    if (mounted) {
      showAppNotification(
        context,
        title: 'Plat retire',
        message: "${plat.nom} a ete retire du menu.",
        type: AppFeedbackType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final restaurant = _restaurant;

    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboard,
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
                        "ESPACE GERANT",
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.grisTexte,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant?.nom ?? "Mon restaurant",
                        style: textTheme.displayLarge?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildKpiCard(context, "NOTE", _averageRating(), "avis verifies"),
                          const SizedBox(width: 12),
                          _buildKpiCard(
                            context,
                            "AVIS",
                            _recentAvis.length.toString(),
                            "publies",
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildQrAction(context),
                      const SizedBox(height: 28),
                      _buildMenuSection(context, restaurant),
                      const SizedBox(height: 28),
                      Text(
                        "DERNIERS AVIS",
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.grisTexte,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_recentAvis.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text("Aucun avis depose pour le moment."),
                          ),
                        )
                      else
                        ..._recentAvis.map(
                          (review) => ReviewCard(
                            avis: review,
                            reviewService: ServiceLocator.reviewService,
                            onReviewActionCompleted: _loadDashboard,
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

  Widget _buildQrAction(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: _showQrCodeDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.orangeClair,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.terracotta.withValues(alpha: 0.15),
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.terracotta,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "QR code du restaurant",
                    style: textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Telecharger pour impression",
                    style: textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.terracotta),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, Restaurant? restaurant) {
    final textTheme = Theme.of(context).textTheme;
    final groupedMenu = <String, List<Plat>>{};
    for (final plat in restaurant?.menu ?? <Plat>[]) {
      groupedMenu.putIfAbsent(plat.categorie, () => <Plat>[]).add(plat);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "GERER MENU",
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.grisTexte,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showPlatSheet(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Ajouter"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (groupedMenu.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: const Text("Aucun plat pour le moment."),
          )
        else
          ...groupedMenu.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map((plat) => _buildDishTile(context, plat)),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDishTile(BuildContext context, Plat plat) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plat.nom,
                  style: textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  plat.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "${plat.prix.toInt()} FCFA",
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.terracotta,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Modifier",
            onPressed: () => _showPlatSheet(plat: plat),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: "Retirer",
            onPressed: () => _removePlat(plat),
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.rougeSignalement,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String value,
    String trend,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.grisTexte,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: textTheme.displayMedium?.copyWith(
                color: AppColors.terracotta,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trend,
              style: textTheme.bodyMedium?.copyWith(fontSize: 11),
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

  String _averageRating() {
    if (_recentAvis.isEmpty) {
      return "0.0";
    }

    final total = _recentAvis.fold<int>(0, (sum, avis) => sum + avis.note);
    return (total / _recentAvis.length).toStringAsFixed(1);
  }
}
