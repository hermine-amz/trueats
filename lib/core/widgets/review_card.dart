import 'package:flutter/material.dart';
import '../services/interfaces.dart';
import '../theme.dart';
import 'report_review_dialog.dart';

class ReviewCard extends StatelessWidget {
  final Avis avis;
  final ReviewService reviewService;
  final VoidCallback? onReviewActionCompleted;

  const ReviewCard({
    super.key,
    required this.avis,
    required this.reviewService,
    this.onReviewActionCompleted,
  });

  void _showFullContentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.creme,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Entête
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.terracotta.withAlpha(40),
                      foregroundColor: AppColors.terracotta,
                      child: Text(
                        avis.nomAuteur.isNotEmpty ? avis.nomAuteur[0].toUpperCase() : "U",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            avis.nomAuteur,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                          ),
                          Text(
                            "Visite le ${_formatDate(avis.dateVisite)}",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Note
                Row(
                  children: [
                    _buildStars(avis.note, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Commentaire Complet
                Text(
                  "Avis sur ${avis.restaurantNom}",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.grisTexte),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cremeFonce,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      avis.commentaire,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: AppColors.marronFonce,
                          ),
                    ),
                  ),
                ),
                
                // Photo si disponible
                if (avis.photoUrl != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE2D4C9), Color(0xFFC9DEC9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "📷 [Photo de l'avis]",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.marronFonce),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Bouton Fermer
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.terracotta,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Fermer"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ReportReviewDialog(
          avis: avis,
          reviewService: reviewService,
          onReportSubmitted: onReviewActionCompleted,
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Widget _buildStars(int note, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < note ? Icons.star : Icons.star_border,
          color: AppColors.terracotta,
          size: size,
        );
      }),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        border: Border.all(color: AppColors.grisBordure, width: 1),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne du haut : Auteur, Note, et Bouton Menu Options
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.terracotta.withAlpha(20),
                foregroundColor: AppColors.terracotta,
                child: Text(
                  avis.nomAuteur.isNotEmpty ? avis.nomAuteur[0].toUpperCase() : "U",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avis.nomAuteur,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.marronFonce,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildStars(avis.note),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Menu contextuel demandé par l'utilisateur
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.grisTexte, size: 20),
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                tooltip: "Options de l'avis",
                onSelected: (value) {
                  if (value == 'read') {
                    _showFullContentDialog(context);
                  } else if (value == 'report') {
                    _showReportDialog(context);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'read',
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book, color: AppColors.marronFonce, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Lire tout le contenu",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.marronFonce,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, color: AppColors.rougeSignalement, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Signaler l'avis",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.rougeSignalement,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Texte de l'avis (tronqué)
          Text(
            avis.commentaire,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 14,
              height: 1.4,
              color: AppColors.marronFonce,
            ),
          ),
        ],
      ),
    );
  }
}
