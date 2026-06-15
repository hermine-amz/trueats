import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_feedback.dart';

class RestaurantManagementScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantManagementScreen({super.key, required this.restaurant});

  @override
  State<RestaurantManagementScreen> createState() =>
      _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState
    extends State<RestaurantManagementScreen> {
  late Restaurant _restaurant;
  List<Avis> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restaurant = widget.restaurant;
    _loadData();
  }

  Future<void> _loadData() async {
    final restaurant = await ServiceLocator.restaurantService.getRestaurantById(
      _restaurant.id,
    );
    final reviews = await ServiceLocator.reviewService.getReviewsForRestaurant(
      _restaurant.id,
    );
    if (!mounted) return;
    setState(() {
      _restaurant = restaurant ?? _restaurant;
      _reviews = reviews;
      _isLoading = false;
    });
  }

  double _averageRating() {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<int>(0, (sum, avis) => sum + avis.note);
    return total / _reviews.length;
  }

  Future<void> _simulateQrDownload() async {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.creme,
          title: const Row(
            children: [
              Icon(Icons.download, color: AppColors.terracotta),
              SizedBox(width: 8),
              Text('Telechargement QR'),
            ],
          ),
          content: Text(
            'Generation du document PDF contenant le QR code unique de ${_restaurant.nom}.\n\n'
            'Le gerant peut l imprimer et le placer sur les tables.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPlatSheet({Plat? plat}) async {
    final nameController = TextEditingController(text: plat?.nom ?? '');
    final descriptionController = TextEditingController(
      text: plat?.description ?? '',
    );
    final priceController = TextEditingController(
      text: plat == null ? '' : plat.prix.toInt().toString(),
    );
    final categoryController = TextEditingController(
      text: plat?.categorie ?? 'Plats Principaux',
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
                      plat == null ? 'Ajouter un plat' : 'Modifier le plat',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix',
                        suffixText: 'FCFA',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'Categorie'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.sauge,
                      value: isAvailable,
                      title: const Text('Disponible'),
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
                            title: 'Champs requis',
                            message: 'Renseignez le nom et le prix.',
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
                              ? 'Autres'
                              : categoryController.text.trim(),
                        );

                        if (plat == null) {
                          await ServiceLocator.restaurantService
                              .addPlatToRestaurant(_restaurant.id, dish);
                        } else {
                          await ServiceLocator.restaurantService
                              .updatePlatInRestaurant(_restaurant.id, dish);
                        }

                        if (!mounted) return;
                        navigator.pop();
                        await _loadData();
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
                      child: Text(plat == null ? 'Ajouter' : 'Enregistrer'),
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
      _restaurant.id,
      plat.id,
    );
    if (!mounted) return;
    await _loadData();
    showAppNotification(
      context,
      title: 'Plat retire',
      message: '${plat.nom} a ete retire du menu.',
      type: AppFeedbackType.success,
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
                onRefresh: _loadData,
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
                        'ESPACE GERANT',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.grisTexte,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _restaurant.nom,
                        style: textTheme.displayLarge?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _restaurant.adresse,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.grisTexte,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildKpiCard(
                            context,
                            'NOTE',
                            _averageRating().toStringAsFixed(1),
                            'avis verifies',
                          ),
                          const SizedBox(width: 12),
                          _buildKpiCard(
                            context,
                            'AVIS',
                            _reviews.length.toString(),
                            'publies',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildQrAction(context),
                      const SizedBox(height: 28),
                      _buildMenuSection(context),
                      const SizedBox(height: 28),
                      Text(
                        'DERNIERS AVIS',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.grisTexte,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_reviews.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text('Aucun avis depose pour le moment.'),
                          ),
                        )
                      else
                        ..._reviews.map(
                          (review) => _buildReviewTile(context, review),
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
      onTap: _simulateQrDownload,
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
                    'QR code du restaurant',
                    style: textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Telecharger pour impression',
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

  Widget _buildMenuSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groupedMenu = <String, List<Plat>>{};
    for (final plat in _restaurant.menu) {
      groupedMenu.putIfAbsent(plat.categorie, () => <Plat>[]).add(plat);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GERER MENU',
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
              label: const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (groupedMenu.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: const Text('Aucun plat pour le moment.'),
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
                Text(plat.nom, style: textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  plat.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${plat.prix.toInt()} FCFA',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.terracotta,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: plat.disponible
                            ? AppColors.sauge.withValues(alpha: 0.16)
                            : AppColors.grisBordure.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        plat.disponible ? 'Disponible' : 'Indisponible',
                        style: textTheme.bodySmall?.copyWith(
                          color: plat.disponible
                              ? AppColors.sauge
                              : AppColors.grisTexte,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Modifier',
            onPressed: () => _showPlatSheet(plat: plat),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Retirer',
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

  Widget _buildReviewTile(BuildContext context, Avis review) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.nomAuteur, style: textTheme.titleLarge),
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.terracotta, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    review.note.toString(),
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(review.commentaire, style: textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            'Publie le ${review.dateVisite.day}/${review.dateVisite.month}/${review.dateVisite.year}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.grisTexte),
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
            Text(trend, style: textTheme.bodyMedium?.copyWith(fontSize: 11)),
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
}
