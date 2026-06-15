import 'package:flutter/material.dart';

import '../../core/services/interfaces.dart';
import '../../core/services/service_locator.dart';
import '../../core/theme.dart';

class WriteReviewScreen extends StatefulWidget {
  final Restaurant restaurant;

  const WriteReviewScreen({super.key, required this.restaurant});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  static const String _defaultCommentText =
      'Décrivez votre expérience culinaire, le service et le cadre';

  int _selectedRating = 4;
  late final TextEditingController _commentController;
  bool _isUsingDefaultComment = true;
  bool _isCheckingGps = true;
  bool _isNear = false;
  double _calculatedDistance = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: _defaultCommentText);
    _checkGpsProximity();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _clearDefaultCommentIfNeeded() {
    if (_isUsingDefaultComment) {
      _commentController.clear();
      _isUsingDefaultComment = false;
      setState(() {});
    }
  }

  Future<void> _checkGpsProximity() async {
    setState(() {
      _isCheckingGps = true;
    });

    try {
      final position = await ServiceLocator.locationService
          .getCurrentLocation();
      final latClient = position['latitude']!;
      final lonClient = position['longitude']!;

      final distance = ServiceLocator.locationService.calculateDistance(
        latClient,
        lonClient,
        widget.restaurant.latitude,
        widget.restaurant.longitude,
      );

      if (mounted) {
        setState(() {
          _calculatedDistance = distance;
          _isNear = distance <= widget.restaurant.rayonMetres;
          _isCheckingGps = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isNear = false;
          _isCheckingGps = false;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty || _isUsingDefaultComment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez rédiger un commentaire.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = ServiceLocator.authService.currentUser;
      final coords = await ServiceLocator.locationService.getCurrentLocation();

      await ServiceLocator.reviewService.submitReview(
        restaurantId: widget.restaurant.id,
        note: _selectedRating,
        comment: comment,
        lat: coords['latitude']!,
        lon: coords['longitude']!,
        isVerified: _isNear,
        photos: null,
        authorName: user?.name ?? 'Utilisateur',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre avis a été publié avec succès !'),
            backgroundColor: AppColors.sauge,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la publication : $e'),
            backgroundColor: AppColors.rougeSignalement,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final restaurantName = widget.restaurant.nom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noter mon expérience'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _isCheckingGps
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Vérification silencieuse de votre présence par GPS...',
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurantName,
                            style: textTheme.titleLarge?.copyWith(
                              color: AppColors.marronFonce,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(
                            height: 32,
                            color: AppColors.grisBordure,
                          ),
                          Text(
                            'Votre note',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.grisTexte,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (index) {
                              return IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedRating = index + 1;
                                  });
                                },
                                icon: Icon(
                                  index < _selectedRating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: AppColors.terracotta,
                                  size: 38,
                                ),
                                padding: const EdgeInsets.only(right: 8),
                                constraints: const BoxConstraints(),
                              );
                            }),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Commentaire',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.grisTexte,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _commentController,
                            maxLines: 6,
                            onTap: _clearDefaultCommentIfNeeded,
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                _isUsingDefaultComment = false;
                              }
                            },
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 14,
                              color: _isUsingDefaultComment
                                  ? AppColors.grisTexte
                                  : AppColors.marronFonce,
                            ),
                            decoration: InputDecoration(
                              hintText: _defaultCommentText,
                              fillColor: AppColors.cremeFonce.withValues(
                                alpha: 0.5,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (!_isNear)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.rougeClair,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.rougeSignalement.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.rougeSignalement,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Vous devez vous trouver physiquement dans le restaurant pour publier votre évaluation.\n'
                                      '(Distance mesurée : ${(_calculatedDistance / 1000).toStringAsFixed(2)} km, autorisée : ${widget.restaurant.rayonMetres.toInt()}m)',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: AppColors.rougeSignalement,
                                        height: 1.4,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ElevatedButton(
                            onPressed: (_isNear && !_isSubmitting)
                                ? _submitReview
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.terracotta,
                              disabledBackgroundColor: AppColors.grisBordure,
                              disabledForegroundColor: AppColors.grisTexte,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    'Publier mon avis',
                                    style: textTheme.titleLarge?.copyWith(
                                      color: _isNear
                                          ? Colors.white
                                          : AppColors.grisTexte,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
