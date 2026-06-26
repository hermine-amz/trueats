import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/services/service_locator.dart';
import '../../core/widgets/app_feedback.dart';

class AccountSanctionScreen extends StatelessWidget {
  final String message;
  final String? motif;
  final DateTime? bloqueJusqua;
  final bool isPermanent;
  final String? email;
  final int? userId;

  const AccountSanctionScreen({
    super.key,
    required this.message,
    this.motif,
    this.bloqueJusqua,
    required this.isPermanent,
    this.email,
    this.userId,
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }

  Future<void> _contactSupport() async {
    final String subject = isPermanent 
        ? "Réclamation - Compte TruEats banni définitivement" 
        : "Réclamation - Compte TruEats suspendu temporairement";

    final StringBuffer body = StringBuffer();
    body.writeln("Bonjour le support TruEats,");
    body.writeln("");
    body.writeln("Je souhaite faire un recours concernant la sanction appliquée sur mon compte.");
    body.writeln("");
    body.writeln("--- Informations de recours (ne pas modifier) ---");
    if (email != null && email!.isNotEmpty) {
      body.writeln("E-mail du compte : $email");
    }
    body.writeln("Statut : ${isPermanent ? 'Banni' : 'Suspendu'}");
    if (motif != null && motif!.trim().isNotEmpty) {
      body.writeln("Motif indiqué : $motif");
    }
    if (!isPermanent && bloqueJusqua != null) {
      body.writeln("Fin de suspension : ${_formatDate(bloqueJusqua!)}");
    }
    body.writeln("-------------------------------------------------");
    body.writeln("");
    body.writeln("[Veuillez expliquer votre situation ici :]");
    body.writeln("");
        
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'amouzounhermine7@gmail.com',
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body.toString())}',
    );
    
    try {
      await launchUrl(emailLaunchUri);
    } catch (_) {
      // Ignorer si l'app de messagerie n'est pas dispo
    }
  }

  void _showInAppAppealDialog(BuildContext context) {
    final messageController = TextEditingController(
      text: "Je sollicite la réévaluation de mon dossier et la levée des sanctions appliquées sur mon compte.",
    );
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.creme,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.orangeClair,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.gavel_rounded,
                                color: AppColors.terracotta,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Recours In-App",
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(fontSize: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "Soumettez votre contestation directement à l'administration. Veuillez confirmer votre mot de passe pour valider l'action.",
                          style: Theme.of(dialogContext).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: email,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Votre e-mail",
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Confirmer votre mot de passe",
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "Mot de passe requis.";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            labelText: "Message de recours",
                          ),
                          maxLines: 3,
                          validator: (v) {
                            if (v == null || v.trim().length < 10) {
                              return "Veuillez fournir un message explicatif (min 10 caract.).";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                                child: const Text("Annuler"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate()) return;
                                        setDialogState(() {
                                          isSubmitting = true;
                                        });
                                        try {
                                          await ServiceLocator.authService.submitAppeal(
                                            message: messageController.text.trim(),
                                            email: email,
                                            password: passwordController.text,
                                          );
                                          if (dialogContext.mounted) {
                                            Navigator.of(dialogContext).pop();
                                            showAppNotification(
                                              context,
                                              title: "Recours envoyé",
                                              message: "Votre recours a bien été transmis à l'administrateur.",
                                              type: AppFeedbackType.success,
                                            );
                                          }
                                        } catch (e) {
                                          if (dialogContext.mounted) {
                                            showAppNotification(
                                              dialogContext,
                                              title: "Échec du recours",
                                              message: e.toString().contains('401') || e.toString().contains('Identifiants')
                                                  ? "Mot de passe incorrect."
                                                  : e.toString(),
                                              type: AppFeedbackType.error,
                                            );
                                          }
                                        } finally {
                                          setDialogState(() {
                                            isSubmitting = false;
                                          });
                                        }
                                      },
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text("Envoyer"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.grisBordure),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.marronFonce.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon inside circular container
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.rougeSignalement.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPermanent ? Icons.gavel_rounded : Icons.timer_outlined,
                        color: AppColors.rougeSignalement,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      isPermanent ? "Compte Banni" : "Compte Suspendu",
                      style: textTheme.displayLarge?.copyWith(
                        fontSize: 24,
                        color: AppColors.marronFonce,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Message description
                    Text(
                      message,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.grisTexte,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Motif section
                    if (motif != null && motif!.trim().isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "MOTIF DU BLOCAGE",
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.grisTexte,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.rougeSignalement.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.rougeSignalement.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          motif!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.marronFonce,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Duration details
                    if (!isPermanent && bloqueJusqua != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "DATE DE RÉACTIVATION",
                          style: textTheme.labelLarge?.copyWith(
                            color: AppColors.grisTexte,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cremeFonce,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.grisBordure),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_available_rounded,
                              color: AppColors.sauge,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _formatDate(bloqueJusqua!),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.marronFonce,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Support contact explanation
                    Text(
                      "Si vous pensez qu'il s'agit d'une erreur ou si vous souhaitez faire une réclamation, vous pouvez contacter l'administration de TruEats.",
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.grisTexte,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Support Button
                    ElevatedButton.icon(
                      onPressed: _contactSupport,
                      icon: const Icon(Icons.mail_outline_rounded, color: Colors.white, size: 20),
                      label: const Text("Contacter le support"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // In-app appeal button
                    ElevatedButton.icon(
                      onPressed: () => _showInAppAppealDialog(context),
                      icon: const Icon(Icons.gavel_rounded, color: AppColors.terracotta, size: 20),
                      label: const Text("Faire un recours in-app"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cremeFonce,
                        foregroundColor: AppColors.terracotta,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(color: AppColors.terracotta),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Back to login button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.marronFonce,
                        side: const BorderSide(color: AppColors.grisBordure),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text("Retour à la connexion"),
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
