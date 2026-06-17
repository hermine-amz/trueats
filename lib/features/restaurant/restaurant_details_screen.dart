import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../../core/utils/image_url_helper.dart';
import '../../core/widgets/restaurant_logo.dart';
import '../../core/widgets/review_card.dart';
import '../../core/widgets/app_feedback.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final Restaurant restaurant;
  final int initialTabIndex;

  const RestaurantDetailsScreen({
    super.key,
    required this.restaurant,
    this.initialTabIndex = 0,
  });

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  late int _activeTabIndex;
  List<Avis> _reviews = [];
  bool _isLoadingReviews = true;
  Restaurant? _freshRestaurant;
  bool _isBookmarked = false;

  Restaurant get _restaurant => _freshRestaurant ?? widget.restaurant;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
    _loadReviews();
    _loadFreshRestaurant();
    _checkIfBookmarked();
  }

  Future<void> _checkIfBookmarked() async {
    try {
      final lists = await ServiceLocator.restaurantService.getExplorationLists();
      final isBookmarked = lists.any((list) => list.adresses.any((r) => r.id == widget.restaurant.id));
      debugPrint("Check bookmark for res ${widget.restaurant.id}: isBookmarked=$isBookmarked");
      if (mounted) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    } catch (e, stack) {
      debugPrint("Error in _checkIfBookmarked: $e\n$stack");
    }
  }

  Future<void> _loadFreshRestaurant() async {
    try {
      final fresh = await ServiceLocator.restaurantService.getRestaurantById(widget.restaurant.id);
      if (fresh != null && mounted) {
        setState(() {
          _freshRestaurant = fresh;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadReviews() async {
    final list = await ServiceLocator.reviewService.getReviewsForRestaurant(
      _restaurant.id,
    );
    if (mounted) {
      setState(() {
        _reviews = list;
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _addRestaurantToExploreList() async {
    final lists = await ServiceLocator.restaurantService.getExplorationLists();
    
    // Note: On recherche en priorité la liste 'À explorer', sinon on prend la première disponible
    var exploreList = lists.where((list) => 
      list.nom.toLowerCase().trim() == 'à explorer' || 
      list.nom.toLowerCase().trim() == 'a explorer'
    ).toList();

    if (exploreList.isEmpty && lists.isNotEmpty) {
      exploreList = [lists.first];
    }

    if (exploreList.isEmpty) {
      await ServiceLocator.restaurantService.createExplorationList(
        'À explorer',
        false,
        ['⭐'],
      );
      final refreshedLists = await ServiceLocator.restaurantService.getExplorationLists();
      exploreList = refreshedLists.where((list) => 
        list.nom.toLowerCase().trim() == 'à explorer' || 
        list.nom.toLowerCase().trim() == 'a explorer'
      ).toList();
      if (exploreList.isEmpty && refreshedLists.isNotEmpty) {
        exploreList = [refreshedLists.first];
      }
    }

    if (exploreList.isEmpty) {
      return;
    }

    await ServiceLocator.restaurantService.addRestaurantToExploration(
      exploreList.first.id,
      _restaurant.id,
    );
  }

  Future<void> _toggleBookmark() async {
    try {
      final confirmed = await showAppConfirmDialog(
        context,
        title: 'Retirer de la liste ?',
        message: 'Voulez-vous retirer ${_restaurant.nom} de votre liste ?',
        confirmLabel: 'Retirer',
        icon: Icons.bookmark_remove_outlined,
        type: AppFeedbackType.warning,
      );
      if (!confirmed) return;

      final lists = await ServiceLocator.restaurantService.getExplorationLists();
      // On cherche toutes les listes contenant ce restaurant pour l'en retirer
      final containingLists = lists.where((list) => list.adresses.any((r) => r.id == _restaurant.id)).toList();

      if (containingLists.isNotEmpty) {
        for (final list in containingLists) {
          await ServiceLocator.restaurantService.addRestaurantToExploration(
            list.id,
            _restaurant.id,
          );
        }
      } else {
        // Fallback : au cas où, on essaie de basculer la liste par défaut
        final exploreList = lists.where((list) => 
          list.nom.toLowerCase().trim() == 'à explorer' || 
          list.nom.toLowerCase().trim() == 'a explorer'
        ).toList();
        if (exploreList.isNotEmpty) {
          await ServiceLocator.restaurantService.addRestaurantToExploration(
            exploreList.first.id,
            _restaurant.id,
          );
        }
      }

      setState(() {
        _isBookmarked = false;
      });
      if (!mounted) return;
      showAppNotification(
        context,
        title: 'Retiré de la liste',
        message: '${_restaurant.nom} a été retiré de votre liste.',
        type: AppFeedbackType.success,
      );
    } catch (e) {
      if (mounted) {
        showAppNotification(
          context,
          title: 'Erreur',
          message: 'Impossible de modifier la liste : $e',
          type: AppFeedbackType.error,
        );
      }
    }
  }

  Future<void> _showAddToExploreDialog() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return Dialog(
          backgroundColor: AppColors.creme,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter à ma liste à explorer',
                  style: textTheme.displaySmall?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RestaurantLogo(
                      logoUrl: _restaurant.logoUrl,
                      restaurantName: _restaurant.nom,
                      size: 64,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _restaurant.nom,
                            style: textTheme.titleLarge?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_restaurant.categorie} · ${_restaurant.typeCuisine}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.grisTexte,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _restaurant.adresse,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.marronFonce,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(dialogContext);
                      await _addRestaurantToExploreList();
                      if (!mounted) return;
                      navigator.pop();
                      setState(() {
                        _isBookmarked = true;
                      });
                      showAppNotification(
                        context,
                        title: 'Ajouté à la liste',
                        message: '${_restaurant.nom} a été ajouté à "À explorer".',
                        type: AppFeedbackType.success,
                      );
                    },
                    child: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final textTheme = Theme.of(context).textTheme;
    final hasPhoto = _restaurant.photoUrl != null && _restaurant.photoUrl!.trim().isNotEmpty;

    return Stack(
      children: [
        // Background photo or default colored background
        Container(
          width: double.infinity,
          height: 280,
          color: AppColors.cremeFonce,
          child: hasPhoto
              ? ImageUrlHelper.buildImage(
                  _restaurant.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: const Center(child: CircularProgressIndicator()),
                )
              : const Center(
                  child: Icon(
                    Icons.restaurant_outlined,
                    size: 80,
                    color: AppColors.terracotta,
                  ),
                ),
        ),
        // Dark top overlay for back/bookmark button visibility
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Back and Bookmark Buttons
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _isBookmarked ? _toggleBookmark : _showAddToExploreDialog,
                ),
              ),
            ],
          ),
        ),
        // Bottom details overlay: transparent/slightly creme transparent to match page background
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.creme.withValues(alpha: 0.0),
                  AppColors.creme.withValues(alpha: 0.7),
                  AppColors.creme,
                ],
                stops: const [0.0, 0.65, 1.0], // Ajusté pour garder la photo de couverture bien visible
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RestaurantLogo(
                  logoUrl: _restaurant.logoUrl,
                  restaurantName: _restaurant.nom,
                  size: 64,
                  isCircular: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_restaurant.categorie.toUpperCase()} · ${_restaurant.typeCuisine.toUpperCase()}',
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.terracotta,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _restaurant.nom,
                        style: textTheme.displayLarge?.copyWith(
                          color: AppColors.marronFonce,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creme,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      _buildTabButton(0, 'Menu'),
                      const SizedBox(width: 24),
                      _buildTabButton(1, 'Avis'),
                      const SizedBox(width: 24),
                      _buildTabButton(2, 'Infos'),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Divider(height: 1, color: AppColors.grisBordure),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                    child: _buildTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isActive ? AppColors.marronFonce : AppColors.grisTexte,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 3,
            color: isActive ? AppColors.terracotta : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final textTheme = Theme.of(context).textTheme;

    if (_activeTabIndex == 0) {
      final availableMenu =
          _restaurant.menu.where((plat) => plat.disponible).toList();
      final groupedMenu = <String, List<Plat>>{};
      for (final plat in availableMenu) {
        groupedMenu.putIfAbsent(plat.categorie, () => <Plat>[]).add(plat);
      }

      if (groupedMenu.isEmpty) {
        return Center(
          child: Text(
            'Aucun plat disponible pour le moment.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.grisTexte),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedMenu.entries.expand((entry) {
          final category = entry.key;
          final plats = entry.value;

          return <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cremeFonce,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                category.toUpperCase(),
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.grisTexte,
                  letterSpacing: 1.3,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...plats.asMap().entries.expand((dishEntry) {
              final index = dishEntry.key;
              final plat = dishEntry.value;
              final isLastInCategory = index == plats.length - 1;

              return <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plat.imageUrl != null && plat.imageUrl!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ImageUrlHelper.buildImage(
                            plat.imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              width: 72,
                              height: 72,
                              color: AppColors.cremeFonce,
                              child: const Icon(Icons.restaurant_outlined),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plat.nom,
                            style: textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            plat.description,
                            style: textTheme.bodyMedium?.copyWith(
                              height: 1.4,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${plat.prix.toInt()} FCFA',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.terracotta,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!isLastInCategory) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.grisBordure),
                  const SizedBox(height: 14),
                ],
              ];
            }),
            const SizedBox(height: 24),
          ];
        }).toList(),
      );
    }

    if (_activeTabIndex == 1) {
      if (_isLoadingReviews) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_reviews.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Text(
              'Aucun avis déposé pour le moment.',
              style: textTheme.bodyLarge?.copyWith(color: AppColors.grisTexte),
            ),
          ),
        );
      }

      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return ReviewCard(
            avis: review,
            reviewService: ServiceLocator.reviewService,
            onReviewActionCompleted: _loadReviews,
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_restaurant.quartier.isNotEmpty) ...[
          _buildInfoRow(
            Icons.location_city_outlined,
            "Localisation",
            _restaurant.quartier,
          ),
          const SizedBox(height: 16),
        ],
        _buildInfoRow(
          Icons.location_on_outlined,
          "Itinéraire",
          _restaurant.adresse,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          Icons.access_time,
          'Horaires d\'ouverture',
          _restaurant.horaires ?? 'Non renseigné',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.phone_outlined, 'Téléphone', _restaurant.telephone ?? 'Non renseigné'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String val) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.terracotta, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.grisTexte,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(val, style: textTheme.bodyLarge?.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
