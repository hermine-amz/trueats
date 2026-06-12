import 'package:flutter/material.dart';
import '../services/interfaces.dart';
import '../theme.dart';

class ReportReviewDialog extends StatefulWidget {
  final Avis avis;
  final ReviewService reviewService;
  final VoidCallback? onReportSubmitted;

  const ReportReviewDialog({
    super.key,
    required this.avis,
    required this.reviewService,
    this.onReportSubmitted,
  });

  @override
  State<ReportReviewDialog> createState() => _ReportReviewDialogState();
}

class _ReportReviewDialogState extends State<ReportReviewDialog> {
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final reasonText = _reasonController.text.trim();

    try {
      await widget.reviewService.reportReview(
        avisId: widget.avis.id,
        reason: reasonText,
        reporterName: "Utilisateur connecté",
      );

      if (mounted) {
        Navigator.of(context).pop(); // Ferme le dialogue
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signalement envoyé avec succès aux modérateurs."),
            backgroundColor: AppColors.sauge,
          ),
        );
        if (widget.onReportSubmitted != null) {
          widget.onReportSubmitted!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'envoi du signalement : $e"),
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
    return Dialog(
      backgroundColor: AppColors.creme,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.report_problem_outlined, color: AppColors.terracotta),
                    const SizedBox(width: 8),
                    Text(
                      "Signaler un avis",
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Auteur de l'avis : ${widget.avis.nomAuteur}\nÉtablissement : ${widget.avis.restaurantNom}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.marronFonce,
                  ),
                ),
                const Divider(height: 24, color: AppColors.grisBordure),
                
                // Raison du signalement (Champ texte libre)
                Text(
                  "Motif du signalement",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Décrivez précisément le motif de votre signalement...",
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez saisir le motif du signalement";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Boutons d'actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        "Annuler",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.grisTexte,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Signaler"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
