import 'package:flutter/material.dart';
import '../../core/mock_data.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';
import '../restaurant/restaurant_details_screen.dart';


class MyReviewsScreen extends StatefulWidget {
  final int userId;

  const MyReviewsScreen({required this.userId, super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = true;
  List<Avis> _myReviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ServiceLocator.reviewService.getReviewsByUser(widget.userId);
      setState(() {
        _myReviews = reviews;
        // Trier les avis du plus récent au plus ancien
        _myReviews.sort((a, b) => b.dateVisite.compareTo(a.dateVisite));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error gracefully if needed
    }
  }

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
      Navigator.of(context).pop(); // Close the loading dialog

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
      if (!mounted) return;
      Navigator.of(context).pop(); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la récupération du restaurant: $e"),
          backgroundColor: AppColors.rougeSignalement,
        ),
      );
    }
  }

  Widget _buildStars(int note) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < note ? Icons.star_rounded : Icons.star_outline_rounded,
          color: AppColors.marronFonce,
          size: 16,
        );
      }),
    );
  }

  Widget _buildReviewCard(Avis avis) {
    final textTheme = Theme.of(context).textTheme;
    final dateStr = '${avis.dateVisite.day.toString().padLeft(2, '0')}/${avis.dateVisite.month.toString().padLeft(2, '0')}/${avis.dateVisite.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cremeFonce,
        borderRadius: BorderRadius.circular(16),
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
                  onTap: () => _navigateToRestaurant(avis.restaurantId),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          avis.restaurantNom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.terracotta,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.terracotta,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: AppColors.terracotta,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                dateStr,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.grisTexte,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStars(avis.note),
          const SizedBox(height: 12),
          Text(
            avis.commentaire.isNotEmpty ? avis.commentaire : "Aucun commentaire.",
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.creme,
      appBar: AppBar(
        backgroundColor: AppColors.creme,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mes Avis',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.marronFonce,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.marronFonce),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta),
            )
          : _myReviews.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.star_outline_rounded,
                          size: 64,
                          color: AppColors.grisBordure,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Vous n'avez pas encore laissé d'avis.",
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.grisTexte,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _myReviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(_myReviews[index]);
                  },
                ),
    );
  }
}
