import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/utils/image_url_helper.dart';
import '../../core/widgets/app_feedback.dart';
import '../../core/widgets/image_picker_field.dart';
import 'gerant_dashboard.dart';
import 'register_restaurant_screen.dart';
import '../../core/widgets/restaurant_logo.dart';
import '../restaurant/restaurant_details_screen.dart';

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

  Future<void> _downloadQrCode() async {
    await showDialog<void>(
      context: context,
      builder: (context) => QrDialog(restaurant: _restaurant),
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
    final categoryController = TextEditingController();

    // 1. Extraire uniquement les categories existantes du menu du restaurant
    final existingCategories = _restaurant.menu.map((p) => p.categorie).toSet().toList();
    final allCategories = existingCategories;

    String selectedCategory = "";
    if (plat != null && allCategories.contains(plat.categorie)) {
      selectedCategory = plat.categorie;
    } else if (allCategories.isNotEmpty && plat == null) {
      selectedCategory = allCategories.first;
    } else {
      selectedCategory = "Autre...";
    }

    final dropdownOptions = [...allCategories, "Autre..."];
    if (selectedCategory == "Autre...") {
      categoryController.text = plat?.categorie ?? "";
    } else {
      categoryController.text = selectedCategory;
    }

    // 2. Gestion de l'image
    XFile? localImageFile;
    String? currentImageUrl = plat?.imageUrl;
    bool isSaving = false;
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
          builder: (dialogContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          plat == null ? "Ajouter un plat" : "Modifier le plat",
                          style: Theme.of(dialogContext).textTheme.displaySmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Nom"),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Prix",
                        suffixText: "FCFA",
                      ),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: "Catégorie"),
                      items: dropdownOptions.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: isSaving ? null : (value) {
                        setSheetState(() {
                          selectedCategory = value ?? "Plats Principaux";
                          if (selectedCategory != "Autre...") {
                            categoryController.text = selectedCategory;
                          } else {
                            categoryController.text = "";
                          }
                        });
                      },
                    ),
                    if (selectedCategory == "Autre...") ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: "Saisir une nouvelle catégorie",
                          hintText: "Ex: Salades, Cocktails...",
                        ),
                        enabled: !isSaving,
                      ),
                    ],
                    const SizedBox(height: 16),
                    ImagePickerField(
                      label: "Photo du plat",
                      imageUrl: currentImageUrl,
                      localFile: localImageFile,
                      isUploading: isSaving,
                      onPick: () async {
                        final picked = await pickImageFromGallery();
                        if (picked != null) {
                          setSheetState(() {
                            localImageFile = picked;
                          });
                        }
                      },
                      onRemove: () {
                        setSheetState(() {
                          localImageFile = null;
                          currentImageUrl = null;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AppColors.sauge,
                      value: isAvailable,
                      title: const Text("Disponible"),
                      onChanged: isSaving ? null : (value) {
                        setSheetState(() {
                          isAvailable = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final name = nameController.text.trim();
                        final price = double.tryParse(
                          priceController.text.trim(),
                        );
                        final catName = categoryController.text.trim();

                        if (name.isEmpty || price == null) {
                          showAppNotification(
                            dialogContext,
                            title: "Champs requis",
                            message: "Renseignez le nom et le prix.",
                            type: AppFeedbackType.warning,
                          );
                          return;
                        }

                        if (catName.isEmpty) {
                          showAppNotification(
                            dialogContext,
                            title: "Champs requis",
                            message: "Veuillez renseigner ou choisir une catégorie.",
                            type: AppFeedbackType.warning,
                          );
                          return;
                        }

                        if (plat != null) {
                          final confirmed = await showAppConfirmDialog(
                            dialogContext,
                            title: 'Enregistrer les modifications ?',
                            message: 'Les informations de ${plat.nom} seront mises a jour dans le menu.',
                            confirmLabel: 'Enregistrer',
                            icon: Icons.edit_outlined,
                            type: AppFeedbackType.info,
                          );
                          if (!confirmed) return;
                        }

                        setSheetState(() {
                          isSaving = true;
                        });

                        String? uploadedImageUrl = currentImageUrl;
                        try {
                          if (localImageFile != null) {
                            uploadedImageUrl = await ServiceLocator.restaurantService.uploadImage(
                              localImageFile!,
                              type: 'plat',
                            );
                          }

                          final dish = Plat(
                            id: plat?.id ?? 0,
                            nom: name,
                            description: descriptionController.text.trim(),
                            prix: price,
                            disponible: isAvailable,
                            categorie: catName,
                            imageUrl: uploadedImageUrl,
                          );

                          if (plat == null) {
                            await ServiceLocator.restaurantService
                                .addPlatToRestaurant(_restaurant.id, dish);
                          } else {
                            await ServiceLocator.restaurantService
                                .updatePlatInRestaurant(_restaurant.id, dish);
                          }

                          if (!mounted) return;
                          Navigator.of(dialogContext).pop();
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
                        } catch (e) {
                          showAppNotification(
                            dialogContext,
                            title: "Erreur",
                            message: "Impossible d'enregistrer le plat : $e",
                            type: AppFeedbackType.error,
                          );
                        } finally {
                          setSheetState(() {
                            isSaving = false;
                          });
                        }
                      },
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(plat == null ? "Ajouter" : "Enregistrer"),
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

  Future<void> _showRestaurantEditSheet(Restaurant restaurant) async {
    final nameController = TextEditingController(text: restaurant.nom);
    final addressController = TextEditingController(text: restaurant.adresse);
    final phoneController = TextEditingController(text: restaurant.telephone ?? '');
    final hoursController = TextEditingController(text: restaurant.horaires ?? '');

    XFile? localLogoFile;
    String? currentLogoUrl = restaurant.logoUrl;
    XFile? localPhotoFile;
    String? currentPhotoUrl = restaurant.photoUrl;

    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.creme,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Modifier le restaurant",
                          style: Theme.of(dialogContext).textTheme.displaySmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Nom du restaurant"),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      maxLines: 4,
                      minLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Itinéraire",
                        hintText: "Décrivez le chemin pour aller...",
                      ),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: "Téléphone",
                        hintText: "Ex: +229 21 30 40 50",
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hoursController,
                      decoration: const InputDecoration(
                        labelText: "Horaires d'ouverture",
                        hintText: "Ex: Lundi - Dimanche : 11h00 - 23h00",
                      ),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 16),
                    ImagePickerField(
                      label: "Logo du restaurant",
                      imageUrl: currentLogoUrl,
                      localFile: localLogoFile,
                      isUploading: isSaving,
                      onPick: () async {
                        final picked = await pickImageFromGallery();
                        if (picked != null) {
                          setSheetState(() {
                            localLogoFile = picked;
                          });
                        }
                      },
                      onRemove: () {
                        setSheetState(() {
                          localLogoFile = null;
                          currentLogoUrl = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ImagePickerField(
                      label: "Photo de couverture",
                      imageUrl: currentPhotoUrl,
                      localFile: localPhotoFile,
                      isUploading: isSaving,
                      onPick: () async {
                        final picked = await pickImageFromGallery();
                        if (picked != null) {
                          setSheetState(() {
                            localPhotoFile = picked;
                          });
                        }
                      },
                      onRemove: () {
                        setSheetState(() {
                          localPhotoFile = null;
                          currentPhotoUrl = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final name = nameController.text.trim();
                        final address = addressController.text.trim();

                        if (name.isEmpty || address.isEmpty) {
                          showAppNotification(
                            dialogContext,
                            title: "Champs requis",
                            message: "Veuillez remplir le nom et l'adresse.",
                            type: AppFeedbackType.warning,
                          );
                          return;
                        }

                        final nameChanged = name != restaurant.nom;
                        final confirmed = await showAppConfirmDialog(
                          dialogContext,
                          title: nameChanged ? "Modifier le nom ?" : "Confirmer les modifications ?",
                          message: nameChanged
                              ? "Attention : modifier le nom du restaurant réinitialisera sa validation et nécessitera une nouvelle approbation par l'administrateur. Il sera temporairement masqué pour les clients. Confirmer ?"
                              : "Les détails de votre restaurant seront mis à jour.",
                          confirmLabel: "Enregistrer",
                          icon: nameChanged ? Icons.warning_amber_rounded : Icons.edit_rounded,
                          type: nameChanged ? AppFeedbackType.warning : AppFeedbackType.info,
                        );
                        if (!confirmed) return;

                        setSheetState(() {
                          isSaving = true;
                        });

                        String? uploadedLogoUrl = currentLogoUrl;
                        String? uploadedPhotoUrl = currentPhotoUrl;

                        try {
                          if (localLogoFile != null) {
                            uploadedLogoUrl = await ServiceLocator.restaurantService.uploadImage(
                              localLogoFile!,
                              type: 'logo',
                            );
                          }
                          if (localPhotoFile != null) {
                            uploadedPhotoUrl = await ServiceLocator.restaurantService.uploadImage(
                              localPhotoFile!,
                              type: 'photo',
                            );
                          }

                          await ServiceLocator.restaurantService.updateRestaurant(
                            id: restaurant.id,
                            name: name,
                            address: address,
                            telephone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                            horaires: hoursController.text.trim().isEmpty ? null : hoursController.text.trim(),
                            logoUrl: uploadedLogoUrl,
                            photoUrl: uploadedPhotoUrl,
                          );

                          if (!mounted) return;
                          Navigator.of(dialogContext).pop();
                          await _loadData();
                          if (!mounted) return;
                          showAppNotification(
                            context,
                            title: "Mise à jour réussie",
                            message: "Les détails du restaurant ont été mis à jour.",
                            type: AppFeedbackType.success,
                          );
                        } catch (e) {
                          showAppNotification(
                            dialogContext,
                            title: "Erreur",
                            message: "Impossible de mettre à jour le restaurant : $e",
                            type: AppFeedbackType.error,
                          );
                        } finally {
                          setSheetState(() {
                            isSaving = false;
                          });
                        }
                      },
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Enregistrer"),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.grisBordure),
                    const SizedBox(height: 10),
                    Text(
                      "Actions d'établissement",
                      style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.marronFonce,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final willArchive = !restaurant.estArchive;
                                    final confirmed = await showAppConfirmDialog(
                                      dialogContext,
                                      title: willArchive ? "Archiver le restaurant ?" : "Désarchiver le restaurant ?",
                                      message: willArchive
                                          ? "Votre restaurant sera archivé et masqué de la boutique pour les clients, mais restera visible sur votre espace de gestion."
                                          : "Votre restaurant sera désarchivé et redeviendra visible pour les clients dans la boutique.",
                                      confirmLabel: willArchive ? "Archiver" : "Désarchiver",
                                      icon: willArchive ? Icons.archive_outlined : Icons.unarchive_outlined,
                                      type: AppFeedbackType.warning,
                                    );
                                    if (!confirmed) return;

                                    setSheetState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      await ServiceLocator.restaurantService.updateRestaurant(
                                        id: restaurant.id,
                                        name: nameController.text.trim(),
                                        address: addressController.text.trim(),
                                        logoUrl: currentLogoUrl,
                                        photoUrl: currentPhotoUrl,
                                        estArchive: willArchive,
                                      );

                                      if (!mounted) return;
                                      Navigator.of(dialogContext).pop();
                                      await _loadData();
                                      
                                      if (!mounted) return;
                                      showAppNotification(
                                        context,
                                        title: willArchive ? "Restaurant archivé" : "Restaurant désarchivé",
                                        message: willArchive
                                            ? "Le restaurant a été archivé avec succès."
                                            : "Le restaurant a été désarchivé.",
                                        type: AppFeedbackType.success,
                                      );
                                    } catch (e) {
                                      showAppNotification(
                                        dialogContext,
                                        title: "Erreur",
                                        message: "Impossible de modifier le statut : $e",
                                        type: AppFeedbackType.error,
                                      );
                                    } finally {
                                      setSheetState(() {
                                        isSaving = false;
                                      });
                                    }
                                  },
                            icon: Icon(
                              restaurant.estArchive ? Icons.unarchive_outlined : Icons.archive_outlined,
                              size: 16,
                              color: AppColors.terracotta,
                            ),
                            label: Text(
                              restaurant.estArchive ? "Désarchiver" : "Archiver",
                              style: const TextStyle(color: AppColors.terracotta),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.terracotta),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final confirmed = await showAppConfirmDialog(
                                      dialogContext,
                                      title: "Supprimer définitivement ?",
                                      message: "Cette action est irréversible. Le restaurant, ses plats et tous ses avis associés seront définitivement supprimés.",
                                      confirmLabel: "Supprimer",
                                      icon: Icons.delete_forever_outlined,
                                      type: AppFeedbackType.error,
                                    );
                                    if (!confirmed) return;

                                    setSheetState(() {
                                      isSaving = true;
                                    });

                                    try {
                                      await ServiceLocator.restaurantService.deleteRestaurant(restaurant.id);

                                      if (!mounted) return;
                                      Navigator.of(dialogContext).pop();
                                      Navigator.of(context).pop();

                                      showAppNotification(
                                        context,
                                        title: "Restaurant supprimé",
                                        message: "Le restaurant a été supprimé définitivement.",
                                        type: AppFeedbackType.success,
                                      );
                                    } catch (e) {
                                      showAppNotification(
                                        dialogContext,
                                        title: "Erreur",
                                        message: "Impossible de supprimer le restaurant : $e",
                                        type: AppFeedbackType.error,
                                      );
                                    } finally {
                                      setSheetState(() {
                                        isSaving = false;
                                      });
                                    }
                                  },
                            icon: const Icon(
                              Icons.delete_forever_outlined,
                              size: 16,
                              color: AppColors.rougeSignalement,
                            ),
                            label: const Text(
                              "Supprimer",
                              style: TextStyle(color: AppColors.rougeSignalement),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.rougeSignalement),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
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
      },
    );

    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    hoursController.dispose();
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

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.grisTexte),
        const SizedBox(width: 8),
        Text(
          "$title : ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.marronFonce),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13.5, color: AppColors.grisTexte),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionDetails(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DETAILS DE LA SOUMISSION',
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.grisTexte,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFBF7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.grisBordure),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(Icons.storefront_outlined, "Nom", _restaurant.nom),
              const SizedBox(height: 10),
              _buildDetailItem(Icons.restaurant_outlined, "Catégorie", _restaurant.categorie),
              const SizedBox(height: 10),
              _buildDetailItem(Icons.flatware_rounded, "Cuisine", _restaurant.typeCuisine),
              const SizedBox(height: 10),
              _buildDetailItem(Icons.aspect_ratio_rounded, "Superficie", "${_restaurant.superficie ?? 0} m²"),
              const SizedBox(height: 10),
              _buildDetailItem(Icons.location_on_outlined, "Itinéraire", "${_restaurant.adresse} (${_restaurant.quartier})"),
              const SizedBox(height: 10),
              _buildDetailItem(Icons.phone_outlined, "Téléphone", _restaurant.telephone ?? 'Non renseigné'),
              const SizedBox(height: 10),
              _buildDetailItem(Icons.access_time_rounded, "Horaires d'ouverture", _restaurant.horaires ?? 'Non renseigné'),
              const SizedBox(height: 10),
              _buildDetailItem(Icons.gps_fixed_outlined, "GPS Coordonnées", "${_restaurant.latitude.toStringAsFixed(6)}, ${_restaurant.longitude.toStringAsFixed(6)}"),
              
              const SizedBox(height: 16),
              const Divider(color: AppColors.grisBordure, height: 1),
              const SizedBox(height: 16),
              
              Text(
                "DOCUMENTS D'ENREGISTREMENT",
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.grisTexte,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_restaurant.cipUrl != null && _restaurant.cipUrl!.isNotEmpty)
                    _buildDocBadge("CIP Gérant", () => _viewDocument(_restaurant.cipUrl, "CIP Gérant")),
                  if (_restaurant.ifuNumero != null && _restaurant.ifuNumero!.isNotEmpty)
                    _buildDocBadge("IFU: ${_restaurant.ifuNumero}", () => _viewDocument(_restaurant.ifuAttestationUrl, "Attestation IFU")),
                  if (_restaurant.rccmNumero != null && _restaurant.rccmNumero!.isNotEmpty)
                    _buildDocBadge("RCCM: ${_restaurant.rccmNumero}", () => _viewDocument(_restaurant.rccmExtraitUrl, "Extrait RCCM")),
                ],
              ),
            ],
          ),
        ),
      ],
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.marronFonce),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, color: AppColors.marronFonce, size: 28),
                                tooltip: "Aperçu client",
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailsScreen(restaurant: _restaurant),
                                    ),
                                  );
                                },
                              ),
                              if (!_restaurant.estValide) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 28, color: AppColors.rougeSignalement),
                                  onPressed: () async {
                                    final confirmed = await showAppConfirmDialog(
                                      context,
                                      title: "Supprimer cette soumission ?",
                                      message: "Cette action est irréversible. La demande d'inscription sera définitivement annulée.",
                                      confirmLabel: "Supprimer",
                                      icon: Icons.delete_forever_outlined,
                                      type: AppFeedbackType.error,
                                    );
                                    if (!confirmed) return;

                                    setState(() {
                                      _isLoading = true;
                                    });

                                    try {
                                      await ServiceLocator.restaurantService.deleteRestaurant(_restaurant.id);
                                      if (!mounted) return;
                                      Navigator.of(context).pop();
                                      showAppNotification(
                                        context,
                                        title: "Demande supprimée",
                                        message: "La demande d'inscription a été supprimée.",
                                        type: AppFeedbackType.success,
                                      );
                                    } catch (e) {
                                      if (mounted) {
                                        showAppNotification(
                                          context,
                                          title: "Erreur",
                                          message: "Impossible de supprimer : $e",
                                          type: AppFeedbackType.error,
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  },
                                  tooltip: "Supprimer la soumission",
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.terracotta.withValues(alpha: 0.15),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.marronFonce.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: RestaurantLogo(
                              logoUrl: _restaurant.logoUrl,
                              restaurantName: _restaurant.nom,
                              size: 80,
                              isCircular: true,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _restaurant.nom,
                                  style: textTheme.displayLarge?.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _restaurant.adresse,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.grisTexte,
                                    fontSize: 13.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_restaurant.estArchive) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.terracotta.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_off_outlined, color: AppColors.terracotta, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Ce restaurant est masqué (archivé). Il n'apparaît plus dans la boutique.",
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.terracotta,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Note de soutenance : Le design de l'en-tête s'inspire des codes esthétiques des réseaux sociaux (TikTok/Instagram)
                      // en plaçant un bouton d'action principal large sous le bloc profil. Cela offre une meilleure accessibilité tactile
                      // et clarifie l'affordance de modification de l'établissement.
                      //
                      // Note de soutenance : Pour des raisons de securite et de coherence des donnees, les soumissions
                      // ne sont pas modifiables pendant l'examen par l'administrateur afin d'eviter des modifications
                      // concurrentes pendant la validation des documents legaux.
                      if (_restaurant.estValide)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showRestaurantEditSheet(_restaurant),
                            icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.terracotta),
                            label: const Text(
                              "Modifier les informations",
                              style: TextStyle(
                                color: AppColors.terracotta,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.terracotta, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: AppColors.terracotta.withValues(alpha: 0.05),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        )
                      else ...[
                        if (_restaurant.motifRejet != null)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => RegisterRestaurantScreen(
                                      restaurantToEdit: _restaurant,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _loadData();
                                }
                              },
                              icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.terracotta),
                              label: const Text(
                                "Corriger et resoumettre",
                                style: TextStyle(
                                  color: AppColors.terracotta,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.terracotta, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: AppColors.terracotta.withValues(alpha: 0.05),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
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
                      if (_restaurant.estValide) ...[
                        const SizedBox(height: 20),
                        _buildQrAction(context),
                        const SizedBox(height: 16),
                        _buildAvisAction(context),
                        const SizedBox(height: 28),
                        _buildMenuSection(context),
                        const SizedBox(height: 24),
                      ] else ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.orangeClair.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.terracotta.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _restaurant.motifRejet != null ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                                    color: AppColors.terracotta,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _restaurant.motifRejet != null ? "Demande refusee" : "En attente de validation",
                                    style: textTheme.titleLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.marronFonce,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _restaurant.motifRejet != null
                                    ? "Motif du rejet : ${_restaurant.motifRejet}\n\nVous pouvez modifier les informations d'enregistrement ou supprimer cette demande d'inscription."
                                    : "Votre etablissement a ete soumis pour validation administrative. Les modifications sont bloquees durant l'examen du dossier par l'administrateur.",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.marronFonce.withValues(alpha: 0.8),
                                  fontSize: 13.5,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSubmissionDetails(context),
                        const SizedBox(height: 24),
                      ],
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
      onTap: _downloadQrCode,
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

  Widget _buildAvisAction(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _RestaurantAvisScreen(
              restaurant: _restaurant,
              initialReviews: _reviews,
              onRefresh: _loadData,
            ),
          ),
        );
      },
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
              child: const Icon(Icons.rate_review_outlined, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avis des clients',
                    style: textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Consulter et signaler des avis (${_reviews.length})',
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
          if (plat.imageUrl != null && plat.imageUrl!.trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 60,
                height: 60,
                child: ImageUrlHelper.buildImage(
                  plat.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: AppColors.cremeFonce,
                    child: const Icon(Icons.fastfood_outlined, size: 24, color: AppColors.marronFonce),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
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

class _RestaurantAvisScreen extends StatefulWidget {
  final Restaurant restaurant;
  final List<Avis> initialReviews;
  final Future<void> Function() onRefresh;

  const _RestaurantAvisScreen({
    required this.restaurant,
    required this.initialReviews,
    required this.onRefresh,
  });

  @override
  State<_RestaurantAvisScreen> createState() => _RestaurantAvisScreenState();
}

class _RestaurantAvisScreenState extends State<_RestaurantAvisScreen> {
  late List<Avis> _reviews;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reviews = widget.initialReviews;
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    await widget.onRefresh();
    final freshReviews = await ServiceLocator.reviewService.getReviewsForRestaurant(
      widget.restaurant.id,
    );
    if (mounted) {
      setState(() {
        _reviews = freshReviews;
        _isLoading = false;
      });
    }
  }

  Future<void> _reportReview(BuildContext context, Avis review) async {
    final controller = TextEditingController();
    final user = ServiceLocator.authService.currentUser;
    final reporterName = user != null ? '${user.prenom} ${user.nom}'.trim() : 'Gérant';

    final result = await showDialog<bool>(
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
                        Icons.warning_amber_rounded,
                        color: AppColors.rougeSignalement,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Signaler cet avis",
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
                  "Veuillez indiquer le motif du signalement de cet avis rédigé par ${review.nomAuteur}.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: "Raison du signalement",
                    hintText: "Contenu inapproprié, diffamation, faux avis...",
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Annuler"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final reason = controller.text.trim();
                          if (reason.isEmpty) {
                            showAppNotification(
                              context,
                              title: 'Motif requis',
                              message: "Veuillez entrer une raison.",
                              type: AppFeedbackType.warning,
                            );
                            return;
                          }
                          try {
                            await ServiceLocator.reviewService.reportReview(
                              avisId: review.id,
                              reason: reason,
                              reporterName: reporterName,
                            );
                            Navigator.of(context).pop(true);
                          } catch (e) {
                            showAppNotification(
                              context,
                              title: 'Erreur',
                              message: "Impossible de signaler : $e",
                              type: AppFeedbackType.error,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rougeSignalement,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Signaler"),
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

    if (result == true) {
      if (mounted) {
        showAppNotification(
          context,
          title: 'Avis signalé',
          message: "L'avis a été signalé à l'administrateur avec succès.",
          type: AppFeedbackType.success,
        );
      }
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        title: const Text("Avis clients"),
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
            : _reviews.isEmpty
                ? const Center(child: Text("Aucun avis déposé pour cet établissement."))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      return _buildDetailedReviewCard(context, review);
                    },
                  ),
      ),
    );
  }

  Widget _buildDetailedReviewCard(BuildContext context, Avis review) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review.nomAuteur,
                  style: textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    review.note.toString(),
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Publié le ${review.dateVisite.day}/${review.dateVisite.month}/${review.dateVisite.year}',
            style: textTheme.bodySmall?.copyWith(color: AppColors.grisTexte, fontSize: 11),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.grisBordure, height: 1),
          const SizedBox(height: 12),
          Text(
            review.commentaire,
            style: const TextStyle(fontSize: 14.5, color: AppColors.marronFonce, height: 1.45),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _reportReview(context, review),
                icon: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.rougeSignalement),
                label: const Text(
                  "Signaler l'avis",
                  style: TextStyle(color: AppColors.rougeSignalement, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: AppColors.rougeSignalement.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
